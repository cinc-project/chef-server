%% -*- erlang-indent-level: 4;indent-tabs-mode: nil; fill-column: 92 -*-
%% ex: ts=4 sw=4 et
%% @author Mark Mzyk <mmzyk@getchef.com>
%% @author Marc Paradise <marc@getchef.com>
%% @copyright 2012-14 Chef Software, Inc.

%% @doc Resource module for Chef users endpoint

-module(oc_chef_wm_users).


-include_lib("chef_wm/include/chef_wm.hrl").
-include_lib("oc_chef_wm.hrl").

-mixin([{chef_wm_base, [content_types_accepted/2,
                        content_types_provided/2,
                        finish_request/2,
                        malformed_request/2,
                        ping/2,
                        post_is_create/2]}]).

-mixin([{oc_chef_wm_base, [forbidden/2,
                          is_authorized/2,
                          service_available/2]}]).

-behavior(chef_wm).
-export([auth_info/2,
         init/1,
         init_resource_state/1,
         conflict_message/1,
         malformed_request_message/3,
         request_type/0,
         validate_request/3]).

-export([allowed_methods/2,
         create_path/2,
         from_json/2,
         resource_exists/2,
         to_json/2]).

init(Config) ->
  chef_wm_base:init(?MODULE, Config).

%% Need to add the user_state
init_resource_state(_Config) ->
  {ok, #user_state{}}.

request_type() ->
  "users".

allowed_methods(Req, State) ->
  {['GET', 'POST'], Req, State}.

validate_request('POST', Req, State) ->
  case wrq:req_body(Req) of
    undefined ->
      throw({error, missing_body});
   Body ->
      {ok, UserData} = chef_user:parse_binary_json(Body),
      {Req, State#base_state{resource_state =
          #user_state{user_data = UserData}}}
  end;
validate_request('GET', Req, State) ->
    {Req, State}.

auth_info(Req, State) ->
    auth_info(wrq:method(Req), Req, State).

auth_info('GET', Req, State) ->
    {{container, user}, Req, State};
auth_info('POST', Req, State) ->
    {{create_in_container, user}, Req, State}.

resource_exists(Req, State) ->
  {true, Req, State}.

create_path(Req, #base_state{resource_state = #user_state{user_data = UserData}} = State) ->
  Name = chef_user:username_from_ejson(UserData),
  {binary_to_list(Name), Req, State}.

from_json(Req, #base_state{reqid = RequestId,
                           resource_state = #user_state{user_data = UserData,
                           user_authz_id = AuthzId}} = State) ->
    Name = chef_user:username_from_ejson(UserData),
    {PublicKey, PrivateKey} = case chef_object_base:cert_or_key(UserData) of
        {undefined, _} ->
            chef_wm_util:generate_keypair(Name, RequestId);
        {PubKey, _PubKeyVersion} ->
            {PubKey, undefined}
    end,
    UserWithKey = chef_object_base:set_public_key(UserData, PublicKey),
    PasswordData = chef_wm_password:encrypt(ej:get({<<"password">>}, UserWithKey)),
    case chef_wm_base:create_from_json(Req, State, chef_user,
                                       {authz_id, AuthzId},
                                       {UserWithKey, PasswordData}) of
        {true, Req1, State1} ->
            Uri = ?BASE_ROUTES:route(user, Req1, [{name, Name}]),
            Ejson = ej:set({<<"private_key">>}, {[{<<"uri">>, Uri}]}, PrivateKey),
            {true, chef_wm_util:set_json_body(Req1, Ejson), State1};
        Else ->
            Else
    end.

to_json(Req, State) ->
    %% In the case of verbose, we cannot  use standard chef_wm_base behavior -
    %% the client expects the fields email, first_name, last_name - while
    %% the standard response tries to give us a URI.
    %% Secondary note: the original interface in opscode-account supported the combination of
    %% both email filter and verbose option, but this was unused
    %% and it adds further complication. It is not supported here now.
    case wrq:get_qs_value("verbose", Req) of
        "true" ->
            {chef_json:encode(verbose_users_as_ejson()), Req, State};
        _ ->
            chef_wm_base:list_objects_json(Req, State#base_state{resource_state =
                                                                 #chef_user{email = wrq:get_qs_value("email", Req)} })
    end.

verbose_users_as_ejson() ->
    case sqerl:select(list_users_verbose, [], {rows_as_records, [chef_user, record_info(fields, chef_user)]}) of
        {ok, none} ->
            {[{}]};
        {ok, Records} ->
            {[ verbose_user(User) || User  <- Records]}
    end.

verbose_user(#chef_user{username = UserName, email = EMail, serialized_object = SerializedObject }) ->
    EJ = chef_json:decode(SerializedObject),
    {UserName, {[ {<<"email">>, EMail},
                  {<<"first_name">>, ej:get({<<"first_name">>}, EJ, "")},
                  {<<"last_name">>, ej:get({<<"last_name">>}, EJ, "")} ]} }.



conflict_message(Name) ->
    Msg = iolist_to_binary([<<"User '">>, Name, <<"' already exists">>]),
    {[{<<"error">>, [Msg]}]}.

error_message(Msg) when is_list(Msg) ->
    error_message(iolist_to_binary(Msg));
error_message(Msg) when is_binary(Msg) ->
    {[{<<"error">>, [Msg]}]}.

malformed_request_message(#ej_invalid{type = json_type, key = Key}, _Req, _State) ->
    case Key of
        undefined -> error_message([<<"Incorrect JSON type for request body">>]);
        _ ->error_message([<<"Incorrect JSON type for ">>, Key])
    end;
malformed_request_message(#ej_invalid{type = missing, key = Key}, _Req, _State) ->
    error_message([<<"Required value for ">>, Key, <<" is missing">>]);
malformed_request_message({invalid_key, Key}, _Req, _State) ->
    error_message([<<"Invalid key ">>, Key, <<" in request body">>]);
malformed_request_message(invalid_json_body, _Req, _State) ->
    error_message([<<"Incorrect JSON type for request body">>]);
malformed_request_message(#ej_invalid{type = exact, key = Key, msg = Expected},
                          _Req, _State) ->
    error_message([Key, <<" must equal ">>, Expected]);
malformed_request_message(#ej_invalid{type = fun_match, key = Key, msg = Error},
                          _Req, _State) when Key =:= <<"password">> ->
    error_message([Error]);
malformed_request_message(#ej_invalid{type = string_match, msg = Error}, _Req, _State) ->
    error_message([Error]);
malformed_request_message(#ej_invalid{type = object_key, key = Object, found = Key},
                          _Req, _State) ->
    error_message([<<"Invalid key '">>, Key, <<"' for ">>, Object]);
% TODO: next two tests can get merged (hopefully) when object_map is extended not
% to swallow keys
malformed_request_message(#ej_invalid{type = object_value, key = Object, found = Val},
                          _Req, _State) when is_binary(Val) ->
    error_message([<<"Invalid value '">>, Val, <<"' for ">>, Object]);
malformed_request_message(#ej_invalid{type = object_value, key = Object, found = Val},
                          _Req, _State) ->
    error_message([<<"Invalid value '">>, io_lib:format("~p", [Val]),
                   <<"' for ">>, Object]);
malformed_request_message(Any, Req, State) ->
    chef_wm_util:malformed_request_message(Any, Req, State).
