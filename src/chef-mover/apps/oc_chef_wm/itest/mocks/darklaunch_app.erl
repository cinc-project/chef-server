%% -*- erlang-indent-level: 4;indent-tabs-mode: nil; fill-column: 92 -*-
%% ex: ts=4 sw=4 et
%% @author Stephen Delano <stephen@chef.io>
%% Copyright Chef Software, Inc. All Rights Reserved.

-module(darklaunch_app).

-behaviour(application).

-export([
         start/2,
         stop/1
        ]).

start(_StartType, _StartArgs) ->
    {ok, self()}.

stop(_State) ->
    ok.
