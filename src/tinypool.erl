-module(tinypool).
-behaviour(gen_server).
-define(SERVER, ?MODULE).
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).
-export([run/1, async/1, check_wrktable/0]).
-record(state, {limit=10,
    sup,
     refs,
     refpids,
     queue=queue:new(),
		conn}).

check_wrktable() ->
    io:format("Pids: ~p~n", [ets:match(pidtab, '$1')]).

prepopulate (_TableName, 0) ->
    ok;
prepopulate (TableName, WorkersNum) ->
    {ok, Pid} = supervisor:start_child(popd_listener_sup, [""]),
    unlink(Pid),
    ets:insert(TableName, {Pid, Pid}),    _Ref = erlang:monitor(process, Pid),
    prepopulate(TableName, WorkersNum -1).   

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
run(Args) ->
     gen_server:call(?SERVER, {run, Args}).

async(Args) -> 
    gen_server:call(?SERVER, {async, Args}).

init(_Args) ->
       
    _Pidtab = ets:new(pidtab, [named_table, public, set]),
    self() ! {start_worker_supervisor},
    {ok, C} = epgsql:connect("localhost", "kb", "123", [{database, "kb"},{timeout, 4000}]),      
    {ok, #state{limit=10, refs=gb_sets:empty(), refpids = gb_sets:new(), conn=C}}.

handle_call({async, Args}, From, State = #state{limit=N}) when N > 0->

    io:format("N is: ~p~n", [N]),
    [{Pid, _}] = lists:nth(1, ets:match(pidtab, '$1')),  
    io:format("Chosen pid: ~p~n", [Pid]),
    ets:delete(pidtab, Pid),   
    io:format("Left PIDS: ~p~n", [ets:match(pidtab, '$1')]),
    gen_server:cast(Pid, {async, {State#state.conn, From, Args}}),
    {noreply,  State#state{limit=N-1}};

 handle_call({async, Args}, From, State = #state{limit=N, queue=Q}) when N =<0 ->
    
     io:format("No workers! From:~p Args:~p ~n",[From, Args]),
     {reply, noalloc, State#state{queue=queue:in({From, Args}, Q)}};

%% handle_call({run, Args}, From, S = #state{limit=N, sup=Sup, refs=R, refpids = Rpids} ) when N > 0 ->
%%     io:format("Supervisor PID: ~p~n", [Sup]),   
%%     {ok, Pid} = supervisor:start_child(Sup, [{S#state.conn, From, Args}]),
%%     ets:insert(pidtab, {Pid, Pid}),
%%     Ref = erlang:monitor(process, Pid),
%%     io:format("Pid refs are: ~p~n", [S#state.refpids]),
%%     {reply, {ok,Pid}, S#state{limit=N-1, refs=gb_sets:add(Ref,R), refpids=gb_sets:add(Pid, Rpids)}};
%% handle_call({run, Args}, From, S=#state{limit=N, queue=Q}) when N =< 0 ->
%%      io:format("Pid refs are: ~p~n", [S#state.refpids]),
%%  io:format("Enqueued: ~p~n",[ S#state{queue=queue:in({From, Args}, Q)}]),
%%     {reply, noalloc, S#state{queue=queue:in({From, Args}, Q)}};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
     {noreply, State}.

handle_info ({done, Pid}, State=#state{queue=Q, limit=L}) ->
    
    ets:insert(pidtab, {Pid,Pid}),
    
    EQ = queue:is_empty(Q),

    if EQ == true -> 
	    ets:insert(pidtab, {Pid,Pid});
       true -> 
	    io:format("Queue: ~p~n",[queue:get_r(Q)])
    end,
    {noreply, State#state{limit=L+1}};

handle_info({start_worker_supervisor}, S = #state{}) ->

    SPEC = {popd_listener_sup, {popd_listener_sup, start_link, []}, permanent, infinity, supervisor, [popd_listener_sup]},
    
    {ok, Pid} = supervisor:start_child(tinypool_sup, SPEC),
    link(Pid),

   prepopulate(pidtab, 10),

    {noreply, S#state{sup=Pid}};

handle_info(_Info, State) ->
    io:format("We got ~w~n", [_Info]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

