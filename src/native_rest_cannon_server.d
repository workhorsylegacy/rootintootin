


import tango.text.convert.Integer;
import tango.text.Util;
import tango.stdc.stringz;
import tango.io.device.File;
import tango.math.random.engines.Twister;

import tango.io.Stdout;
import tango.net.Socket;
import tango.net.ServerSocket;
import tango.net.SocketConduit;

import tango.text.Regex;
import tango.time.chrono.Gregorian;
import tango.time.WallClock;
import tango.time.Clock;

import language_helper;
import helper;
import db;
import native_rest_cannon;


public class Server {
	private bool _has_rendered = false;
	private Request _request = null;
	private Socket _client_socket = null;
	private int _session_id = 0;
	private char[][char[]] _sessions;
	private char[][char[]] _cookies;
	private char[] _salt;
	private RunnerBase _runner = null;

	public this() {
		// Get a random salt for salting sessions
		Twister* random = new Twister();
		random.seed(Clock.now.span.millis);
		this._salt = to_s(random.next());
		delete random;
	}

	public void redirect_to(char[] url) {
		// If we have already rendered, show an error
		if(_has_rendered) {
			throw new Exception("Something has already been rendered.");
		}

		char[] status = Helper.get_verbose_status_code(301);

		char[] header = "HTTP/1.1 " ~ status ~ "\r\n" ~
		"Location: " ~ url ~ "\r\n" ~
		"Content-Type: text/html\r\n" ~
		"Content-Length: 0" ~
		"\r\n";

		_client_socket.send(header);
	}

	public void render_text(char[] text, ushort status_code = cast(ushort)-1) {
		// If we have already rendered, show an error
		if(_has_rendered) {
			throw new Exception("Something has already been rendered.");
		}

		// Get the status code. Use 200 as default
		if(status_code == cast(ushort)-1)
			status_code = 200;
		char[] status = Helper.get_verbose_status_code(status_code);

		// If there is no session add one to the cookies
		char[] set_cookies = "";
		if(("_appname_session" in _cookies) == null || (_cookies["_appname_session"] in _sessions) == null) {
			char[] hashed_session_id = Helper.hash_and_base64(to_s(_session_id), _salt);
			_cookies["_appname_session"] = hashed_session_id; // ~ "; path=/";
			_sessions[hashed_session_id] = [];
			Stdout.format("\nCreated session number '{}' '{}'\n", _session_id, hashed_session_id).flush;
			_session_id++;
		} else {
			Stdout.format("Using existing session '{}'\n", _cookies["_appname_session"]).flush;
		}

		// Get all the new cookie values to send
		// FIXME: This is sending all cookies. It should only send the ones that have changed
		foreach(char[] name, char[] value ; _cookies) {
			set_cookies ~= "Set-Cookie: " ~ name ~ "=" ~ Helper.escape_value(value) ~ "\r\n";
		}

		// Add the HTTP headers
		auto now = WallClock.now;
		auto time = now.time;
		auto date = Gregorian.generic.toDate(now);
		char[][] reply = [
		"HTTP/1.1 ", status, "\r\n", 
		"Date: ", to_s(date.day), to_s(date.month), to_s(date.year), "\r\n", 
		"Server: Native_Rest_Cannon_0.1\r\n", 
		set_cookies, 
		"Status: ", status, "\r\n",
		//"X-Runtime: 0.15560\r\n",
		//"ETag: \"53e91025a55dfb0b652da97df0e96e4d\"\r\n",
		"Cache-Control: private, max-age=0\r\n",
		"Content-Type: text/html; charset=utf-8\r\n",
		"Content-Length: ", to_s(text.length), "\r\n",
		//"Vary: User-Agent\r\n",
		"\r\n",
		text];

		_client_socket.send(tango.text.Util.join(reply, ""));
	}

	public void start(ushort port, uint max_connections, 
						char[] buffer, uint header_max_size, 
						char[] db_host, char[] db_user, char[] db_password, char[] db_name, 
						RunnerBase runner) {

		this._runner = runner;

		// Connect to the database
		db_connect(db_host, db_user, db_password, db_name);

		// Create a socket that is non-blocking, can re-use dangling addresses, and can hold many connections.
		Socket server = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
		server.blocking = false;
		server.bind(new InternetAddress(port));
		uint[1] opt = 1;
		server.setOption(SocketOptionLevel.SOCKET, SocketOption.SO_REUSEADDR, opt);
		server.listen(max_connections);

		// FIXME: Isn't this socket_set doing the same thing as the client_sockets array? Is it needed?
		SocketSet socket_set = new SocketSet(max_connections + 1);
		Socket[] client_sockets;
		Stdout("Server running ...\n").flush;

		while(true) {
			// Get a socket set to hold all the client sockets while they wait to be processed
			socket_set.reset();
			socket_set.add(server);
			foreach(Socket each; client_sockets) {
				socket_set.add(each);
			}
			Socket.select(socket_set, null, null);

			// Reply to clients
			for(size_t i=0; i<client_sockets.length; i++) {
				if(socket_set.isSet(client_sockets[i]) == false) {
					continue;
				}

				// Save the current socket
				_has_rendered = false;
				foreach(char[] key ; _cookies.keys)
					_cookies.remove(key);
				_client_socket = client_sockets[i];

				try {
					this.process_request(buffer, header_max_size);
				} catch(Exception e) {
					char[] msg = "Error: file " ~ e.file ~ ", Line " ~ to_s(e.line) ~ ", msg '" ~ e.msg ~ "'";
					this.render_text(msg, 500);
				}

				// Remove this client from the socket set
				_client_socket.shutdown(SocketShutdown.BOTH);
				_client_socket.detach();
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
					if(client_sockets.length < max_connections) {
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

	private void process_request(char[] buffer, uint header_max_size) {
		// Get the http header
		int buffer_length = _client_socket.receive(buffer);
		//Stdout.format("GOT \"{}\": LENGTH: {}\n", buffer[0 .. buffer_length], buffer_length).flush;

		// Show an error if the header was bad
		if(Socket.ERROR == buffer_length) {
			Stdout("Connection error.\n").flush;
			return;
		} else if(0 == buffer_length) {
			try {
				//if the connection closed due to an error, remoteAddress() could fail
				Stdout.format("Connection from {} closed.\n", _client_socket.remoteAddress()).flush;
			} catch {
				Stdout("Connection from unknown closed.\n").flush;
			}
			return;
		}

		// Show an 'HTTP 413 Request Entity Too Large' if the end of the header was not read
		if(tango.text.Util.locatePattern(buffer[0 .. buffer_length], "\r\n\r\n", 0) == buffer_length) {
			this.render_text("The end of the HTTP header was not found when reading the first " ~ to_s(header_max_size) ~ " bytes.", 413);
			return;
		}

		// Clone the buffer segments into the raw header and body
		char[][] buffer_pair = ["", ""];
		int header_end = tango.text.Util.locatePattern(buffer[0 .. buffer_length], "\r\n\r\n", 0);
		buffer_pair[0] = buffer[0 .. buffer_length][0 .. header_end];
		buffer_pair[1] = buffer[0 .. buffer_length][header_end+4 .. length];

		char[] raw_header = "" ~ buffer_pair[0];

		// Get the header info
		char[][] header_lines = tango.text.Util.splitLines(raw_header);
		char[][] first_line = tango.text.Util.split(header_lines[0], " ");
		char[] method = first_line[0];
		char[] uri = first_line[1];
		char[] http_version = first_line[2];

		// Get the content length and body
		int content_length = 0;
		File body_file = null;

		if(method == "POST" || method == "PUT") {
			// Show an 'HTTP 411 Length Required' error if there is no Content-Length
			if(tango.text.Util.locatePattern(raw_header, "Content-Length: ", 0) == raw_header.length) {
				this.render_text("Content-Length is required for HTTP POST and PUT.", 411);
				return;
			}

			// Get the content length
			content_length = to_int(between(raw_header, "Content-Length: ", "\r\n"));

			// Write the request body into a file
			if(content_length > 0) {
				// Write any left-over body from when we read the header into the file
				int remaining_length = content_length;
				body_file = new File("raw_body", File.WriteCreate);
				if(buffer_pair.length == 2 && buffer_pair[1].length > 0) {
					remaining_length -= buffer_pair[1].length;
					body_file.output.write(buffer_pair[1]);
				}

				// Write the remaining body into the file
				while(remaining_length > 0) {
					// FIXME: check for errors after receive like above
					buffer_length = _client_socket.receive(buffer);
					if(buffer_length > 0) {
						body_file.output.write(buffer[0 .. buffer_length]);
					}
					remaining_length -= buffer_length;
				}
			}
		}

		//Stdout.format("GOT \"{}\": LENGTH: {}\n", raw_header, raw_header.length).flush;
		//Stdout.format("GOT \"{}\": LENGTH: {}\n", raw_body, raw_body.length).flush;

		// Get all the fields
		char[][char[]] fields;
		foreach(char[] line ; header_lines) {
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
					_cookies[pair[0]] = Helper.unescape_value(pair[1]);
				}
			}
		}

		// Make sure the session id is one we created
		if(("_appname_session" in _cookies) != null) {
			char[] hashed_session_id = _cookies["_appname_session"];
			if((hashed_session_id in _sessions) == null) {
				Stdout.format("Unknown session id '{}'\n", hashed_session_id).flush;
			}
		}

		// Get the HTTP GET params
		char[][char[]] params;
		if(tango.text.Util.contains(uri, '?')) {
			foreach(char[] param ; tango.text.Util.split(tango.text.Util.split(uri, "?")[1], "&")) {
				char[][] pair = tango.text.Util.split(param, "=");
				params[Helper.unescape_value(pair[0])] = Helper.unescape_value(pair[1]);
			}
		}

		// Get the params from a url encoded body
		// FIXME: This will put the whole post body into ram. It should put the params into a file
		if((method == "POST" || method == "PUT") && ("Content-Type" in fields) != null) {
			if(fields["Content-Type"] == "application/x-www-form-urlencoded") {
				File raw_body_file = new File("raw_body", File.ReadExisting);
				char[] raw_body = "";
				char[100] buf;
				int len = 0;
				while((len = raw_body_file.read(buf)) > 0) {
					raw_body ~= buf[0 .. len];
				}
				foreach(char[] param ; tango.text.Util.split(raw_body, "&")) {
					char[][] pair = tango.text.Util.split(param, "=");
					if(pair.length == 2) {
						params[Helper.unescape_value(pair[0])] = Helper.unescape_value(pair[1]);
					}
				}
			}
		}
/*
		// Get the file from a miltipart encoded body
		// FIXME: This will put the whole post body into ram. It should put the body into a file
		if((method == "POST" || method == "PUT") && ("Content-Type" in fields) != null) {
			char[] content_type = fields["Content-Type"];
			if(tango.text.Util.locatePattern(content_type, "multipart/form-data; boundary=", 0) == 0) {
				char[] boundary = tango.text.Util.split(content_type, "; boundary=")[1];
				Stdout.format("Boundary [[{}]]\n", boundary).flush;

				File raw_body_file = new File("raw_body", File.ReadExisting);
				char[] raw_body = "";
				char[100] buf;
				int len = 0;
				while((len = raw_body_file.read(buf)) > 0) {
					raw_body ~= buf[0 .. len];
				}

				// Add any params
				foreach(char[] part ; tango.text.Util.split(raw_body, boundary)) {
					if(tango.text.Util.locatePattern(part, "Content-Disposition: form-data; ", 0) == 0) {
						char[] data = between("Content-Disposition: form-data; ", "\r\n");
						foreach(char[] variable ; tango.text.Util.split(data, "; ")) {
							char[] pair = tango.text.Util.split(variable, "=");
							if(pair[0] == "name")
								params[pair[1]] = pair[1];
						}
					}
				}
				//char[] meta = tango.text.Util.split(parts[1], "\r\n\r\n")[0];
				//char[] file = tango.text.Util.split(parts[1], "\r\n\r\n")[1][0 .. length-2];
			}
		}
*/
		// Get the controller and action
		char[][] route = tango.text.Util.split(tango.text.Util.split(uri, "?")[0], "/");
		char[] controller = route.length > 1 ? route[1] : null;
		char[] action = route.length > 2 ? route[2] : "index";
		char[] id = route.length > 3 ? route[3] : null;
		if(id != null) params["id"] = id;

		// Assemble the request object
		_request = new Request(method, uri, http_version, controller, action, params, _cookies);

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
		*/

		// Run the action
		char[] response = null;
		try {
			response = _runner.run_action(_request);
			if(response != null) {
				this.render_text(response);
			}
		} catch(RedirectToException e) {
			this.redirect_to(e.url);
		} catch(RenderViewException e) {
			response = _runner.render_view(_request.controller, e.view_name);
			this.render_text(response, 200);
		}

		Stdout("Route :\n").flush;
		Stdout.format("\tController Name: {}\n", controller).flush;
		Stdout.format("\tAction Name: {}\n", action).flush;
		Stdout.format("\tID: {}\n", id).flush;
		//*/
	}
}


