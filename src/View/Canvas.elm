module View.Canvas exposing (view)

import Dict exposing (..)
import Events
import Expr exposing (..)
import Html exposing (Html)
import Html.Attributes as Html
import List.Extra as List
import Math.Vector2 exposing (..)
import Piece exposing (..)
import Styles.Colors as Colors
import Svg exposing (Svg, path)
import Svg.Attributes as Svg
import Svg.Events as Svg
import Svg.Extra as Svg
import Tools.Common
    exposing
        ( Data
        , svgSelectPoint
        )
import Types exposing (..)


view :
    Svg msg
    -> (Position -> msg)
    -> (Maybe Id -> msg)
    -> (Maybe Id -> msg)
    -> (Int -> Int -> msg)
    -> Data
    -> Dict Int Piece
    -> Html msg
view tool startDrag focusPoint selectPoint extendPiece data pieceStore =
    let
        viewBoxString =
            String.join " "
                [ toString data.viewPort.x
                , toString data.viewPort.y
                , toString data.viewPort.width
                , toString data.viewPort.height
                ]
    in
    Svg.svg
        [ Svg.viewBox viewBoxString
        , Html.style
            [ ( "background-color", Colors.base3 )
            , ( "width", toString data.viewPort.width )
            , ( "height", toString data.viewPort.height )
            , ( "user-select", "none" ) -- TODO: add browser-prefixes
            , ( "-moz-user-select", "none" )
            ]
        ]
        [ grid defaultGridConfig data.viewPort
        , origin
        , Svg.g [] (points data)
        , viewSelectedPoints data
        , dragArea startDrag data.viewPort
        , Svg.g [] (pieces extendPiece data)
        , svgSelectPoint focusPoint selectPoint data
        , tool
        ]


defaultGridConfig =
    { offset = 50
    , unit = "mm"
    , color1 = "rgba(0,0,0,0.08)"
    , color2 = "rgba(0,0,0,0.24)"
    , highlight = 5
    }


grid config viewPort =
    let
        line color u v =
            Svg.line
                [ Svg.x1 (toString (getX u))
                , Svg.y1 (toString (getY u))
                , Svg.x2 (toString (getX v))
                , Svg.y2 (toString (getY v))
                , Svg.stroke color
                ]
                []

        x =
            toFloat (viewPort.width + 2 * config.offset) / 2

        y =
            toFloat (viewPort.height + 2 * config.offset) / 2

        -- n satisfies:
        --    2 * n * config.offset > ((max viewPort.height viewPort.width) / 2)
        n =
            max viewPort.height viewPort.width
                // config.offset
                |> (+) 4

        -- for good measure
        nh =
            n // 2

        dx =
            viewPort.x + (viewPort.width // 2)

        dy =
            viewPort.y + (viewPort.height // 2)

        -- so that the grid does not translate
        translationOffset =
            vec2 (toFloat dx) (toFloat dy)

        -- so that it appears like it does:
        -- (note that this affects computation of highlight colors k)
        correctionOffset =
            vec2 (toFloat (-dx % config.offset))
                (toFloat (-dy % config.offset))

        pr u =
            u
                |> add translationOffset
                |> add correctionOffset

        translation =
            pr (vec2 0 0)

        tx =
            getX translation

        ty =
            getY translation

        color k =
            if k % config.highlight == 0 then
                config.color2
            else
                config.color1
    in
    Svg.g
        [ Svg.transform ("translate(" ++ toString tx ++ "," ++ toString ty ++ ")")
        ]
        (List.concat
            [ List.map
                (\k_ ->
                    let
                        y =
                            (k_ - nh)
                                * config.offset
                                |> toFloat

                        u =
                            vec2 -x y

                        v =
                            vec2 x y

                        k =
                            floor (getY (pr u)) // config.offset
                    in
                    line (color k) u v
                )
                (List.range 0 n)
            , List.map
                (\k_ ->
                    let
                        x =
                            (k_ - nh)
                                * config.offset
                                |> toFloat

                        u =
                            vec2 x -y

                        v =
                            vec2 x y

                        k =
                            floor (getX (pr u)) // config.offset
                    in
                    line (color k) u v
                )
                (List.range 0 n)
            ]
        )


dragArea : (Position -> msg) -> ViewPort -> Svg msg
dragArea startDrag viewPort =
    Svg.rect
        [ Svg.x (toString viewPort.x)
        , Svg.y (toString viewPort.y)
        , Svg.width (toString viewPort.width)
        , Svg.height (toString viewPort.height)
        , Svg.fill "transparent"
        , Svg.strokeWidth "0"
        , Events.onMouseDown startDrag
        ]
        []


viewSelectedPoints : Data -> Svg msg
viewSelectedPoints data =
    let
        tail list =
            case List.tail list of
                Just rest ->
                    rest

                Nothing ->
                    []
    in
    (List.head data.selectedPoints
        |> Maybe.andThen (viewSelectedPoint data True)
    )
        :: (data.selectedPoints
                |> tail
                |> List.map (viewSelectedPoint data False)
           )
        |> List.filterMap identity
        |> Svg.g []


viewSelectedPoint : Data -> Bool -> Id -> Maybe (Svg msg)
viewSelectedPoint data first id =
    let
        pointPosition =
            Dict.get id data.store
                |> Maybe.andThen (position data.store data.variables)
    in
    case pointPosition of
        Just position ->
            Just <|
                Svg.g []
                    (if first then
                        [ Svg.drawPoint Colors.red position
                        , Svg.drawSelector Svg.Solid Colors.red position
                        ]
                     else
                        [ Svg.drawPoint Colors.yellow position
                        , Svg.drawSelector Svg.Solid Colors.yellow position
                        ]
                    )

        Nothing ->
            Nothing


origin : Svg msg
origin =
    Svg.g []
        [ Svg.line
            [ Svg.x1 "-10"
            , Svg.y1 "0"
            , Svg.x2 "10"
            , Svg.y2 "0"
            , Svg.stroke Colors.green
            , Svg.strokeWidth "1"
            ]
            []
        , Svg.line
            [ Svg.x1 "0"
            , Svg.y1 "-10"
            , Svg.x2 "0"
            , Svg.y2 "10"
            , Svg.stroke Colors.green
            , Svg.strokeWidth "1"
            ]
            []
        ]


points : Data -> List (Svg msg)
points data =
    Dict.values data.store
        |> List.filterMap (point data)


point : Data -> Point -> Maybe (Svg msg)
point data point =
    case point of
        Absolute _ _ ->
            position data.store data.variables point
                |> Maybe.map (Svg.drawPoint Colors.base0)

        Relative id _ _ ->
            let
                draw v w =
                    Svg.g []
                        [ Svg.drawPoint Colors.base0 w
                        , Svg.drawRectArrow v w
                        ]
            in
            Maybe.map2
                draw
                (positionById data.store data.variables id)
                (position data.store data.variables point)

        Distance id _ _ ->
            let
                draw v w =
                    Svg.g []
                        [ Svg.drawPoint Colors.base0 w
                        , Svg.drawArrow v w
                        ]
            in
            Maybe.map2
                draw
                (positionById data.store data.variables id)
                (position data.store data.variables point)

        Between idA idB _ ->
            Just (Svg.g [] [])


pieces : (Int -> Int -> msg) -> Data -> List (Svg msg)
pieces extendPiece data =
    Dict.toList data.pieceStore
        |> List.map (piece extendPiece data)
        |> List.map (Svg.g [])


piece : (Int -> Int -> msg) -> Data -> ( Int, Piece ) -> List (Svg msg)
piece extendPiece data ( id, piece ) =
    let
        segments =
            Piece.toList piece
                |> List.filterMap (positionById data.store data.variables)
                |> List.zip (Piece.toList piece)
    in
    case segments of
        first :: rest ->
            piecePath first rest
                :: pieceHelper (extendPiece id) first rest first []

        [] ->
            []


piecePath : ( Int, Vec2 ) -> List ( Int, Vec2 ) -> Svg msg
piecePath ( _, first ) rest =
    let
        restD =
            List.foldl l "" rest

        l ( _, v ) restD =
            "L "
                ++ toString (getX v)
                ++ " "
                ++ toString (getY v)
                ++ " "
                ++ restD
    in
    path
        [ Svg.d
            ("M "
                ++ toString (getX first)
                ++ " "
                ++ toString (getY first)
                ++ " "
                ++ restD
            )
        , Svg.fill Colors.blue
        , Svg.strokeWidth "0"
        , Svg.opacity "0.2"
        , Svg.pointerEvents "none"
        ]
        []


pieceHelper :
    (Int -> msg)
    -> ( Int, Vec2 )
    -> List ( Int, Vec2 )
    -> ( Int, Vec2 )
    -> List (Svg msg)
    -> List (Svg msg)
pieceHelper extendPiece ( firstId, first ) rest veryFirst drawn =
    case rest of
        ( secondId, second ) :: veryRest ->
            (Svg.drawLineSegmentWith (extendPiece firstId) first second :: drawn)
                |> pieceHelper extendPiece ( secondId, second ) veryRest veryFirst

        [] ->
            Svg.drawLineSegmentWith (extendPiece firstId) first (Tuple.second veryFirst) :: drawn
