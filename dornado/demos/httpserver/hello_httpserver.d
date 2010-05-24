/*
# Copyright 2010 Matthew Brennan Jones
# Copyright 2009 Facebook
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#	 http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
*/

public import tango.io.Stdout;
public import dornado.httpserver;
public import dornado.ioloop;

class HelloServer {
	public void handle_request(HTTPRequest request) {
		string message = "You requested " ~ request.uri ~ "\n";
		request.write("HTTP/1.1 200 OK\r\nContent-Length: " ~ to_s(message) ~ "\r\n\r\n" ~ message);
		request.finish();
	}

	public void start() {
		int port = 3000;
		auto http_server = new HTTPServer(&this.handle_request);
		http_server.listen(port);
		Stdout.format("http://localhost:{}", port).newline.flush;
		IOLoop.instance().start(http_server.socket);
	}
}

void main() {
	IOLoop.use_epoll = true;
	auto hello = new HelloServer();
	hello.start();
}

