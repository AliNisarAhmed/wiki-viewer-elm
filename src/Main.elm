module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Parser
import Html.Parser.Util
import Http
import Json.Decode as D exposing (..)
import Url exposing (percentEncode)



---- MODEL ----


type alias Model =
    { formActive : Bool
    , searchField : String
    , searchResults : List ResponseObject
    , isLoading : Bool
    }


wikiUrl : String
wikiUrl =
    "https://cors-anywhere.herokuapp.com/https://en.wikipedia.org/w/api.php?action=query&format=json&list=search&utf8=1&srsearch="


initModel : Model
initModel =
    { formActive = False
    , searchField = ""
    , searchResults = []
    , isLoading = False
    }


init : ( Model, Cmd Msg )
init =
    ( initModel, Cmd.none )



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
            let
                field =
                    case model.formActive of
                        False ->
                            model.searchField

                        True ->
                            ""
            in
            ( { model | formActive = not model.formActive, searchField = field }, Cmd.none )

        SearchInput input ->
            ( { model | searchField = input }, Cmd.none )

        FormSubmit ->
            let
                searchBy =
                    model.searchField
            in
            ( { model | searchField = "", isLoading = True }, getResponseFromWiki searchBy )

        Response result ->
            case result of
                Ok res ->
                    ( { model | searchResults = res, isLoading = False }, Cmd.none )

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
                [ input [ Html.Attributes.value model.searchField, class "input", onFocus ToggleActive, onBlur ToggleActive, onInput SearchInput, required True ] [] ]
            , p [] [ text "click the icon to search" ]
            ]
        , displayLoadingIconOrSearchResults model
        ]


displayLoadingIconOrSearchResults : Model -> Html Msg
displayLoadingIconOrSearchResults model =
    case model.isLoading of
        True ->
            div [ class "loading-icon-parent" ]
                [ div [ class "loading-icon" ] [] ]

        False ->
            div [ class "result-list" ] (List.map displaySearchResults model.searchResults)


displaySearchResults : ResponseObject -> Html Msg
displaySearchResults listItem =
    a [ class "result", href ("https://en.wikipedia.org/wiki?curid=" ++ String.fromInt listItem.pageid), target "_blank" ]
        [ h3 [ class "result-title" ] [ text listItem.title ]
        , div [] (displaySnippet listItem.snippet)
        ]


toggleForm : Bool -> String
toggleForm x =
    case x of
        True ->
            "active"

        _ ->
            ""


displaySnippet : String -> List (Html Msg)
displaySnippet str =
    case Html.Parser.run str of
        Ok res ->
            Html.Parser.Util.toVirtualDom res

        Err _ ->
            [ p [] [ text "something went wrong parsing the snippet" ] ]



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


getResponseFromWiki : String -> Cmd Msg
getResponseFromWiki searchField =
    Http.get { url = wikiUrl ++ percentEncode searchField, expect = Http.expectJson Response responseDecoder }


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
