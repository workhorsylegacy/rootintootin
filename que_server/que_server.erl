-module(que_server).
-compile(export_all).

%% run in erl like this:
%% c(que_server).
%% que_server:start().

start() ->
	Body = "<h1>pees</h1>\r\n<h2>hat</h2>",
	Response = "HTTP/1.1 200 OK\r\n" ++ 
	"Server: Rester_0.1\r\n" ++ 
	"Status: 200 OK\r\n" ++ 
	"Content-Length: " ++ integer_to_list(length(Body)) ++ "\r\n\r\n" ++ 
	Body,
	{ok, Listen} = gen_tcp:listen(2345, [list, {packet, line},
										 {reuseaddr, true},
										 {active, true}]),
	spawn(fun() -> accept_connect(Listen, Response) end).

accept_connect(Listen, Response) ->
	{ok, Socket} = gen_tcp:accept(Listen),
	spawn(fun() -> accept_connect(Listen, Response) end),
	%%io:format("Client connected~n"),
	process_request(Socket, Response).

process_request(Socket, Response) ->
	receive
		{tcp, Socket, Request} ->
			gen_tcp:send(Socket, Response),
			gen_tcp:close(Socket)
	end.

