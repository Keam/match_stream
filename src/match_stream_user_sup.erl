%%%-------------------------------------------------------------------
%%% @author Fernando Benavides <fernando.benavides@inakanetworks.com>
%%% @copyright (C) 2010 InakaLabs S.R.L.
%%% @doc Supervisor for User Processes
%%% @end
%%%-------------------------------------------------------------------
-module(match_stream_user_sup).

-include("match_stream.hrl").
-define(MANAGERS, 400). %%NOTE: To reduce message_queue_lens on massive user initialization

-behaviour(supervisor).

-export([start_link/0, start_user/1, init/1]).

%% ====================================================================
%% External functions
%% ====================================================================
%% @doc  Starts the supervisor process
-spec start_link() -> ignore | {error, term()} | {ok, pid()}.
start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% @doc  Starts a new client process
-spec start_user(match_stream:user_id()) -> {ok, pid()} | {error, term()}.
start_user(User) ->
  Manager =
    list_to_atom("match-stream-user-manager-" ++ integer_to_list(random:uniform(?MANAGERS))),
  supervisor:start_child(Manager, [User]).

%% ====================================================================
%% Server functions
%% ====================================================================
%% @hidden
-spec init([]) -> {ok, {{one_for_one, 5, 10}, [supervisor:child_spec()]}}.
init([]) ->
  ?INFO("User supervisor initialized~n", []),
  _ = random:seed(erlang:now()),
  Managers =
    [{list_to_atom("match-stream-user-manager-" ++ integer_to_list(I)),
      {match_stream_user_mgr, start_link,
       [list_to_atom("match-stream-user-manager-" ++ integer_to_list(I))]},
      permanent, brutal_kill, supervisor, [match_stream_user_mgr]}
     || I <- lists:seq(1, ?MANAGERS)],
  {ok, {{one_for_one, 5, 10}, Managers}}.