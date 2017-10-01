module Views.Canvas exposing (view)

import Data.Piece as Piece exposing (..)
import Data.Point as Point exposing (Point)
import Data.Position as Position exposing (Position)
import Data.Store as Store exposing (Id, Store)
import Data.ViewPort as ViewPort exposing (ViewPort)
import Events
import Html exposing (Html)
import Html.Attributes as Html
import List.Extra as List
import Math.Vector2 exposing (..)
import Styles.Colors as Colors
import Svg exposing (Svg, path)
import Svg.Attributes as Svg
import Svgs.Extra as Extra
import Svgs.SelectPoint as SelectPoint
import Tools.Data exposing (Data)


view :
    { startDrag : Position -> msg
    , focusPoint : Maybe (Id Point) -> msg
    , selectPoint : Maybe (Id Point) -> msg
    , extendPiece : Id Piece -> Id Point -> msg
    , updateZoom : Float -> msg
    }
    -> Store Piece
    -> Svg msg
    -> Data
    -> Html msg
view { startDrag, focusPoint, selectPoint, extendPiece, updateZoom } pieceStore tool data =
    let
        viewBoxString =
            let
                wh =
                    ViewPort.virtualWidth data.viewPort // 2

                hh =
                    ViewPort.virtualHeight data.viewPort // 2

                dx =
                    data.viewPort.offset.x

                dy =
                    data.viewPort.offset.y
            in
            String.join " "
                [ toString (dx - wh)
                , toString (dy - hh)
                , toString (ViewPort.virtualWidth data.viewPort)
                , toString (ViewPort.virtualHeight data.viewPort)
                ]
    in
    Svg.svg
        [ Svg.viewBox viewBoxString
        , Html.style
            [ ( "background-color", Colors.base3 )
            , ( "user-select", "none" ) -- TODO: add browser-prefixes
            , ( "-moz-user-select", "none" )
            ]
        , Events.onWheel updateZoom
        ]
        [ grid defaultGridConfig data.viewPort
        , origin
        , Svg.g [] (points data)
        , viewSelectedPoints data
        , dragArea startDrag data.viewPort
        , Svg.g [] (pieces extendPiece data)
        , SelectPoint.svg focusPoint selectPoint data
        , tool
        ]


type alias GridConfig =
    { unit : String
    , color1 : String
    , color2 : String
    , highlight : Int
    , offset : Int
    }


defaultGridConfig : GridConfig
defaultGridConfig =
    { offset = 50
    , unit = "mm"
    , color1 = "rgba(0,0,0,0.08)"
    , color2 = "rgba(0,0,0,0.24)"
    , highlight = 5
    }


grid : GridConfig -> ViewPort -> Svg msg
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
            toFloat (ViewPort.virtualWidth viewPort + 2 * config.offset) / 2

        y =
            toFloat (ViewPort.virtualHeight viewPort + 2 * config.offset) / 2

        -- n satisfies:
        --    2 * n * config.offset > ((max viewPort.height viewPort.width) / 2)
        n =
            max (ViewPort.virtualHeight viewPort) (ViewPort.virtualWidth viewPort)
                // config.offset
                |> (+) 4

        -- for good measure
        nh =
            n // 2

        dx =
            viewPort.offset.x

        dy =
            viewPort.offset.y

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
        [ Svg.x (toString (viewPort.offset.x - (ViewPort.virtualWidth viewPort // 2)))
        , Svg.y (toString (viewPort.offset.y - (ViewPort.virtualHeight viewPort // 2)))
        , Svg.width (toString (ViewPort.virtualWidth viewPort))
        , Svg.height (toString (ViewPort.virtualHeight viewPort))
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


viewSelectedPoint : Data -> Bool -> Id Point -> Maybe (Svg msg)
viewSelectedPoint data first id =
    let
        position =
            Store.get id data.store
                |> Maybe.andThen (Point.position data.store data.variables)
    in
    case position of
        Just position ->
            Just <|
                Svg.g []
                    (if first then
                        [ Extra.drawPoint Colors.red position
                        , Extra.drawSelector Extra.Solid Colors.red position
                        ]
                     else
                        [ Extra.drawPoint Colors.yellow position
                        , Extra.drawSelector Extra.Solid Colors.yellow position
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
    Store.values data.store
        |> List.filterMap (point data)


point : Data -> Point -> Maybe (Svg msg)
point data point =
    let
        handlers =
            { withAbsolute =
                \point _ _ ->
                    Point.position data.store data.variables point
                        |> Maybe.map (Extra.drawPoint Colors.base0)
            , withRelative =
                \point anchorId _ _ ->
                    let
                        draw v w =
                            Svg.g []
                                [ Extra.drawPoint Colors.base0 w
                                , Extra.drawRectArrow v w
                                ]
                    in
                    Maybe.map2
                        draw
                        (Point.positionById data.store data.variables anchorId)
                        (Point.position data.store data.variables point)
            , withDistance =
                \point anchorId _ _ ->
                    let
                        draw v w =
                            Svg.g []
                                [ Extra.drawPoint Colors.base0 w
                                , Extra.drawArrow v w
                                ]
                    in
                    Maybe.map2
                        draw
                        (Point.positionById data.store data.variables anchorId)
                        (Point.position data.store data.variables point)
            , withBetween =
                \point firstId lastId _ ->
                    let
                        draw v p q =
                            Svg.g []
                                [ Extra.drawLine p q
                                , Extra.drawPoint Colors.base0 v
                                ]
                    in
                    Maybe.map3
                        draw
                        (Point.position data.store data.variables point)
                        (Point.positionById data.store data.variables firstId)
                        (Point.positionById data.store data.variables lastId)
            , withCircleIntersection =
                \point firstId _ lastId _ _ ->
                    let
                        draw v p q =
                            Svg.g []
                                [ Extra.drawArrow p v
                                , Extra.drawArrow v q
                                , Extra.drawPoint Colors.base0 v
                                ]
                    in
                    Maybe.map3
                        draw
                        (Point.position data.store data.variables point)
                        (Point.positionById data.store data.variables firstId)
                        (Point.positionById data.store data.variables lastId)
            }
    in
    Point.dispatch handlers point


pieces : (Id Piece -> Id Point -> msg) -> Data -> List (Svg msg)
pieces extendPiece data =
    Store.toList data.pieceStore
        |> List.map (piece extendPiece data)
        |> List.map (Svg.g [])


piece :
    (Id Piece -> Id Point -> msg)
    -> Data
    -> ( Id Piece, Piece )
    -> List (Svg msg)
piece extendPiece data ( id, piece ) =
    let
        segments =
            Piece.toList piece
                |> List.filterMap (Point.positionById data.store data.variables)
                |> List.zip (Piece.toList piece)
    in
    case segments of
        first :: rest ->
            piecePath first rest
                :: pieceHelper (extendPiece id) first rest first []

        [] ->
            []


piecePath : ( Id Point, Vec2 ) -> List ( Id Point, Vec2 ) -> Svg msg
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
    (Id Point -> msg)
    -> ( Id Point, Vec2 )
    -> List ( Id Point, Vec2 )
    -> ( Id Point, Vec2 )
    -> List (Svg msg)
    -> List (Svg msg)
pieceHelper extendPiece ( firstId, first ) rest veryFirst drawn =
    case rest of
        ( secondId, second ) :: veryRest ->
            (Extra.drawLineSegmentWith (extendPiece firstId) first second :: drawn)
                |> pieceHelper extendPiece ( secondId, second ) veryRest veryFirst

        [] ->
            Extra.drawLineSegmentWith (extendPiece firstId) first (Tuple.second veryFirst) :: drawn
