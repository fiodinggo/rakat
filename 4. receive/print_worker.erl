-module(print_worker).
-export([start/0, loop/0]).

%% Start the background worker process
start() ->
    spawn(?MODULE, loop, []).

%% Persistent receive loop using selective receive and timeout
loop() ->
    receive
        %% Priority clause: matched first even if normal jobs arrived earlier
        {urgent_print, User, FileName} ->
            io:format("[URGENT] Printing ~s for ~s immediately!~n", [FileName, User]),
            loop();

        %% Standard job clause
        {print_doc, User, FileName} ->
            io:format("[NORMAL] Printing ~s for ~s.~n", [FileName, User]),
            loop();

        %% Graceful shutdown clause
        stop ->
            io:format("Print worker shutting down.~n")
    after 5000 ->
        %% Runs if no matching message arrives within 5000 ms (5 seconds)
        io:format("[IDLE] Waiting for print jobs...~n"),
        loop()
    end.
