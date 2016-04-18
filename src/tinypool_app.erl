-module(tinypool_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    sync:go(),
    application:ensure_all_started(inets),
    tinypool_sup:start_link().

stop(_State) ->
    ok.
