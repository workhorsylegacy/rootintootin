

-module(que_server).
-compile(export_all).


start() ->
	{ok, Listen} = gen_tcp:listen(2345, [list, {packet, line},
										 {reuseaddr, true},
										 {active, true}]),
	spawn(fun() -> accept_connect(Listen) end).

accept_connect(Listen) ->
	{ok, Socket} = gen_tcp:accept(Listen),
	spawn(fun() -> accept_connect(Listen) end),
	io:format("Client connected~n"),
	process_request(Socket).

process_request(Socket) ->
	receive
		{tcp, Socket, Request} ->
			gen_tcp:send(Socket, "<h1>pees</h1>"),
			gen_tcp:close(Socket);
		{tcp_closed, Socket} ->
			io:format("Client disconnected~n")
	end.

