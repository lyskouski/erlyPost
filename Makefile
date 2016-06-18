all:
    (cd include && erl -make && cd ../src && erl -make && cd ../)

test:
    (cd test && erl -make && \
       erl -noinput -eval 'eunit:test({dir, "."}, [verbose]), init:stop()')