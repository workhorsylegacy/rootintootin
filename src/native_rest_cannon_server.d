


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

		char[]  header = "HTTP/1.1 " ~ status ~ "\r\n" ~
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
			char[] hashed_session_id = Helper.hash_and_base64(tango.text.convert.Integer.toString(_session_id));
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
		"Date: ", tango.text.convert.Integer.toString(date.day), tango.text.convert.Integer.toString(date.month), tango.text.convert.Integer.toString(date.year), "\r\n", 
		"Server: Native_Rest_Cannon_0.1\r\n", 
		set_cookies, 
		"Status: ", status, "\r\n",
		//"X-Runtime: 0.15560\r\n",
		//"ETag: \"53e91025a55dfb0b652da97df0e96e4d\"\r\n",
		"Cache-Control: private, max-age=0\r\n",
		"Content-Type: text/html; charset=utf-8\r\n",
		"Content-Length: ", tango.text.convert.Integer.toString(text.length), "\r\n",
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

		// Create a socket that is non-blocking, can re-uses dangling addresses, and can hold many connections.
		Socket server = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
		server.blocking = false;
		server.bind(new InternetAddress(port));
		uint[1] opt = 1;
		server.setOption(SocketOptionLevel.SOCKET, SocketOption.SO_REUSEADDR, opt);
		server.listen(max_connections);

		// FIXME: Isn't this socket_set doing the same thing as the client_sockets array? Is it needed?
		SocketSet socket_set = new SocketSet(max_connections + 1);
		Socket[] client_sockets;

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
						Stdout.format("Connection from {} closed.\n", client_sockets[i].remoteAddress()).flush;
					} catch {
						Stdout("Connection from unknown closed.\n").flush;
					}
				} else {
//					Stdout.format("Received from {}: \n\"{}\"\n", client_sockets[i].remoteAddress(), buffer[0 .. read]).flush;

					// Get the request
					char[] raw_request = buffer[0 .. read];
					char[][] request = tango.text.Util.splitLines(raw_request);
					Stdout.format("\tRequest: [[{}]]\n", raw_request).flush;

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
					if(method == "POST" && tango.text.Util.contains(request[request.length-1], ':') == false) {
						foreach(char[] param ; tango.text.Util.split(request[request.length-1], "&")) {
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
					_client_socket = client_sockets[i];
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
}


