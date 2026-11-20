-module(server).
-export([
	start/0, 
	stop/0, 
	loop/1
]).

ensure_node() ->
    case node() of
        'nonode@nohost' ->
            os:cmd("epmd -daemon"),
            net_kernel:start(server, #{name_domain => shortnames});
        _ ->
            ok
    end.

start() ->
    ensure_node(),
    case whereis(server) of
        undefined ->
            Pid = spawn(?MODULE, loop, [[]]),
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

broadcast(Clients, Msg) ->
    lists:foreach(fun({Pid, _, _}) -> Pid ! {incoming, Msg} end, Clients).

loop(Clients) ->
    receive
        {join, CallerPid, ListenerPid, Username} ->
            case lists:keymember(Username, 2, Clients) of
                true ->
                    CallerPid ! {join_error, username_taken},
                    loop(Clients);
                false ->
                    Ref = erlang:monitor(process, ListenerPid),
                    Notice = lists:flatten(io_lib:format("[INFO] ~s join the chat.", [Username])),
                    broadcast(Clients, Notice),
                    io:format("~s~n", [Notice]),
                    CallerPid ! {joined, ok},
                    loop([{ListenerPid, Username, Ref} | Clients])
            end;

        {send, FromPid, Text} ->
            case lists:keyfind(FromPid, 1, Clients) of
                {FromPid, Username, _} ->
                    Formatted = lists:flatten(io_lib:format("[~s]: ~ts", [Username, Text])),
                    io:format("~s~n", [Formatted]),
                    Others = lists:keydelete(FromPid, 1, Clients),
                    broadcast(Others, Formatted);
                false ->
                    ok
            end,
            loop(Clients);

        {leave, FromPid} ->
            case lists:keytake(FromPid, 1, Clients) of
                {value, {FromPid, Username, Ref}, Rest} ->
                    erlang:demonitor(Ref, [flush]),
                    Notice = lists:flatten(io_lib:format("[INFO] ~s exit the chat room.", [Username])),
                    broadcast(Rest, Notice),
                    io:format("~s~n", [Notice]),
                    loop(Rest);
                false ->
                    loop(Clients)
            end;

        {'DOWN', Ref, process, FromPid, _Reason} ->
            case lists:keytake(FromPid, 1, Clients) of
                {value, {FromPid, Username, Ref}, Rest} ->
                    Notice = lists:flatten(io_lib:format("[INFO] ~s disconnected.", [Username])),
                    broadcast(Rest, Notice),
                    io:format("~s~n", [Notice]),
                    loop(Rest);
                false ->
                    loop(Clients)
            end;

        stop ->
            broadcast(Clients, "[INFO] Chat server is down."),
            io:format("Chat server stopped.~n"),
            ok;

        _ ->
            loop(Clients)
    end.
