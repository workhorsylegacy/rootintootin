

import std.stdio;
import std.socket;
import std.regexp;

import rail_cannon;


public class Server {
	public static void start(void function(string action, Socket socket) routing) {
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
		TcpSocket listener = new TcpSocket();
		listener.blocking = false;
		listener.bind(new InternetAddress(2345));
		listener.listen(MAX_CONNECTIONS);
		SocketSet sset = new SocketSet(MAX_CONNECTIONS + 1);
		Socket[] reads;

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
					string method = header[0];
					string uri = header[1];
					string http_version = header[2];

					// Get the host
					string host = null;
					foreach(string line ; request) {
						auto reg = std.regexp.search(line, ": ");
						if(reg && reg.pre == "Host") {
							host = reg.post;
							break;
						}
					}

					// get the user agent
					string user_agent = null;
					foreach(string line ; request) {
						auto reg = std.regexp.search(line, ": ");
						if(reg && reg.pre == "User-Agent") {
							user_agent = reg.post;
							break;
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

					// FIXME: Just render the /user/index action for now.
					routing("index", reads[i]);
					//UserController con = new UserController();
					//con.index();

					//int[int] line_translations;
					//// FIXME: This should add the HTTP headers to the top of the page before sending
					//reads[i].send(render(con, line_translations));
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

