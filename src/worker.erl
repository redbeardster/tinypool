-module(worker).
-behaviour(gen_server).

-export([init/1]).
-export([handle_cast/2, handle_call/3, terminate/2,handle_info/2,
          code_change/3]).

-export([start_link/1]).

start_link(Args) ->
     gen_server:start_link(?MODULE, [Args], []).

init(Args) ->

     erlang:process_flag(trap_exit, true),
    
    io:format("Hello! I'm worker ~p~n",[self()]),
    %% {Conn, From, Req} = Args,
    %% SelectRes = epgsql:squery(Conn, Req),
    %% gen_server:reply(From, SelectRes),   
%    {ok, Conn}.
{ok, Args}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({async, Args}, State) -> 

    io:format("Pid: ~p~n", [self()]),
    {Conn, From, Req} = Args,
    SelectRes = epgsql:squery(Conn, Req),

    timer:sleep(3000),
    gen_server:reply(From, SelectRes),

    tinypool ! {done, self()},

{noreply, State};



handle_cast(_Msg, State) ->
     {noreply, State}.

handle_info(_Message, State) -> { noreply, State }.
code_change(_OldVersion, State, _Extra) -> { ok, State }.
terminate(_Reason, _State) ->
     ok.
