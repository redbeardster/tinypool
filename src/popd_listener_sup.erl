-module(popd_listener_sup).
-behaviour(supervisor).
-export([start_link/0]).
-export([init/1]).

start_link() ->
    {ok, Pid} = supervisor:start_link({local,?MODULE}, ?MODULE, []),
    {ok, Pid}.

init([]) ->
    RestartStrategy = {simple_one_for_one, 10, 60},

    Listener = {worker, {worker, start_link, []},
            transient, 2000, worker, [worker]},

    Children = [Listener],

    {ok, {RestartStrategy, Children}}.
