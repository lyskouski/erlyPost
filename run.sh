#!/bin/sh

kill -9 `ps aux | grep beam.smp | grep -v grep | awk '{print($2)}'`

#erlc -Wall *.erl
cd ./include && erl -make && cd ../src && erl -make && cd ../

## localy:linux
# erl -pa ./ebin ./include/ebin -detached -noshell -config run -s inets

## locally:windows
# erl -pa ./ebin ./include/ebin -config run
# > application:start(inets).

## erl +fna +pc unicode -pa ./ebin ./include/ebin -detached -noshell -config run -s inets
erl -pa ./ebin ./include/ebin -detached -noshell -config run -s inets
# -heart  <= restore after fail