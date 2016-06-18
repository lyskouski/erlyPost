-module(index).
-export([ping/3, action/3, response/3]).

ping(SessionID, _Env, _Input)->
    mod_esi:deliver(SessionID,
        ["Content-Type: text/html\r\n\r\n index pong"]).

action(SessionID, Env, Input) ->
    Path = tools:parseParam([Value || {path_info, Value} <- Env]),
    Method = [Value || {request_method, Value} <- Env],
    {Status, Answer} = case Method of
        ["GET"]    -> getAction(Path ++ tools:parseParam([Value || {query_string, Value} <- Env]));
        ["POST"]   -> postAction( Path, tools:parseParam(Input) );
        ["PUT"]    -> putAction( Path, tools:parseParam(Input) );
        ["DELETE"] -> deleteAction( Path );
        [ Other ] -> missingAction( Other )
    end,
    Type = if
        Method =:= ["GET"] -> "text/html";
        true -> "application/json"
    end,
    response(SessionID, [{status, Status},{type, Type}], Answer).

getAction( Query ) ->
    {ok, [ "Hello getAction!<br />Query: ", io_lib:format("~w", [Query]) ]}.

postAction( Path, Input ) ->
    {ok, [ "{'message': 'Hello postAction!',", "'values': '", io_lib:format("Path: ~w ; Input: ~w", [Path, Input]), "'}" ]}.

putAction( Path, Input ) ->
    Input, Path,
    {ok, "{'message': 'Hello putAction!'}"}.

deleteAction( Path ) ->
    Path,
    {ok, "{'message': 'Hello deleteAction!'}"}.

missingAction( Method ) ->
    {missing, ["Request method ", Method, " is not supported"]}.


%% Provide response with headers and content
% @param pid SessionID - user session
% @param list Headers
% @param string Text
response(SessionID, Headers, Text) ->
    case [ Value || {status, Value} <- Headers] of
        [] -> HeaderList = [{status, ok} | Headers];
        _ -> HeaderList = Headers
    end,
    mod_esi:deliver(SessionID, lists:flatten([responseHeaders(HeaderList), "\r\n"]) ),
    mod_esi:deliver( SessionID, Text ).

responseHeaders([]) -> [];
responseHeaders([{Type, Value}|Rest]) ->
    case Type of
        status ->
            {Code, Phrase} = headerText(Value),
            Header = ["Status: ", Code, Phrase];
        type   ->
            Header = ["Content-Type: ", Value ];
        title ->
            Header = ["Title:", Value];
        _ ->
            Header = ""
    end,
    lists:flatten([ Header , "\r\n" , responseHeaders(Rest) ]).

headerText(Key) ->
    case Key of
        ok -> {"200", " OK"};
        new -> {"201", " Created"};
        accepted -> {"202", " Accepted"};
        redirect -> {"301", " Moved Permanently"};
        found -> {"302", " Found"};
        locked -> {"403", " Forbidden"};
        missing -> {"404", " Not Found"};
        nok -> {"406", " Not Acceptable"};
        del -> {"410", " Gone"};
        critical -> {"500", " Internal Server Error"};
        comming -> {"501", " Not Implemented"};
        _ -> {"500", " Internal Server Error (wrong response)"}
    end.