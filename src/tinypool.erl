-module(tinypool).
-behaviour(gen_server).
-define(SERVER, ?MODULE).

-export([start_link/0]).


-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-export([run/1]).

-record(state, {limit=2,
    sup,
    refs,
    queue=queue:new(), conn}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

 run(Args) ->

     gen_server:call(?SERVER, {run, Args}).

init(Args) ->

    self() ! {start_worker_supervisor},

    {ok, C} = epgsql:connect("localhost", "kb", "123", [
    {database, "kb"},
    {timeout, 4000}]),   

    {ok, #state{limit=2, refs=gb_sets:empty(), conn=C}}.

handle_call({run, Args}, _From, S = #state{limit=N, sup=Sup, refs=R}) when N > 0 ->

%%    Listener = {ch1, {ch1, start_link, [Args]},
%%            temporary, 2000, worker, [ch1]},

    {ok, Pid} = supervisor:start_child(Sup, [S#state.conn]),
    
    Ref = erlang:monitor(process, Pid),

    gen_server:cast(Pid, calc),
    {reply, {ok,Pid}, S#state{limit=N-1, refs=gb_sets:add(Ref,R)}};

handle_call({run, _Args}, _From, S=#state{limit=N}) when N =< 0 ->

    {reply, noalloc, S};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({add_worker}, S = #state{}) ->
    
    WorkSupPid = S#state.sup,

    {ok, WorkerPid} = supervisor:start_child(WorkSupPid, []),

    % gen_server:cast(WorkerPid, calc),

    {noreply, S};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({start_worker_supervisor}, S = #state{}) ->

    SPEC = {popd_listener_sup, {popd_listener_sup, start_link, []}, permanent, infinity, supervisor, [popd_listener_sup]},
    
    {ok, Pid} = supervisor:start_child(tinypool_sup, SPEC),
    link(Pid),
    {noreply, S#state{sup=Pid}};

handle_info(_Info, State) ->
    io:format("We got ~w~n", [_Info]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

