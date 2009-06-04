


import tango.io.digest.Digest;
import tango.io.digest.Sha0;
import tango.io.encode.Base64;

import tango.text.convert.Integer;
import tango.text.Util;
import tango.stdc.stringz;

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

	public void render_text(char[] text) {
		// If we have already rendered, show an error
		if(_has_rendered) {
			throw new Exception("Something has already been rendered.");
		}

		char[] status = Helper.get_verbose_status_code(200);

		// If there is no session add one to the cookies
		// FIXME: Session ids are not yet salted, so they can easily be looked up in a rainbow table or googled
		char[] set_cookies = "";
		if(("_appname_session" in _cookies) == null || (_cookies["_appname_session"] in _sessions) == null) {
			char[] hashed_session_id = Helper.hash_and_base64(to_s(_session_id));
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

	public void start(ushort port, int max_connections, 
						char[] db_host, char[] db_user, char[] db_password, char[] db_name, 
						void function(Request request, Server server) run_action) {

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

				this.process_request(client_sockets[i], run_action);

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

	private void process_request(Socket client_socket, 
								void function(Request request, Server server) run_action) {
		// Get the http header
		char[8192] buffer;
		int buffer_length = client_socket.receive(buffer);
		// FIXME: have this return a 413 if the end of the header is not found?
		char[][] buffer_pair = tango.text.Util.split(buffer[0 .. buffer_length], "\r\n\r\n");
		char[] raw_header = buffer_pair[0];
		char[] raw_body = buffer_pair.length > 1 ? buffer_pair[1] : "";

		// Print an error if the header was bad
		if(Socket.ERROR == buffer_length) {
			Stdout("Connection error.\n").flush;
			return;
		} else if(0 == buffer_length) {
			try {
				//if the connection closed due to an error, remoteAddress() could fail
				Stdout.format("Connection from {} closed.\n", client_socket.remoteAddress()).flush;
			} catch {
				Stdout("Connection from unknown closed.\n").flush;
			}
			return;
		}

		// Get the header info
		char[][] header_lines = tango.text.Util.splitLines(raw_header);
		char[][] first_line = tango.text.Util.split(header_lines[0], " ");
		char[] method = first_line[0];
		char[] uri = first_line[1];
		char[] http_version = first_line[2];

		// Get the content length and body
		// FIXME: update this to put large bodies into a file, so we don't waste ram
		int content_length = 0;
		if(method == "POST" || method == "PUT") {
			content_length = to_int(between(raw_header, "Content-Length: ", "\r\n"));

			int remaining_length = content_length - raw_body.length;
			while(remaining_length > 0) {
				char[8192] other_buffer;
				// FIXME: check for errors after receive like above
				buffer_length = client_socket.receive(other_buffer);
				if(buffer_length > 0)
					raw_body ~= other_buffer[0 .. buffer_length];
				remaining_length -= 8192;
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

		// Get the HTTP POST params
		if(method == "POST" && tango.text.Util.contains(header_lines[header_lines.length-1], ':') == false) {
			foreach(char[] param ; tango.text.Util.split(header_lines[header_lines.length-1], "&")) {
				char[][] pair = tango.text.Util.split(param, "=");
				if(pair.length == 2) {
					params[Helper.unescape_value(pair[0])] = Helper.unescape_value(pair[1]);
				}
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
		_client_socket = client_socket;
		_request = new Request(method, uri, http_version, controller, action, params, _cookies);

		// Run the action
		run_action(_request, this);

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
		Stdout("Route :\n").flush;
		Stdout.format("\tController Name: {}\n", controller).flush;
		Stdout.format("\tAction Name: {}\n", action).flush;
		Stdout.format("\tID: {}\n", id).flush;
		//*/
	}
}


