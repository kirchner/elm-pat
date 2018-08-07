# elm-pat

Create sewing patterns in your browser. [Live
Demo](http://kirchner.github.io/elm-pat)

Note, that this is in a very early development state.  Nevertheless,
I appreciate any questions or feedback. :) The remaining part of this document
tries to explain some parts the architecture and how to extend it.

This project got a lot of inspiration and knowledge from
[Seamly2D](https://github.com/FashionFreedom/Seamly2D) and
[TauMeta](https://github.com/slspencer/TauMeta), so you should definitely check
these out, too!


## What is this all about?

When constructing sewing patterns, one usually takes some measurments of the
person the final clothes should be for (e.g. shoulder width, back width, leg
length) and then follows some construction steps, like 'draw a point', 'draw
a line from point A downwards of half the length of the back height', 'draw
a line perpendicular to some other line at 2/3 of that line', etc..

Eventually, you should be able to feed this program all these construction
steps, so that you only have to update the input measurements to adjust your
sewing patterns.


## How to add new Tools?

Suppose we want to implement a new tool which lets you add a new point on
a line between two other points with a certain ratio.  To do this, we need to
define a state type for it like so:

```elm
type alias State =
    { start : Maybe Id
    , end : Maybe Id
    , ratio : Maybe Float
    }
```

We need a function which may return a new point, given this state and the
global data, which includes for example the current cursor position on the
canvas (if we decide to track it), all previously created points, or our set of
variables:

```elm
point : Data -> State -> Maybe Point
point data state =
    ...


type alias Data =
    { store : PointStore
    , variables : Variables
    , viewPort : ViewPort
    , mousePosition : Maybe Position
    , focusedPoint : Maybe Id
    }
```

In this case, `start` and `end` have to be given (and we are able to compute
their positions) but `ratio` is not necessary if we have a the current cursor
position, in which case we can compute it using the positions of `start` and
`end`.

We also need to provide a rendering function for the canvas:

```elm
svg : Callbacks msg -> (State -> msg) -> Data -> State -> Svg msg
svg callbacks updateState data state =
    ...


type alias Callbacks msg =
    { addPoint : Point -> msg
    , updateCursorPosition : Maybe Position -> msg
    , focusPoint : Maybe Id -> msg
    }
```

In `svg` you can use the function

```elm
svgUpdateMouse : Maybe msg -> (Maybe Position -> msg) -> Data -> Svg msg
svgUpdateMouse mouseClicked updateCursorPosition data =
    ...
```

to indicate that you want the cursor position be updated and to add a callback
for mouse click events.  In our example, we will only draw `svgUpdateMouse`
when `start` and `end` are selected.  The mouseClicked callback will then use
the `point` function to create a new point.

To be able to select `start` or `end` by clicking on existing points in the
canvas, you can use the function

```elm
svgSelectPoint : (Maybe Id -> msg) -> (Maybe Id -> msg) -> Data -> Svg msg
svgSelectPoint focusPoint selectPoint data =
    ...
```

The last bit is a `view` function which displays a form in which one can input
the different values for the tool:

```elm
view : Callbacks msg -> (State -> msg) -> Data -> State -> Svg msg
view callbacks updateState data state =
    let
        updateRatio =
            (\newRatio -> { state | ratio = newRatio }) >> updateState

        ...
    in
    [ exprInput "ratio" state.ratio updateRatio
    , ...
    ]
        |> Tools.Common.view callbacks data state point
```

The module `Tools.Common` provides helper view functions for often used input
elements.

Now you have to extend the `Tool` type in `Editor` and add the tool to
`allTools`. The compiler errors should then guide you through the remaining
necessary changes.
