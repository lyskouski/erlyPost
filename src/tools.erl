-module(tools).
-export([parseParam/1, json_encode/1, setData/2, getData/1, delData/1]).

%% Parse parameters from string to erlang construction
% @param string Input
% @return list
parseParam(Input) ->
    Params = string:tokens(decode(Input), "/?&="),
    convert(Params).

decode(Value)->
    unicode:characters_to_list(erlang:list_to_binary(Value)).

convertToNumber(L) ->
    Float = (catch erlang:list_to_float(L)),
    Int = (catch erlang:list_to_integer(L)),
    if
        is_number(Int) ->
            erlang:list_to_integer(L);
        is_number(Float) ->
            erlang:list_to_float(L);
        true ->
            false
    end.

convert([])->
     [];
convert([Key,Value|Part])->
    Atom = erlang:list_to_atom(Key),
    Convert = convertToNumber(Value),
    Output = if
        Atom =:= login ->
            erlang:list_to_atom(Value);
        Convert =/= false ->
            Convert;
        true ->
            erlang:iolist_to_binary(Value)
    end,
    [ {Atom, Output} | convert(Part) ].

%% Convert erlang construction to JSON
% @param list Tuple
% @return string
json_encode(Tuple)->
    "{" ++ join( json_encode_loop(Tuple), "," ) ++ "}".

join([First|Rest],JoinWith) ->
   lists:flatten( [First] ++ [ JoinWith ++ X || X <- Rest] ).

json_encode_loop([])->[];
json_encode_loop([{Key,Value}|List])->
    Convert = convertToNumber(Value),
    Sense = if
        erlang:is_atom(Value) ->
            [["\"" | erlang:atom_to_list(Value)] | "\""];
        erlang:is_binary(Value) ->
            [["\"" | erlang:binary_to_list(Value)] | "\""];
        Convert =/= false ->
            io_lib:format("~w", [Value]);
        Value =:= false ->
            "false";
        Value =:= true ->
            "true";
        true ->
            [["\"" | Value] | "\""]
    end,
    [ ["\"", erlang:atom_to_list(Key), "\":", Sense] | json_encode_loop(List) ].

%% Save data into memcache
setData( Key, Params )->
    memcacheWorker(set, Key, Params).

%% Get data from memcache
getData( Key )->
    memcacheWorker(get, Key).

%% Delete data from memcache
delData( Key )->
    memcacheWorker(delete, Key).


memcacheWorker( Type, Key )->
    memcacheWorker( Type, 0, Key, false, null ).

memcacheWorker( Type, Key, Params )->
    memcacheWorker( Type, 0, Key, Params, null ).

memcacheWorker( Type, Tried, Key, Value, PrevError )->
    %timer:exit_after(1, 'timeout'),
    if Tried > 100 ->
            PrevError;
        true ->
            case mcd:Type(myMcd, Key) of
                {ok, Data} ->
                    Data;
                {error, noproc} ->
                    case mcd:start_link(myMcd, []) of
                        {error, Error} ->
                            Stop = gen_server:cast(mcd, stop),
                            io:format("Stop server mcd ~w ~w ~n", [Error, Stop]);
                        {ok, _} ->
                            true,
                            io:format("Reconnect to server mcd ~n")
                    end,
                    memcacheWorker( Type, Tried + 1, Key, Value, noproc );
                {error, noconn}->
                    %timer:sleep(Tried),
                    memcacheWorker( Type, Tried + 1, Key, Value, noconn );
                {_, Error} ->
                    Error
            end
    end.