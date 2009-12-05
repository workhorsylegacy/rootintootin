.SUFFIXES: .erl .beam

.erl.beam:
	erlc -W $<

ERL = erl -smp enable -noshell -boot start_clean

MODS = que_server

server: compile
	${ERL} -s que_server start

compile: ${MODS:%=%.beam}

clean:
	rm -rf *.beam erl_crash.dump
