

import std.stdio;
import std.socket;
import std.regexp;

import rail_cannon;


public class Request {
	private string _method;
	private string _uri;
	private string _http_version;
	private string _controller;
	private string _action;
	private string[string] _params;

	public this(string method, string uri, string http_version, string controller, string action, string[string] params) {
		_method = method;
		_uri = uri;
		_http_version = http_version;
		_controller = controller;
		if(action == "new") {
			_action = "New";
		} else {
			_action = action;
		}
		_params = params;
	}

	public string method() { return _method; }
	public string uri() { return _uri; }
	public string http_version() { return _http_version; }
	public string controller() { return _controller; }
	public string action() { return _action; }
	public string[string] params() { return _params; }
}

public class Server {
	private static bool _has_rendered = false;
	private static Request _request = null;
	private static Socket _client_socket = null;

	public static void render_text(string text) {
		// If we have already rendered, show an error
		if(_has_rendered) {
			throw new Exception("This action has already rendered.");
		}

		// Add the HTTP headers
		string[] reply = [
		"HTTP/1.1 200 OK\r\n", 
		"Date: Mon, 13 Oct 2008 04:05:25 GMT\r\n", 
		"Server: Rail Cannon Server0.0\r\n", 
		"Set-Cookie: _appname_session=BAh7BzoMY3NyZl9pZCIlOWQ0Njc5ODIyNWM5MWZhNGU4OTY4NjczNmEwMTlh%0ANjAiCmZsYXNoSUM6J0FjdGlvbkNvbnRyb2xsZXI6OkZsYXNoOjpGbGFzaEhh%0Ac2h7AAY6CkB1c2VkewA%3D--eb5d809fcaceee78af495aa7544242ba4415a072; path=/\r\n",
		"Status: 200 OK\r\n",
		"X-Runtime: 0.15560\r\n",
		"ETag: \"53e91025a55dfb0b652da97df0e96e4d\"\r\n",
		"Cache-Control: private, max-age=0, must-revalidate\r\n",
		"Content-Type: text/html; charset=utf-8\r\n",
		"Content-Length: ", std.string.toString(text.length), "\r\n",
		"Vary: User-Agent\r\n",
		"\r\n",
		text];

		_client_socket.send(std.string.join(reply, ""));
	}

	public static void start(void function(Request request, void function(string) render_text) run_action) {
		/*
		 respStatus.Add(200, "200 Ok");
		 respStatus.Add(201, "201 Created");
		 respStatus.Add(202, "202 Accepted");
		 respStatus.Add(204, "204 No Content");

		 respStatus.Add(301, "301 Moved Permanently");
		 respStatus.Add(302, "302 Redirection");
		 respStatus.Add(304, "304 Not Modified");
		 
		 respStatus.Add(400, "400 Bad Request");
		 respStatus.Add(401, "401 Unauthorized");
		 respStatus.Add(403, "403 Forbidden");
		 respStatus.Add(404, "404 Not Found");

		 respStatus.Add(500, "500 Internal Server Error");
		 respStatus.Add(501, "501 Not Implemented");
		 respStatus.Add(502, "502 Bad Gateway");
		 respStatus.Add(503, "503 Service Unavailable");

		*/
		const int MAX_CONNECTIONS = 100;
		ushort port = 2345;
		TcpSocket listener = new TcpSocket();
		listener.blocking = false;
		listener.bind(new InternetAddress(port));
		listener.listen(MAX_CONNECTIONS);
		SocketSet sset = new SocketSet(MAX_CONNECTIONS + 1);
		Socket[] reads;

		printf("Running on port %i.\n", port);

		while(true) {
			sset.reset();
			sset.add(listener);
			foreach(Socket each; reads) {
				sset.add(each);
			}
			Socket.select(sset, null, null);

			int read = 0;
			for(int i=0; i<reads.length; i++) {
				if(sset.isSet(reads[i]) == false) {
					continue;
				}

				char[1024] buffer;
				read = reads[i].receive(buffer);

				if(Socket.ERROR == read) {
					printf("Connection error.\n");
				} else if(0 == read) {
					try {
						//if the connection closed due to an error, remoteAddress() could fail
						printf("Connection from %.*s closed.\n", reads[i].remoteAddress().toString());
					} catch {
					}
				} else {
					printf("Received %d bytes from %.*s: \n\"%.*s\"\n", read, reads[i].remoteAddress().toString(), buffer[0 .. read]);

					// Get the request
					string[] request = std.string.splitlines(buffer[0 .. read]);

					// Get the header
					string[] header = std.string.split(request[0]);
					//"OPTIONS"                ; Section 9.2
                    //"GET"                    ; Section 9.3
                    //"HEAD"                   ; Section 9.4
                    //"POST"                   ; Section 9.5
                    //"PUT"                    ; Section 9.6
                    //"DELETE"                 ; Section 9.7
                    //"TRACE"                  ; Section 9.8
                    //"CONNECT"                ; Section 9.9
					string method = header[0];
					string uri = header[1];
					string http_version = header[2];

					// Get all the fields
					string[string] fields;
					foreach(string line ; request) {
						if(auto match = std.regexp.search(line, ": ")) {
							fields[match.pre] = match.post;
						}
						/*
						switch(reg.pre) {
							case "Host"            : stuff["Host"]            = reg.post; break;
							case "User-Agent"      : stuff["User-Agent"]      = reg.post; break;
							case "Accept"          : stuff["Accept"]          = reg.post; break;
							case "Accept-Language" : stuff["Accept-Language"] = reg.post; break;
							case "Accept-Encoding" : stuff["Accept-Encoding"] = reg.post; break;
							case "Accept-Charset"  : stuff["Accept-Charset"]  = reg.post; break;
							case "Keep-Alive"      : stuff["Keep-Alive"]      = reg.post; break;
							case "Connection"      : stuff["Connection"]      = reg.post; break;
							case "Cookie"          : stuff["Cookie"]          = reg.post; break;
						}
						*/
					}

					// get the params
					string[string] params;
					if(std.regexp.search(uri, "[?]")) {
						foreach(string param ; std.string.split(std.string.split(uri, "?")[1], "&")) {
							string[] pair = std.string.split(param, "=");
							params[pair[0]] = pair[1];
						}
					}

					// get the controller and action
					string[] route = std.string.split(std.string.split(uri, "[?]")[0], "/");
					string controller = route.length > 1 ? route[1] : null;
					string action = route.length > 2 ? route[2] : "index";
					string id = route.length > 3 ? route[3] : null;
					params["id"] = id;

					// Assemble the request object
					_has_rendered = false;
					_client_socket = reads[i];
					_request = new Request(method, uri, http_version, controller, action, params);

					// Run the action
					run_action(_request, &render_text);
				}

				//remove from reads
				reads[i].close();
				if(i != reads.length - 1)
					reads[i] = reads[reads.length - 1];
				reads = reads[0 .. reads.length - 1];
				printf("\tTotal connections: %d\n", reads.length);
			}


			//connection request
			if(sset.isSet(listener)) {
				Socket sn;
				try {
					if(reads.length < MAX_CONNECTIONS) {
						sn = listener.accept();
						printf("Connection from %.*s established.\n", sn.remoteAddress().toString());
						assert(sn.isAlive);
						assert(listener.isAlive);
				
						reads ~= sn;
						printf("\tTotal connections: %d\n", reads.length);
					} else {
						sn = listener.accept();
						printf("Rejected connection from %.*s; too many connections.\n", sn.remoteAddress().toString());
						assert(sn.isAlive);
				
						sn.close();
						assert(!sn.isAlive);
						assert(listener.isAlive);
					}
				} catch(Exception e) {
					printf("Error accepting: %.*s\n", e.toString());
			
					if(sn)
						sn.close();
				}
			}
		}

		return 0;
	}
}


