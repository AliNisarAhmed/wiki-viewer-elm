module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)



---- MODEL ----


type alias Model =
    { formActive : Bool
    }


init : ( Model, Cmd Msg )
init =
    ( { formActive = False }, Cmd.none )



---- UPDATE ----


type Msg
    = ToggleActive


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleActive ->
            ( { model | formActive = not model.formActive }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ div [ class "nav" ]
            [ h1 [ class "title" ] [ text "Wikipedia Viewer" ]
            ]
        , div
            [ class "center" ]
            [ a [] [ text "click here to generate a random article" ]
            , Html.form [ class (toggleForm model.formActive) ]
                [ input [ class "input", onFocus ToggleActive, onBlur ToggleActive ] [] ]
            , p [] [ text "click the icon to search" ]
            ]
        ]


toggleForm : Bool -> String
toggleForm x =
    case x of
        True ->
            "active"

        _ ->
            ""



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
