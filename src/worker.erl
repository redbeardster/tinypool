-module(worker).
-behaviour(gen_server).

-export([init/1]).
-export([handle_cast/2, terminate/2]).

-export([start_link/1]).

start_link(Args) ->
     gen_server:start_link(?MODULE, [Args], []).

init([Args]) ->
     erlang:process_flag(trap_exit, true),
     io:format("ch1 has started (~w)~n~n", [self()]),
   
     io:format("~w~n", [Args]),
     
     SelectRes = epgsql:squery(Args, "select * from employees"),
     io:format("Selected: ~p~n", [SelectRes]),         

     {ok, []}.

handle_cast(calc, State) ->
     io:format("result 2+2=4~n"),
     {noreply, State};
handle_cast(calcbad, State) ->
     io:format("result 1/0~n"),
     1 / 0,
     {noreply, State}.

terminate(_Reason, _State) ->
     io:format("ch1: terminating.~n"),
     ok.