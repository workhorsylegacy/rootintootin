

import std.stdio;
import std.socket;
import std.regexp;
import std.date;

import rail_cannon;


public class Server {
	private static bool _has_rendered = false;
	private static Request _request = null;
	private static Socket _client_socket = null;
	private static string[string] _sessions;
	private static string[string] _cookies;

	private static string[ushort] status_code;
	private static string[string] cookie_escape_map;

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

	public static string get_verbose_status_code(ushort code) {
		return std.string.toString(code) ~ " " ~ status_code[code];
	}

	public static string escape_cookie_value(string value) {
		foreach(string before, string after ; cookie_escape_map) {
			value = std.string.replace(value, before, after);
		}

		return value;
	}

	public static string unescape_cookie_value(string value) {
		foreach(string before, string after ; cookie_escape_map) {
			value = std.string.replace(value, after, before);
		}

		return value;
	}

	public static void render_text(string text) {
		// If we have already rendered, show an error
		if(_has_rendered) {
			throw new Exception("This action has already rendered.");
		}

		string status = get_verbose_status_code(200);

		// FIXME: if there is no session add one to the cookies
		string set_cookies = "";
		//set_cookies ~= "Set-Cookie: " ~ "_appname_session=" ~ "BAh7BzoMY3NyZl9pZCIlOWQ0Njc5ODIyNWM5MWZhNGU4OTY4NjczNmEwMTlh%0ANjAiCmZsYXNoSUM6J0FjdGlvbkNvbnRyb2xsZXI6OkZsYXNoOjpGbGFzaEhh%0Ac2h7AAY6CkB1c2VkewA%3D--eb5d809fcaceee78af495aa7544242ba4415a072; path=/\r\n";

		// Get all the new cookie values to send
		foreach(string name, string value ; _cookies) {
			set_cookies ~= "Set-Cookie: " ~ name ~ "=" ~ escape_cookie_value(value) ~ "\r\n";
		}

		// Add the HTTP headers
		string[] reply = [
		"HTTP/1.1 ", status, "\r\n", 
		"Date: ", std.date.toUTCString(std.date.getUTCtime()), "\r\n", 
		"Server: Rail Cannon Server 0.0\r\n", 
		set_cookies, 
		"Status: ", status, "\r\n",
		//"X-Runtime: 0.15560\r\n",
		//"ETag: \"53e91025a55dfb0b652da97df0e96e4d\"\r\n",
		//"Cache-Control: private, max-age=0, must-revalidate\r\n",
		"Content-Type: text/html; charset=utf-8\r\n",
		"Content-Length: ", std.string.toString(text.length), "\r\n",
		//"Vary: User-Agent\r\n",
		"\r\n",
		text];

		_client_socket.send(std.string.join(reply, ""));
	}

	public static void start(void function(Request request, void function(string) render_text) run_action) {
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

					// get the cookies
					if(("Cookie" in fields) != null) {
						foreach(string cookie ; std.string.split(fields["Cookie"], "; ")) {
							string[] pair = std.string.split(cookie, "=");
							if(pair.length != 2) {
								writefln("Malformed cookie: %s", cookie);
							} else {
								_cookies[pair[0]] = unescape_cookie_value(pair[1]);
							}
						}
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
					_request = new Request(method, uri, http_version, controller, action, params, _cookies);

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


