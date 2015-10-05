-module(popd_listener_sup).
-behaviour(supervisor).
-export([start_link/0]).
-export([init/1]).

start_link() ->
    {ok, Pid} = supervisor:start_link({local,?MODULE}, ?MODULE, []),
    {ok, Pid}.

init([]) ->
    RestartStrategy = {simple_one_for_one, 10, 60},

    Listener = {ch1, {ch1, start_link, []},
            temporary, 2000, worker, [ch1]},

    Children = [Listener],

    {ok, {RestartStrategy, Children}}.