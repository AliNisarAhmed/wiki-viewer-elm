module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as D exposing (..)



---- MODEL ----


type alias Model =
    { formActive : Bool
    , searchField : String
    , searchResults : List ResponseObject
    }


wikiUrl : String
wikiUrl =
    "https://cors-anywhere.herokuapp.com/https://en.wikipedia.org/w/api.php?action=query&format=json&list=search&utf8=1&srsearch=$react"


init : ( Model, Cmd Msg )
init =
    ( { formActive = False, searchField = "", searchResults = [] }, Cmd.none )



---- UPDATE ----


type Msg
    = ToggleActive
    | SearchInput String
    | FormSubmit
    | Response (Result Http.Error (List ResponseObject))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleActive ->
            ( { model | formActive = not model.formActive }, Cmd.none )

        SearchInput input ->
            ( { model | searchField = input }, Cmd.none )

        FormSubmit ->
            ( { model | searchField = "" }, getResponseFromWiki )

        Response result ->
            case result of
                Ok res ->
                    ( { model | searchResults = res }, Cmd.none )

                Err _ ->
                    ( { model | searchResults = [ { title = "error", pageid = 0, snippet = "" } ] }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ div [ class "nav" ]
            [ h1 [ class "title" ] [ text "Wikipedia Viewer" ]
            ]
        , div
            [ class "center" ]
            [ p []
                [ text "click "
                , a [ href "https://en.wikipedia.org/wiki/Special:Random", target "_blank", class "random" ] [ text "here" ]
                , text " to read a random article"
                ]
            , Html.form [ class (toggleForm model.formActive), onSubmit FormSubmit ]
                [ input [ class "input", onFocus ToggleActive, onBlur ToggleActive, onInput SearchInput ] [] ]
            , p [] [ text "click the icon to search" ]
            ]
        , div [ class "result-list" ] (List.map displaySearchResults model.searchResults)
        ]


displaySearchResults : ResponseObject -> Html Msg
displaySearchResults listItem =
    a [ class "result" ]
        [ h3 [ class "result-title" ] [ text listItem.title ]
        , p [] [ text listItem.snippet ]
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



-- Http


getResponseFromWiki : Cmd Msg
getResponseFromWiki =
    Http.get { url = wikiUrl, expect = Http.expectJson Response responseDecoder }


type alias ResponseObject =
    { title : String
    , pageid : Int
    , snippet : String
    }


resDecoder : Decoder ResponseObject
resDecoder =
    D.map3 ResponseObject (field "title" D.string) (field "pageid" D.int) (field "snippet" D.string)


resList : Decoder (List ResponseObject)
resList =
    D.list resDecoder


responseDecoder : Decoder (List ResponseObject)
responseDecoder =
    field "query" (field "search" resList)
