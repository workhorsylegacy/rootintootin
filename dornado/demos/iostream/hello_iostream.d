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
private import tango.net.device.Socket;
private import tango.net.InternetAddress;
public import tango.io.Stdout;

public import dornado.iostream;
public import dornado.ioloop;
public import language_helper;


class HelloServer {
	public Socket _socket;
	public IOStream _stream;

	public void on_headers(string data) {
		Stdout(data).newline.flush;
		string[string] headers;
		foreach(string line ; split(data, "\r\n")) {
			string[] parts = split(line, ":");
			if(parts.length == 2) {
				headers[trim(parts[0])] = trim(parts[1]);
			}
		}
		this._stream.read_bytes(to_int(headers["Content-Length"]), &this.on_body);
	}

	public void on_body(string data) {
		Stdout(data).newline.flush;
		this._stream.close();
		IOLoop.instance().stop();
	}

	public void start() {
		this._socket = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
		this._socket.connect("friendfeed.com", 80);
		this._stream = new IOStream(this._socket);
	}
}

void main() {
	IOLoop.use_epoll = true;
	auto server = new HelloServer();
	server.start();

	//server._stream.write("GET / HTTP/1.0\r\n\r\n");
	//server._stream.read_until("\r\n\r\n", &server.on_headers);
	//IOLoop.instance().start(server._socket);
}

