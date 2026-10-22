%% Copyright (c) 2026 Cinc Project

-module(chef_license_worker_test).

-include_lib("eunit/include/eunit.hrl").

-define(LICENSE_FILE, "/tmp/lic").
-define(NEVER_EXPIRES_DATE, "9999-12-31").
-define(DAY, 86400).

%% An expired commercial license in the shape the automate CLI used to write.
expired_commercial_license() ->
    <<"{\"status\":\"OK\",\"result\":{\"set\":true,\"license_id\":\"6541d90a-2ed0-4d64-9861-c20fc21a3093\","
      "\"customer_name\":\"example\",\"expiration_date\":{\"seconds\":1635689599},"
      "\"license_type\":\"commercial\"}}">>.

license_test_() ->
    {foreach,
     fun setup/0,
     fun cleanup/1,
     [fun no_license/1,
      fun installed_400_days_ago/1,
      fun ignores_license_file/1]}.

setup() ->
    file:delete(?LICENSE_FILE),
    meck:new(chef_sql, [non_strict, no_link]),
    ok.

cleanup(_) ->
    application:stop(chef_license),
    meck:unload(chef_sql),
    file:delete(?LICENSE_FILE).

installed(SecondsAgo) ->
    Itime = integer_to_binary(os:system_time(second) - SecondsAgo),
    meck:expect(chef_sql, select_rows, fun(_) -> [[{<<"value">>, Itime}]] end).

license() ->
    {Result, _Type, _Grace, ExpDate, _Msg, _CN, _Id} = chef_license_worker:get_license(),
    {Result, ExpDate}.

no_license(_) ->
    meck:expect(chef_sql, select_rows, fun(_) -> not_found end),
    ok = application:start(chef_license),
    ?_assertEqual({valid_license, ?NEVER_EXPIRES_DATE}, license()).

installed_400_days_ago(_) ->
    installed(400 * ?DAY),
    ok = application:start(chef_license),
    ?_assertEqual({valid_license, ?NEVER_EXPIRES_DATE}, license()).

ignores_license_file(_) ->
    installed(0),
    ok = file:write_file(?LICENSE_FILE, expired_commercial_license()),
    ok = application:start(chef_license),
    ?_assertEqual({valid_license, ?NEVER_EXPIRES_DATE}, license()).
