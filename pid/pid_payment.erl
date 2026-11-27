-module(pid_payment).
-export([process_checkout/2, payment_worker/0]).

%% Main entry point: spawns a worker PID, sends a request, and awaits the reply
process_checkout(OrderId, Amount) ->
    %% 1. Spawn a new process and capture its PID
    WorkerPid = spawn(?MODULE, payment_worker, []),
    io:format("Main process ~p spawned worker ~p~n", [self(), WorkerPid]),

    %% 2. Send a message to WorkerPid, including self() as the return address
    WorkerPid ! {verify_payment, self(), OrderId, Amount},

    %% 3. Wait for the worker's response in our mailbox
    receive
        {payment_result, OrderId, Status} ->
            io:format("Order ~p status received from worker: ~p~n", [OrderId, Status]),
            {ok, OrderId, Status}
    after 3000 ->
        {error, timeout}
    end.

%% Worker process loop: receives a request and replies to CallerPid
payment_worker() ->
    receive
        {verify_payment, CallerPid, OrderId, Amount} when Amount > 0 ->
            io:format("Worker ~p verifying $~p for order ~p...~n", [self(), Amount, OrderId]),
            %% Send the result back to the requester's PID
            CallerPid ! {payment_result, OrderId, approved};
        {verify_payment, CallerPid, OrderId, _InvalidAmount} ->
            CallerPid ! {payment_result, OrderId, rejected}
    end.
