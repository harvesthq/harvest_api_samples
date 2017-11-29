module Tests exposing (..)

import Main exposing (..)
import Test exposing (..)
import Expect
import String


all : Test
all =
    describe ".decodeScope"
        [ test "given 'all'" <|
            \() ->
                Expect.equal (Just AllAccounts) (decodeScope "all")
        , test "given 'harvest:all'" <|
            \() ->
                Expect.equal (Just AllHarvestAccounts)
                    (decodeScope "harvest:all")
        , test "given 'forecast:all'" <|
            \() ->
                Expect.equal (Just AllForecastAccounts)
                    (decodeScope "forecast:all")
        , test "given 'harvest:12345'" <|
            \() ->
                Expect.equal (Just <| SpecifiedAccounts [ HarvestAccount 12345 ])
                    (decodeScope "harvest:12345")
        , test "given 'forecast:88888'" <|
            \() ->
                Expect.equal (Just <| SpecifiedAccounts [ ForecastAccount 88888 ])
                    (decodeScope "forecast:88888")
        , test "given 'harvest:12345+forecast:88888'" <|
            \() ->
                Expect.equal (Just <| SpecifiedAccounts [ HarvestAccount 12345, ForecastAccount 88888 ])
                    (decodeScope "harvest:12345+forecast:88888")
        , test "given 'invalid:scope'" <|
            \() ->
                Expect.equal Nothing (decodeScope "invalid:scope")
        ]
