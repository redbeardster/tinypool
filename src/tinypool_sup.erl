-module(tinypool_sup).
-behaviour(supervisor).
-export([start_link/0]).
-export([init/1, shutdown/0]).

start_link() ->
     supervisor:start_link({local,?MODULE}, ?MODULE, []).

init([]) ->

     RestartStrategy = {one_for_one, 10, 60},
     WorkerServer = {tinypool, {tinypool, start_link, []}, permanent, infinity,worker, [tinypool]},
     Children = [WorkerServer],
     {ok, {RestartStrategy, Children}}.    

shutdown() ->
     exit(whereis(?MODULE), shutdown).
