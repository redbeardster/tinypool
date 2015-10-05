-module(ch1).
-behaviour(gen_server).

% Callback functions which should be exported
-export([init/1]).
-export([handle_cast/2, terminate/2]).

% user-defined interface functions
-export([start_link/1]).

start_link(Args) ->
     gen_server:start_link(?MODULE, [Args], []).

init([Args]) ->
     erlang:process_flag(trap_exit, true),
     io:format("ch1 has started (~w)~n~n", [self()]),
   
     io:format("~w~n", [Args]),

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