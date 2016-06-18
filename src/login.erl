-module(login).
-export([auth/3, ping/3]).

ping(SessionID, _Env, _Input)->
    mod_esi:deliver(SessionID,
        ["Content-Type: text/html\r\n\r\n login pong"]).

auth(SessionID, _Env, Input) ->
    % Result = tools:parseParam(Input),
    {Status, Result} = case tools:parseParam(Input) of
        % @todo check cookies
        [{cookie, Value}] ->
            {ok, [{message, Value}] };
        % @todo check auth
        [{login, Login},{pssw, Pssw}] ->
            {ok, [{message, [erlang:atom_to_list(Login), ", Current pssw: ", Pssw]}] };
        % @todo restore auth
        [{login, Login}] ->
            {accepted, [{message, [erlang:atom_to_list(Login), ", New password: send"]}] };
        % @todo restore auth
        [] ->
            {new, [{message, "New user registry"}] };
        % other cases
        _ ->
            {missing, [{message, io_lib:format("Missing statement ~w", [tools:parseParam(Input)])}] }
    end,
    index:response(SessionID, [{status, Status},{type, "application/json"}], tools:json_encode(Result)).