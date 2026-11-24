
-module(pattern_demo).
-export([describe_shape/1, sum_list/1, classify_age/1, run/0]).

describe_shape({circle, Radius}) when is_number(Radius), Radius >= 0 ->
    {circle, Radius, math:pi() * Radius * Radius};
describe_shape({rectangle, Width, Height}) when Width >= 0, Height >= 0 ->
    {rectangle, Width, Height, Width * Height};
describe_shape({square, Side}) when Side >= 0 ->
    {square, Side, Side * Side};
describe_shape(Other) ->
    {unknown_shape, Other}.

sum_list([]) ->
    0;
sum_list([Head | Tail]) when is_number(Head) ->
    Head + sum_list(Tail).

classify_age(Age) when is_integer(Age), Age < 0 ->
    invalid_age;
classify_age(Age) when is_integer(Age), Age < 13 ->
    child;
classify_age(Age) when is_integer(Age), Age < 20 ->
    teenager;
classify_age(Age) when is_integer(Age) ->
    adult;
classify_age(_) ->
    non_integer_input.

run() ->
    io:format("Circle: ~p~n", [describe_shape({circle, 5})]),
    io:format("Rectangle: ~p~n", [describe_shape({rectangle, 4, 6})]),
    io:format("Sum [1, 2, 3, 4]: ~p~n", [sum_list([1, 2, 3, 4])]),
    io:format("Age 16: ~p~n", [classify_age(16)]),
    ok.
