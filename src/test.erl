-module(test).
-export([ping/3, check/3, test/3]).

ping(SessionID, _Env, _Input)->
    mod_esi:deliver(SessionID,
        ["Content-Type: text/html\r\n\r\n test pong"]).

test(SessionID, Env, Input) ->
    mod_esi:deliver(SessionID,
        [ io_lib:format("Content-Type: text/html\r\n\r\n <b>Env:</b><br /> ~w <hr /> <b>Input:</b> <br /> ~w" , [Env, Input]) ]).

check(SessionID, Env, _Input) ->
    mod_esi:deliver(SessionID,
        ["Content-Type: text/html\r\n\r\n" | format(Env)]).

format([]) ->
    "";
format([{Key, Value} | Env]) ->
    [io_lib:format("<b>~p:</b> ~p<br />\~n", [Key, Value]) | format(Env)].