%%%-------------------------------------------------------------------
%%% @author XKLEST
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 7월 2016 19:15
%%%-------------------------------------------------------------------
-module(mytcg_reloader).
-author("XKLEST").
-include_lib("kernel/include/file.hrl").
%% API
-export([start/0, loop/1, reload/1]).

start()->
  Pid = spawn(mytcg_reloader, loop, [erlang:localtime()]),
  timer:send_interval(timer:seconds(1), Pid, check).

loop(From)->
  receive
    check->
      To = erlang:localtime(),
      [check(From, To, Module, Filename)
        || {Module, Filename} <- code:all_loaded(), is_list(Filename)],
      loop(To);
    update->
      ?MODULE:loop(From);
    Other->
      io:format("~p~n", [Other]),
      loop(From)
end.

check(From, To, Module, Filename)->
  case file:read_file_info(Filename) of
    {ok, #file_info{mtime = MTime}} when MTime >= From, MTime < To ->
      reload(Module);
  _->
    pass
end.

reload(Module)->
  io:format("Reloading ~p ...", [Module]),
  code:purge(Module),
  code:load_file(Module),
  io:format("ok ~n").

