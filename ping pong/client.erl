-module(client).
-export([
        start/0,
        start/1,
        stop/0,
        send_ping/0,
        send_ping/1,
        loop/1
]).

ensure_node() ->
    case node() of
        'nonode@nohost' ->
            os:cmd("epmd -daemon"),
            net_kernel:start(client, #{
                name_domain => shortnames
            });
        _ ->
            ok
    end.

start() ->
    start('server@root').

start(ServerNode) ->
    ensure_node(),
    case whereis(client) of
        undefined ->
            Pid = spawn(?MODULE, loop, [ServerNode]),
            register(client, Pid),
            {ok, node(), Pid};
        Pid ->
            {already_started, node(), Pid}
    end.

stop() ->
    case whereis(client) of
        undefined ->
            not_running;
        Pid ->
            Pid ! stop,
            ok
    end.

loop(ServerNode) ->
    send_ping(ServerNode),
    receive
        stop ->
            io:format("[client] stopped~n"),
            ok
    after 3000 ->
        loop(ServerNode)
    end.

send_ping() ->
    send_ping('server@root').

send_ping(ServerNode) ->
    ensure_node(),
    Pid = self(),
    io:format("My pid() ~p~n", [Pid]),
    {server, ServerNode} ! {Pid, ping},
    receive
        pong ->
            io:format("[client] get pong~n")
    after 5000 ->
        io:format("[client] timeout~n")
    end.
