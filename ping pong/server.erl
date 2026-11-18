-module(server).
-export([
        start/0,
        stop/0,
        loop/0
]).

ensure_node() ->
    case node() of
        'nonode@nohost' ->
            os:cmd("epmd -daemon"),
            net_kernel:start(server, #{
                name_domain => shortnames
            });
        _ ->
            ok
    end.

start() ->
    ensure_node(),
    case whereis(server) of
        undefined ->
            Pid = spawn(?MODULE, loop, []),
            register(server, Pid),
            {ok, node(), Pid};
        Pid ->
            {already_started, node(), Pid}
    end.

stop() ->
    case whereis(server) of
        undefined ->
            not_running;
        Pid ->
            Pid ! stop,
            ok
    end.

loop() ->
    receive
        {From, ping} ->
            io:format("[server] get ping from ~p~n", [From]),
            From ! pong,
            loop();
        stop ->
            io:format("[server] server stopped~n"),
            ok;
        {From, _} ->
            io:format("[server] get unk from ~p~n", [From]),
            From ! 'unknown message',
            loop()
    end.
