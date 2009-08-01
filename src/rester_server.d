


import tango.text.convert.Integer;
import tango.text.Util;
import tango.stdc.stringz;
import tango.io.device.File;

import tango.core.Thread;
import tango.core.sync.Mutex;
import tango.core.sync.Semaphore;
import tango.math.random.engines.Twister;

import tango.io.Stdout;
import tango.net.device.Berkeley;
import tango.net.device.Socket;
import tango.net.InternetAddress;

import tango.text.Regex;
import tango.time.chrono.Gregorian;
import tango.time.WallClock;
import tango.time.Clock;

import language_helper;
import helper;
import db;
import rester;

const int SOCKET_ERROR = -1;

public class Server {
	private bool _has_rendered = false;
	private Request _request = null;
	private Socket _client_socket = null;
	private Socket _event_socket = null;
	private Socket[] _client_sockets;
	private Berkeley _event_server;
	private Berkeley[] _event_sockets;
	private Mutex _event_sockets_mutex;
	private Semaphore _event_semaphore;
	private char[][] _event_headers;
	private char[][] _events_to_trigger;
	private int _session_id = 0;
	private char[][char[]] _sessions;
	private char[][char[]] _cookies;
	private char[] _salt;

	private ushort _port;
	private ushort _event_port;
	private uint _max_connections;
	private char[] _buffer = null;
	private char[] _event_buffer = null;
	private uint _header_max_size;
	private RunnerBase _runner = null;

	public this() {
		// Get a random salt for salting sessions
		Twister* random = new Twister();
		random.seed(Clock.now.span.millis);
		this._salt = to_s(random.next());
		delete random;

		this._event_sockets_mutex = new Mutex();
		this._event_semaphore = new Semaphore();
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

		_client_socket.output.write(header);
	}

	public void render_text(char[] text, ushort status_code = 200) {
		// If we have already rendered, show an error
		if(_has_rendered) {
			throw new Exception("Something has already been rendered.");
		}

		// Get the status code.
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
		"Server: Rester_0.1\r\n", 
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

		_client_socket.output.write(tango.text.Util.join(reply, ""));
	}

	// Start without events
	public void start(ushort port, uint max_connections, 
						char[] buffer, uint header_max_size, 
						char[] db_host, char[] db_user, char[] db_password, char[] db_name, 
						RunnerBase runner) {

		this.start(port, 0, max_connections, 
					buffer, null, header_max_size, 
					db_host, db_user, db_password, db_name, 
					runner);
	}

	// Start with events
	public void start(ushort port, ushort event_port, uint max_connections, 
						char[] buffer, char[] event_buffer, uint header_max_size, 
						char[] db_host, char[] db_user, char[] db_password, char[] db_name, 
						RunnerBase runner) {

		this._port = port;
		this._event_port = event_port;
		this._max_connections = max_connections;
		this._buffer = buffer;
		this._event_buffer = event_buffer;
		this._header_max_size = header_max_size;
		this._runner = runner;

		// Connect to the database
		db_connect(db_host, db_user, db_password, db_name);

		// Create a thread that responds to normal requests
		ThreadGroup t = new ThreadGroup();
		t.create(&begin_normal_responder);

		// Create event threads if desired
		if(this._event_port > 0) {
			t.create(&begin_event_acceptor);
			t.create(&begin_event_responder);
		}

		Stdout("Server running ...\n").flush;
		t.joinAll();
	}

	private void begin_normal_responder() {
		// Create a socket that is non-blocking, can re-use dangling addresses, and can hold many connections.
		tango.net.device.Socket.ServerSocket server = new tango.net.device.Socket.ServerSocket(
													new InternetAddress(this._port), 
													this._max_connections, 
													true);
		Socket pending_client = null;

		while(true) {
			pending_client = null;

			// Respond to all the clients
			for(size_t i=0; i<this._client_sockets.length; i++) {
				// Reset the attributes
				_has_rendered = false;
				foreach(char[] key ; _cookies.keys)
					_cookies.remove(key);
				_client_socket = this._client_sockets[i];

				// Process the request
				try {
					this.process_request(this._buffer, this._header_max_size);
				} catch(Exception e) {
					char[] msg = "Error: file " ~ e.file ~ ", Line " ~ to_s(e.line) ~ ", msg '" ~ e.msg ~ "'";
					this.render_text(msg, 500);
				}

				// Close the client and remove
				_client_socket.close();
				Array!(Socket[]).remove(this._client_sockets, i);
			}

			// Accept client requests
			try {
				pending_client = server.accept();
				//Stdout.format("Connection from {} established.\n", pending_client.remoteAddress()).flush;

				if(this._client_sockets.length < this._max_connections) {
					this._client_sockets ~= pending_client;
				} else {
					pending_client.output.write("503: Service Unavailable - Too many requests in the queue.");
					pending_client.close();
				}
			} catch(Exception e) {
				Stdout.format("Error accepting: {}\n", e).flush;
				if(pending_client && pending_client.isAlive) {
					pending_client.close();
				}
			}
		}
	}

	private void begin_event_acceptor() {
		// Create a socket that is non-blocking, can re-use dangling addresses, and can hold many connections.
		this._event_server = Berkeley();
		this._event_server.open(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
		//this._event_server.blocking = false;
		this._event_server.addressReuse(true);
		try {
			this._event_server.bind(new InternetAddress(this._event_port));
		} catch(Exception e) {
			Stdout.format("Event processing socket could not bind to port {}\n", this._event_port).flush;
			return;
		}
		this._event_server.listen(this._max_connections);

		Berkeley pending_event;

		while(true) {
			// Accept event requests
			pending_event = Berkeley();
			try {
				this._event_server.accept(pending_event);
				Stdout.format("Connection from {} established.\n", pending_event.remoteAddress).flush;

				if(this._event_sockets.length < this._max_connections) {
					synchronized(this._event_sockets_mutex) {
						this._event_sockets ~= pending_event;

						// FIXME: This duplicates code in process_request
						char[1024 * 8] buffer;
						int len = pending_event.receive(buffer);
						int header_end = tango.text.Util.locatePattern(buffer[0 .. len], "\r\n\r\n", 0);

						// Get the header info
						char[] header = buffer[0 .. header_end].dup;
						char[][] header_lines = tango.text.Util.splitLines(header);
						char[][] first_line = split(header_lines[0], " ");
						char[] method = first_line[0];
						char[] uri = first_line[1];
						char[] http_version = first_line[2];

						// Get the controller and action
						char[][] route = split(split(uri, "?")[0], "/");
						char[] controller = route.length > 1 ? route[1] : null;
						char[] action = route.length > 2 ? route[2] : "index";
						char[] event = controller ~ ':' ~ action;

						this._event_headers ~= event;
					}
				} else {
					pending_event.send("503: Service Unavailable - Too many requests in the queue.");
					pending_event.shutdown(SocketShutdown.BOTH);
					pending_event.detach();
				}
			} catch(Exception e) {
				Stdout.format("Error accepting: {}\n", e).flush;
				if(pending_event.isAlive) {
					pending_event.shutdown(SocketShutdown.BOTH);
					pending_event.detach();
				}
			}
		}
	}

	private void begin_event_responder() {
		SocketSet write_socket_set = new SocketSet(this._max_connections);
		SocketSet error_socket_set = new SocketSet(this._max_connections);

		while(true) {
			// Wait for events to be triggered
			_event_semaphore.wait();
			Stdout("\n\n\ndoing events\n").flush;

			// Get only the sockets waiting for events that were triggered
			Berkeley[] sockets_with_events, copy_sockets_with_events;
			synchronized(this._event_sockets_mutex) {
				for(size_t i=0; i<this._events_to_trigger.length; i++) {
					for(size_t j=0; j<this._event_sockets.length; j++) {
						if(this._events_to_trigger[i] == this._event_headers[j]) {
							sockets_with_events ~= this._event_sockets[j];
							break;
						}
					}
				}
			}
			copy_sockets_with_events = sockets_with_events.dup;


			while(sockets_with_events.length > 0) {
				// Determine which sockets are writeable and have errored
				write_socket_set.reset();
				error_socket_set.reset();
				foreach(Berkeley socket; sockets_with_events) {
					write_socket_set.add(socket.handle);
					error_socket_set.add(socket.handle);
				}
				SocketSet.select(null, write_socket_set, error_socket_set, 100000);

				// Write the responses
				for(size_t i=0; i<sockets_with_events.length; i++) {
					if(write_socket_set.isSet(sockets_with_events[i].handle) == false) {
						continue;
					}

					// FIXME: Change this to fire events
					sockets_with_events[i].send("example event: blah");

					// Remove this client from the socket set
					sockets_with_events[i].shutdown(SocketShutdown.BOTH);
					sockets_with_events[i].detach();
					Array!(Berkeley[]).remove(sockets_with_events, i);
				}

				// Close errors
				for(size_t i=0; i<sockets_with_events.length; i++) {
					if(error_socket_set.isSet(sockets_with_events[i].handle) == false) {
						continue;
					}

					// Remove this client from the socket set
					sockets_with_events[i].shutdown(SocketShutdown.BOTH);
					sockets_with_events[i].detach();
					Array!(Berkeley[]).remove(sockets_with_events, i);
				}
			}

			// Remove the sockets that fired
			synchronized(this._event_sockets_mutex) {
				for(size_t i=0; i<copy_sockets_with_events.length; i++) {
					for(size_t j=0; j<this._event_sockets.length; j++) {
						if(copy_sockets_with_events[i] == this._event_sockets[j]) {
							Array!(Berkeley[]).remove(this._event_sockets, j);
							Array!(char[][]).remove(this._event_headers, j);
							break;
						}
					}
				}
			}

			this._events_to_trigger = [];
		}
	}

	private void process_request(char[] buffer, uint header_max_size) {
		// Get the http header
		int buffer_length = _client_socket.input.read(buffer);

		// Show an error if the header was bad
		if(SOCKET_ERROR == buffer_length) {
			Stdout("Connection error.\n").flush;
			return;
		} else if(0 == buffer_length) {
			try {
				//if the connection closed due to an error, remoteAddress() could fail
				//Stdout.format("Connection from {} closed.\n", _client_socket.remoteAddress()).flush;
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
		char[][] first_line = split(header_lines[0], " ");
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
					buffer_length = _client_socket.input.read(buffer);
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

			char[][] pair = split(line, ": ");
			if(pair.length == 2) {
				fields[pair[0]] = pair[1];
			}
		}

		// Get the cookies
		if(("Cookie" in fields) != null) {
			foreach(char[] cookie ; split(fields["Cookie"], "; ")) {
				char[][] pair = split(cookie, "=");
				if(pair.length != 2) {
					Stdout.format("Malformed cookie: {}\n", cookie).flush;
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
			foreach(char[] param ; split(split(uri, "?")[1], "&")) {
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
				foreach(char[] param ; split(raw_body, "&")) {
					char[][] pair = split(param, "=");
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
				char[] boundary = split(content_type, "; boundary=")[1];
				Stdout.format("Boundary [[{}]]\n", boundary).flush;

				File raw_body_file = new File("raw_body", File.ReadExisting);
				char[] raw_body = "";
				char[100] buf;
				int len = 0;
				while((len = raw_body_file.read(buf)) > 0) {
					raw_body ~= buf[0 .. len];
				}

				// Add any params
				foreach(char[] part ; split(raw_body, boundary)) {
					if(tango.text.Util.locatePattern(part, "Content-Disposition: form-data; ", 0) == 0) {
						char[] data = between("Content-Disposition: form-data; ", "\r\n");
						foreach(char[] variable ; split(data, "; ")) {
							char[] pair = split(variable, "=");
							if(pair[0] == "name")
								params[pair[1]] = pair[1];
						}
					}
				}
				//char[] meta = split(parts[1], "\r\n\r\n")[0];
				//char[] file = split(parts[1], "\r\n\r\n")[1][0 .. length-2];
			}
		}
*/
		// Get the controller and action
		char[][] route = split(split(uri, "?")[0], "/");
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

		Stdout("Route :\n").flush;
		Stdout.format("\tController Name: {}\n", controller).flush;
		Stdout.format("\tAction Name: {}\n", action).flush;
		Stdout.format("\tID: {}\n", id).flush;

		// Run the action
		char[] response = null;
		response = _runner.run_action(_request);
		if(_request.response_type == ResponseType.normal && response != null) {
			this.render_text(response);
		} else if(_request.response_type == ResponseType.redirect_to) {
			this.redirect_to(_request.redirect_to_url);
		} else if(_request.response_type == ResponseType.render_view) {
			response = _runner.render_view(_request.controller, _request.render_view_name);
			this.render_text(response, 200);
		} else if(_request.response_type == ResponseType.render_text) {
			this.render_text(_request.render_text_text, 200);
		}

		// Trigger any events
		if(_request.events_to_trigger.length > 0) {
			foreach(char[] event ; _request.events_to_trigger) {
				this._events_to_trigger ~= controller ~ ':' ~ event;
			}
			_event_semaphore.notify();
		}

		return;
	}
}


