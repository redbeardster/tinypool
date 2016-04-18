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
%   io:format("Hello! I'm worker ~p~n",[self()]),  
    {ok, Args}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({async, Args}, State) -> 

   io:format("Worker Pid: ~p~n", [self()]),
   io:format("Args is ~p~n", [Args]),
   {{From, Req}, Arguments} = Args,
   io:format("Client: ~p~n ", [From]),

  %% Method = post,
  %% URL = "http://localhost:2375/images/create?fromImage=" ++ Req,
  %% Header = [],
  %% Type = "",
  %% Body = "",
  %% HTTPOptions = [],
  %% Options = [],
  %% R = httpc:request(Method, {URL, Header, Type, Body}, HTTPOptions, Options),  

    timer:sleep(6000),
    From ! hello,
 
    tinypool ! {done, self()},
    {noreply, State};

handle_cast(_Msg, State) ->
     {noreply, State}.

handle_info({async, Args}, State) -> 

    {Conn, From, Req} = Args,
    Method = post,
    URL = "http://localhost:2375/images/create?fromImage=" ++ Req,
    Header = [],
    Type = "",
    Body = "",
    HTTPOptions = [],
    Options = [],
    R = httpc:request(Method, {URL, Header, Type, Body}, HTTPOptions, Options),   
    gen_server:reply(From, R),
    tinypool ! {done, self()},
{noreply, State };

handle_info(_Message, State) -> 
{ noreply, State }.

code_change(_OldVersion, State, _Extra) -> { ok, State }.
terminate(_Reason, _State) ->
     ok.
