-module(client).
-export([
	join/1, 
	join/2, 
	say/1, 
	leave/0, 
	listener/1
]).

to_atom(Val) when is_atom(Val) -> Val;
to_atom(Val) when is_list(Val) -> list_to_atom(Val).

ensure_node(NodeName) ->
    case node() of
        'nonode@nohost' ->
            os:cmd("epmd -daemon"),
            net_kernel:start(NodeName, #{name_domain => shortnames});
        _ ->
            ok
    end.

join(Username) ->
    join(Username, 'server@root').

join(Username, ServerNode) ->
    UserAtom = to_atom(Username),
    ensure_node(UserAtom),
    case whereis(client_listener) of
        undefined ->
            case net_adm:ping(ServerNode) of
                pong ->
                    Pid = spawn(?MODULE, listener, [ServerNode]),
                    register(client_listener, Pid),
                    {server, ServerNode} ! {join, self(), Pid, UserAtom},
                    receive
                        {joined, ok} ->
                            io:format("Connected to ~p as ~p~n", [ServerNode, UserAtom]),
                            ok;
                        {join_error, Reason} ->
                            catch unregister(client_listener),
                            Pid ! stop_local,
                            io:format("Failed to join: ~p~n", [Reason]),
                            {error, Reason}
                    after 5000 ->
                        catch unregister(client_listener),
                        Pid ! stop_local,
                        io:format("Timeout: server process is not yet active (run server:start().).~n"),
                        timeout
                    end;
                pang ->
                    io:format("Node ~p not found. Run server:start(). in the server terminal first.~n", [ServerNode]),
                    server_unreachable
            end;
        Pid ->
            {already_joined, node(), Pid}
    end.

say(Text) ->
    case whereis(client_listener) of
        undefined ->
            not_connected;
        Pid ->
            Pid ! {outgoing, Text},
            ok
    end.

leave() ->
    case whereis(client_listener) of
        undefined ->
            not_connected;
        Pid ->
            Pid ! leave,
            ok
    end.

listener(ServerNode) ->
    receive
        {outgoing, Text} ->
            {server, ServerNode} ! {send, self(), Text},
            listener(ServerNode);
        {incoming, Msg} ->
            io:format("~n~ts~n", [Msg]),
            listener(ServerNode);
        leave ->
            {server, ServerNode} ! {leave, self()},
            io:format("Exit the chat room.~n"),
            ok;
        stop_local ->
            ok;
        _ ->
            listener(ServerNode)
    end.
