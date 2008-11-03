


import tango.text.convert.Integer;
import tango.text.Util;
import tango.io.Stdout;
import tango.net.Socket;

import tango.net.ServerSocket;
import tango.net.SocketConduit;

import tango.text.Regex;
import tango.time.chrono.Gregorian;
import tango.time.WallClock;
import tango.time.Clock;

import native_rest_cannon;


public class Server {
	private static bool _has_rendered = false;
	private static Request _request = null;
	private static Socket _client_socket = null;
	private static char[][char[]] _sessions;
	private static char[][char[]] _cookies;

	private static char[][ushort] status_code;
	private static char[][char[]] cookie_escape_map;

	public static this() {
		status_code[100] = "Continue";
		status_code[101] = "Switching Protocols";
		status_code[200] = "OK";
		status_code[201] = "Created";
		status_code[202] = "Accepted";
		status_code[203] = "Non-Authoritative Information";
		status_code[204] = "No Content";
		status_code[205] = "Reset Content";
		status_code[206] = "Partial Content";
		status_code[300] = "Multiple Choices";
		status_code[301] = "Moved Permanently";
		status_code[302] = "Found";
		status_code[303] = "See Other";
		status_code[304] = "Not Modified";
		status_code[305] = "Use Proxy";
		status_code[307] = "Temporary Redirect";
		status_code[400] = "Bad Request";
		status_code[401] = "Unauthorized";
		status_code[402] = "Payment Required";
		status_code[403] = "Forbidden";
		status_code[404] = "Not Found";
		status_code[405] = "Method Not Allowed";
		status_code[406] = "Not Acceptable";
		status_code[407] = "Proxy Authentication Required";
		status_code[408] = "Request Time-out";
		status_code[409] = "Conflict";
		status_code[410] = "Gone";
		status_code[411] = "Length Required";
		status_code[412] = "Precondition Failed";
		status_code[413] = "Request Entity Too Large";
		status_code[414] = "Request-URI Too Large";
		status_code[415] = "Unsupported Media Type";
		status_code[416] = "Requested range not satisfiable";
		status_code[417] = "Expectation Failed";
		status_code[500] = "Internal Server Error";
		status_code[501] = "Not Implemented";
		status_code[502] = "Bad Gateway";
		status_code[503] = "Service Unavailable";
		status_code[504] = "Gateway Time-out";
		status_code[505] = "HTTP Version not supported";

		cookie_escape_map[";"] = "%3B";
		cookie_escape_map[" "] = "+";
		cookie_escape_map["\n"] = "%0A";
		cookie_escape_map["\r"] = "%0D";
		cookie_escape_map["\t"] = "%09";
		cookie_escape_map["="] = "%3D";
		cookie_escape_map["+"] = "%2B";
	}

	public static char[] get_verbose_status_code(ushort code) {
		return tango.text.convert.Integer.toString(code) ~ " " ~ status_code[code];
	}

	public static char[] escape_cookie_value(char[] value) {
		foreach(char[] before, char[] after ; cookie_escape_map) {
			value = tango.text.Util.substitute(value, before, after);
		}

		return value;
	}

	public static char[] unescape_cookie_value(char[] value) {
		foreach(char[] before, char[] after ; cookie_escape_map) {
			value = tango.text.Util.substitute(value, after, before);
		}

		return value;
	}

	public static void render_text(char[] text) {
		// If we have already rendered, show an error
		if(_has_rendered) {
			throw new Exception("This action has already rendered.");
		}

		char[] status = get_verbose_status_code(200);

		// If there is no session add one to the cookies
		char[] set_cookies = "";
		if(("_appname_session" in _cookies) != null) {
			_cookies["_appname_session"] = "BAh7BzoMY3NyZl9pZCIlOWQ0Njc5ODIyNWM5MWZhNGU4OTY4NjczNmEwMTlh%0ANjAiCmZsYXNoSUM6J0FjdGlvbkNvbnRyb2xsZXI6OkZsYXNoOjpGbGFzaEhh%0Ac2h7AAY6CkB1c2VkewA%3D--eb5d809fcaceee78af495aa7544242ba4415a072; path=/";
		}

		// Get all the new cookie values to send
		// FIXME: This is sending all cookies. It should only send the ones that have changed
		foreach(char[] name, char[] value ; _cookies) {
			set_cookies ~= "Set-Cookie: " ~ name ~ "=" ~ escape_cookie_value(value) ~ "\r\n";
		}

		// Add the HTTP headers
		auto now = WallClock.now;
		auto time = now.time;
		auto date = Gregorian.generic.toDate(now);
		char[][] reply = [
		"HTTP/1.1 ", status, "\r\n", 
		"Date: ", tango.text.convert.Integer.toString(date.day), tango.text.convert.Integer.toString(date.month), tango.text.convert.Integer.toString(date.year), "\r\n", 
		"Server: Rail Cannon Server 0.0\r\n", 
		set_cookies, 
		"Status: ", status, "\r\n",
		//"X-Runtime: 0.15560\r\n",
		//"ETag: \"53e91025a55dfb0b652da97df0e96e4d\"\r\n",
		//"Cache-Control: private, max-age=0, must-revalidate\r\n",
		"Content-Type: text/html; charset=utf-8\r\n",
		"Content-Length: ", tango.text.convert.Integer.toString(text.length), "\r\n",
		//"Vary: User-Agent\r\n",
		"\r\n",
		text];

		_client_socket.send(tango.text.Util.join(reply, ""));
	}

	public static void start(void function(Request request, void function(char[]) render_text) run_action) {
		const int MAX_CONNECTIONS = 100;
		ushort port = 2345;
		Socket server = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
		server.blocking = false;
		server.bind(new InternetAddress(port));
		server.listen(MAX_CONNECTIONS);
		// FIXME: Isn't this socket_set doing the same thing as the client_sockets array? Is it needed?
		SocketSet socket_set = new SocketSet(MAX_CONNECTIONS + 1);
		Socket[] client_sockets;

		Stdout.format("Running on port {}.\n", port).flush;

		while(true) {
			// Get a  socket set to hold all the client sockets while they wait to be processed
			socket_set.reset();
			socket_set.add(server);
			foreach(Socket each; client_sockets) {
				socket_set.add(each);
			}
			Socket.select(socket_set, null, null);

			// Reply to clients
			int read = 0;
			for(int i=0; i<client_sockets.length; i++) {
				if(socket_set.isSet(client_sockets[i]) == false) {
					continue;
				}

				char[1024] buffer;
				read = client_sockets[i].receive(buffer);

				if(Socket.ERROR == read) {
					Stdout("Connection error.\n").flush;
				} else if(0 == read) {
					try {
						//if the connection closed due to an error, remoteAddress() could fail
						Stdout.format("Connection from {} closed.\n", client_sockets[i].remoteAddress());
					} catch {
						Stdout("Connection from unknown closed.\n");
					}
				} else {
//					Stdout.format("Received from {}: \n\"{}\"\n", client_sockets[i].remoteAddress(), buffer[0 .. read]).flush;

					// Get the request
					char[][] request = tango.text.Util.splitLines(buffer[0 .. read]);

					// Get the header
					char[][] header = tango.text.Util.split(request[0], " ");
					//"OPTIONS"                ; Section 9.2
                    //"GET"                    ; Section 9.3
                    //"HEAD"                   ; Section 9.4
                    //"POST"                   ; Section 9.5
                    //"PUT"                    ; Section 9.6
                    //"DELETE"                 ; Section 9.7
                    //"TRACE"                  ; Section 9.8
                    //"CONNECT"                ; Section 9.9
					char[] method = header[0];
					char[] uri = header[1];
					char[] http_version = header[2];

					// Get all the fields
					char[][char[]] fields;
					foreach(char[] line ; request) {
						// Break if we are at the end of the fields
						if(line.length == 0) break;

						char[][] pair = tango.text.Util.split(line, ": ");
						if(pair.length == 2) {
							fields[pair[0]] = pair[1];
						}
					}

					// Get the cookies
					if(("Cookie" in fields) != null) {
						foreach(char[] cookie ; tango.text.Util.split(fields["Cookie"], "; ")) {
							char[][] pair = tango.text.Util.split(cookie, "=");
							if(pair.length != 2) {
								Stdout.format("Malformed cookie: {}", cookie).flush;
							} else {
								_cookies[pair[0]] = unescape_cookie_value(pair[1]);
							}
						}
					}

					// Get the params
					char[][char[]] params;
					if(tango.text.Util.contains(uri, '?')) {
						foreach(char[] param ; tango.text.Util.split(tango.text.Util.split(uri, "?")[1], "&")) {
							char[][] pair = tango.text.Util.split(param, "=");
							params[pair[0]] = pair[1];
						}
					}

					// Get the controller and action
					char[][] route = tango.text.Util.split(tango.text.Util.split(uri, "?")[0], "/");
					char[] controller = route.length > 1 ? route[1] : null;
					char[] action = route.length > 2 ? route[2] : "index";
					char[] id = route.length > 3 ? route[3] : null;
					if(id != null) params["id"] = id;

					// Assemble the request object
					_has_rendered = false;
					_client_socket = client_sockets[i];
					_request = new Request(method, uri, http_version, controller, action, params, _cookies);

					// Run the action
					run_action(_request, &render_text);

					// FIXME: this prints out all the values we care about
					/*
					Stdout.format("Total params: {}\n", params.length).flush;
					foreach(char[] name, char[] value ; params) {
						Stdout.format("\t{} => {}\n", name, value).flush;
					}

					Stdout.format("Total cookies: {}\n", _cookies.length).flush;
					foreach(char[] name, char[] value ; _cookies) {
						Stdout.format("\t{} => {}\n", name, value).flush;
					}

					Stdout("Route :\n").flush;
					Stdout.format("\tController Name: {}\n", controller).flush;
					Stdout.format("\tAction Name: {}\n", action).flush;
					*/
				}

				// Remove this client from the socket set
				client_sockets[i].shutdown(SocketShutdown.BOTH);
				client_sockets[i].detach();
				if(i != client_sockets.length - 1)
					client_sockets[i] = client_sockets[client_sockets.length - 1];
				client_sockets = client_sockets[0 .. client_sockets.length - 1];
			}

//			if(client_sockets.length > 0) {
//				Stdout.format("\tTotal connections: {}\n", client_sockets.length).flush;
//			}

			// Accept client requests
			if(socket_set.isSet(server)) {
				Socket pending_client;
				try {
					if(client_sockets.length < MAX_CONNECTIONS) {
						pending_client = server.accept();
//						Stdout.format("Connection from {} established.\n", pending_client.remoteAddress()).flush;
//						assert(pending_client.isAlive);
//						assert(server.isAlive);
				
						client_sockets ~= pending_client;
					} else {
						pending_client = server.accept();
//						Stdout.format("Rejected connection from {}. Too many connections.\n", pending_client.remoteAddress()).flush;
//						assert(pending_client.isAlive);

						pending_client.send("503: Service Unavailable - Too many requests in the queue.");
						pending_client.shutdown(SocketShutdown.BOTH);
						pending_client.detach();
//						assert(!pending_client.isAlive);
//						assert(server.isAlive);
					}
				} catch(Exception e) {
					Stdout.format("Error accepting: {}\n", e).flush;
			
					if(pending_client && pending_client.isAlive) {
						pending_client.shutdown(SocketShutdown.BOTH);
						pending_client.detach();
					}
				}
			}
		}

		return 0;
	}
}


