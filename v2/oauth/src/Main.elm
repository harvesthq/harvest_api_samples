module Main exposing (..)

import Erl
import Erl.Query
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import HttpBuilder exposing (..)
import Json.Decode as Json
import Json.Decode.Pipeline as JsonPipeline
import Maybe.Extra
import RemoteData exposing (WebData, RemoteData(..))


main : Program String Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }



---- MODEL ----


type alias Model =
    { url : URL
    , authentication : Maybe Authentication
    , maybeUser : Maybe User
    , maybeAccounts : Maybe (List Account)
    , maybeAccountId : Maybe AccountId
    , exampleResponse : WebData User
    , accountsResponse : WebData AccountsResponse
    }


type alias URL =
    String


type alias Authentication =
    { token : AccessToken
    , scope : Scope
    }


type alias AccessToken =
    String


type Scope
    = AllAccounts
    | AllHarvestAccounts
    | AllForecastAccounts
    | SpecifiedAccounts (List AccountScope)


type AccountScope
    = HarvestAccount AccountId
    | ForecastAccount AccountId


type alias AccountId =
    ID


type alias User =
    { id : UserId
    , firstName : String
    , lastName : String
    , email : String
    }


type alias UserId =
    ID


type alias Account =
    { id : AccountId
    , name : String
    , product : Product
    }


type Product
    = Harvest
    | Forecast


type alias ID =
    Int


type alias AccountsResponse =
    { user : User
    , accounts : List Account
    }


init : String -> ( Model, Cmd Msg )
init url =
    let
        maybeAuthentication =
            parseAuthentication url

        initialModel =
            Model url Nothing Nothing Nothing Nothing NotAsked NotAsked
    in
        case maybeAuthentication of
            Just authentication ->
                ( { initialModel | authentication = Just authentication }
                , fetchAccounts authentication
                )

            Nothing ->
                ( initialModel, Cmd.none )


parseAuthentication : URL -> Maybe Authentication
parseAuthentication url =
    let
        parsedUrl =
            Erl.parse url

        queryParams =
            parsedUrl.query
    in
        case ( Erl.Query.getValuesForKey "access_token" queryParams, Erl.Query.getValuesForKey "scope" queryParams ) of
            ( accessToken :: [], scope :: [] ) ->
                decodeAuthentication accessToken scope

            _ ->
                Nothing


decodeAuthentication : String -> String -> Maybe Authentication
decodeAuthentication accessToken encodedScope =
    Maybe.map (Authentication accessToken) (decodeScope encodedScope)


decodeScope : String -> Maybe Scope
decodeScope encodedScope =
    case encodedScope of
        "all" ->
            Just AllAccounts

        "harvest:all" ->
            Just AllHarvestAccounts

        "forecast:all" ->
            Just AllForecastAccounts

        "" ->
            Nothing

        encodedAccounts ->
            parseSpecifiedAccounts (Debug.log "encodedAccounts" encodedAccounts)


parseSpecifiedAccounts : String -> Maybe Scope
parseSpecifiedAccounts encodedAccounts =
    encodedAccounts
        |> String.split "+"
        |> List.map parseSpecifiedAccount
        |> Maybe.Extra.combine
        |> Maybe.map SpecifiedAccounts


parseSpecifiedAccount : String -> Maybe AccountScope
parseSpecifiedAccount encodedAccountScope =
    case String.split ":" encodedAccountScope of
        product :: accountIdString :: [] ->
            case String.toInt accountIdString of
                Ok accountId ->
                    case product of
                        "harvest" ->
                            Just <| HarvestAccount accountId

                        "forecast" ->
                            Just <| ForecastAccount accountId

                        _ ->
                            Nothing

                Err _ ->
                    Nothing

        _ ->
            Nothing


accountsUrl : URL
accountsUrl =
    "https://id.getharvest.com/api/v1/accounts"


exampleRequestUrl : URL
exampleRequestUrl =
    "https://api.harvestapp.com/v2/users/me"


parsedUrlWithoutParams : URL -> Erl.Url
parsedUrlWithoutParams url =
    let
        parsedUrl =
            Erl.parse url

        port_ =
            if List.member parsedUrl.port_ [ 80, 443 ] then
                0
            else
                parsedUrl.port_
    in
        { parsedUrl | port_ = port_, query = Erl.Query.parse "", hash = "" }


baseUrl : URL -> URL
baseUrl currentUrl =
    Erl.toString <| parsedUrlWithoutParams currentUrl


originUrl : URL -> URL
originUrl currentUrl =
    let
        parsedUrl =
            parsedUrlWithoutParams currentUrl
    in
        Erl.toString { parsedUrl | path = [], hasTrailingSlash = False }



---- UPDATE ----


type Msg
    = SelectAccount String
    | SendExampleRequest
    | AnotherRequest
    | HandleExampleResponse (WebData User)
    | HandleAccountsResponse (WebData AccountsResponse)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectAccount accountIdString ->
            let
                newAccountId =
                    case String.toInt accountIdString of
                        Ok accountId ->
                            Just accountId

                        Err _ ->
                            Nothing
            in
                ( { model | maybeAccountId = newAccountId }, Cmd.none )

        SendExampleRequest ->
            case model.authentication of
                Just authentication ->
                    case model.maybeAccountId of
                        Just accountId ->
                            ( model, sendExampleRequest authentication accountId )

                        Nothing ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        AnotherRequest ->
            ( { model | exampleResponse = NotAsked }, Cmd.none )

        HandleExampleResponse user ->
            ( { model | exampleResponse = user }, Cmd.none )

        HandleAccountsResponse accountsResponseData ->
            case accountsResponseData of
                Success accountsResponse ->
                    ( { model
                        | maybeUser = Just accountsResponse.user
                        , maybeAccounts = Just accountsResponse.accounts
                        , maybeAccountId = List.head accountsResponse.accounts |> Maybe.map .id
                        , accountsResponse = accountsResponseData
                      }
                    , Cmd.none
                    )

                Failure error ->
                    let
                        _ =
                            Debug.log "Error fetching account list" error
                    in
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


fetchAccounts : Authentication -> Cmd Msg
fetchAccounts authentication =
    HttpBuilder.get accountsUrl
        |> withHeader "Authorization" ("Bearer " ++ authentication.token)
        |> withHeader "Accept" "application/json"
        |> withExpect (Http.expectJson accountsResponseDecoder)
        |> toRequest
        |> RemoteData.sendRequest
        |> Cmd.map HandleAccountsResponse


sendExampleRequest : Authentication -> AccountId -> Cmd Msg
sendExampleRequest authentication accountId =
    HttpBuilder.get exampleRequestUrl
        |> withHeader "Authorization" ("Bearer " ++ authentication.token)
        |> withHeader "Harvest-Account-ID" (toString accountId)
        |> withHeader "Accept" "application/json"
        |> withExpect (Http.expectJson userDecoder)
        |> toRequest
        |> RemoteData.sendRequest
        |> Cmd.map HandleExampleResponse


accountsResponseDecoder : Json.Decoder AccountsResponse
accountsResponseDecoder =
    JsonPipeline.decode AccountsResponse
        |> JsonPipeline.required "user" userDecoder
        |> JsonPipeline.required "accounts" (Json.list accountDecoder)


userDecoder : Json.Decoder User
userDecoder =
    JsonPipeline.decode User
        |> JsonPipeline.required "id" Json.int
        |> JsonPipeline.required "first_name" Json.string
        |> JsonPipeline.required "last_name" Json.string
        |> JsonPipeline.required "email" Json.string


accountDecoder : Json.Decoder Account
accountDecoder =
    JsonPipeline.decode Account
        |> JsonPipeline.required "id" Json.int
        |> JsonPipeline.required "name" Json.string
        |> JsonPipeline.required "product" productDecoder


productDecoder : Json.Decoder Product
productDecoder =
    Json.string
        |> Json.andThen
            (\productString ->
                case productString of
                    "harvest" ->
                        Json.succeed Harvest

                    "forecast" ->
                        Json.succeed Forecast

                    _ ->
                        Json.fail <| "Unknown product: " ++ productString
            )



---- VIEW ----


view : Model -> Html Msg
view model =
    let
        content =
            case model.authentication of
                Just authentication ->
                    authenticatedView authentication model

                Nothing ->
                    unauthenticatedView model
    in
        div
            []
            [ nav
                [ class "navbar navbar-expand-md navbar-dark bg-dark fixed-top" ]
                [ a [ class "navbar-brand", href "#" ] [ text "Harvest v2 API OAuth Example" ]
                ]
            , node "main" [ class "container" ] [ content ]
            ]


unauthenticatedView : Model -> Html Msg
unauthenticatedView model =
    div
        []
        [ gettingStartedView model.url
        , formView model
        ]


gettingStartedView : String -> Html Msg
gettingStartedView url =
    div
        [ class "alert alert-primary" ]
        [ h3 [] [ text "Getting Started" ]
        , p
            []
            [ text "You'll need to set up an OAuth client in Harvest ID by completing "
            , a [ href "https://id.getharvest.com/oauth2/clients/new" ] [ text "this form" ]
            , text ". Make sure to use "
            , code [] [ text <| baseUrl url ]
            , text " for the Redirect URL and "
            , code [] [ text <| originUrl url ]
            , text " for the Origin URL. Once that's been created "
            , text "copy the Client ID from the Parameters section and paste it in the "
            , text "form below."
            ]
        ]


formView : Model -> Html Msg
formView model =
    Html.form
        [ method "GET", action "https://id.getharvest.com/oauth2/authorize" ]
        [ input [ type_ "hidden", name "response_type", value "token" ] []
        , div
            [ class "form-group row" ]
            [ label [ class "col-form-label" ] [ text "Client ID:" ]
            , div
                [ class "col-sm-3" ]
                [ input [ name "client_id", class "form-control " ] []
                ]
            , small
                [ class "form-text text-muted" ]
                [ text "Get this from the "
                , a
                    [ href "https://id.getharvest.com/developers" ]
                    [ text "Developers section of Harvest ID" ]
                , text "."
                ]
            ]
        , div
            [ class "form-group row" ]
            [ button [ class "btn btn-primary" ] [ text "Connect to Harvest" ]
            ]
        ]


authenticatedView : Authentication -> Model -> Html Msg
authenticatedView authentication model =
    div
        []
        [ authenticationView authentication model
        , accountsResponseView model
        , exampleRequestView model
        ]


authenticationView : Authentication -> Model -> Html Msg
authenticationView authentication model =
    cardView
        [ text "Authentication" ]
        [ labeledValueView "Access token" authentication.token
        , labeledValueView "Scope" (toString authentication.scope)
        , case model.maybeUser of
            Just user ->
                labeledValueView "User" (toString user)

            Nothing ->
                text ""
        , a [ href <| baseUrl model.url, class "btn btn-danger btn-sm" ] [ text "Start over" ]
        ]


accountsResponseView : Model -> Html Msg
accountsResponseView model =
    cardView
        [ text "GET", code [] [ text accountsUrl ] ]
        [ case model.accountsResponse of
            NotAsked ->
                code [] [ text "Loading..." ]

            Loading ->
                code [] [ text "Loading..." ]

            Failure error ->
                div [] [ code [] [ text <| toString error ] ]

            Success accounts ->
                labeledValueView "Response body" (toString accounts)
        ]


exampleRequestView : Model -> Html Msg
exampleRequestView model =
    let
        anotherRequestLink =
            a
                [ href "#"
                , onClick <| AnotherRequest
                , class "btn btn-link"
                ]
                [ text "Try Another Request" ]
    in
        cardView
            [ text "GET ", code [] [ text exampleRequestUrl ] ]
            [ case model.exampleResponse of
                NotAsked ->
                    exampleRequestFormView model

                Loading ->
                    code [] [ text "Loading..." ]

                Failure error ->
                    div
                        []
                        [ code [] [ text <| toString error ]
                        , anotherRequestLink
                        ]

                Success user ->
                    div
                        []
                        [ labeledValueView "Response body" (toString user)
                        , anotherRequestLink
                        ]
            ]


exampleRequestFormView : Model -> Html Msg
exampleRequestFormView model =
    let
        accountOptions =
            case model.maybeAccounts of
                Just accounts ->
                    List.map accountOption accounts

                Nothing ->
                    []

        accountOption account =
            option [ value <| toString account.id ] [ text account.name ]
    in
        div
            [ class "form-inline" ]
            [ div
                [ class "form-group" ]
                [ label [ class "mr-sm-2 font-weight-bold" ] [ text "Account: " ]
                , select
                    [ onInput <| SelectAccount
                    , class "custom-select mb-2 mr-sm-2 mb-sm-0"
                    ]
                    accountOptions
                ]
            , div
                [ class "form-group" ]
                [ button
                    [ onClick SendExampleRequest
                    , class "btn btn-primary"
                    ]
                    [ text "Send Authenticated Request" ]
                ]
            ]


cardView : List (Html Msg) -> List (Html Msg) -> Html Msg
cardView header content =
    div
        [ class "card mb-3" ]
        [ h4 [ class "card-header" ] header
        , div [ class "card-body" ] content
        ]


labeledValueView : String -> String -> Html Msg
labeledValueView title value =
    div
        []
        [ label [ class "mr-sm-1 font-weight-bold" ] [ text <| title ++ ": " ]
        , code [ class "sm" ] [ text value ]
        ]
