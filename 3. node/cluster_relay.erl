-module(cluster_relay).
-export([start_receiver/0, send_alert/3, receiver_loop/0]).

start_receiver() ->
    Pid = spawn(?MODULE, receiver_loop, []),
    register(alert_inbox, Pid),
    {ok, Pid}.

receiver_loop() ->
    receive
        {alert, FromNode, Severity, Message} ->
            io:format("[~p] Alert from ~p: ~s~n", [Severity, FromNode, Message]),
            receiver_loop();
        stop ->
            io:format("Stopping alert_inbox receiver.~n");
        Other ->
            io:format("Received unknown message: ~p~n", [Other]),
            receiver_loop()
    end.

send_alert(TargetNode, Severity, Message) ->
    case net_adm:ping(TargetNode) of
        pong ->
            {alert_inbox, TargetNode} ! {alert, node(), Severity, Message},
            {ok, sent};
        pang ->
            {error, {unreachable_node, TargetNode}}
    end.
