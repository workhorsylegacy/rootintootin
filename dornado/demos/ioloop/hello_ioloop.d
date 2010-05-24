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
// FIXME: This is only needed for ISelectable.Handle.
//        We should just use an int instead.
private import tango.io.model.IConduit;
private import tango.net.InternetAddress;
private import tango.io.Stdout;
public import dornado.ioloop;

class HelloServer {
	private ServerSocket sock;
	private char[1024] buffer;

	public void handle_connection(Socket connection, string address) {
		connection.read(buffer);

		connection.write("hello world!");
		connection.shutdown();
		connection.detach();
	}

	public void connection_ready(ServerSocket sock, ISelectable.Handle fd, uint events) {
		while(true) {
			Socket connection;
			// FIXME: How do we get the address?
			string address = "";
	//		try {
				//connection, address = sock.accept();
				connection = sock.accept();
	//		} catch(socket.error e) {
	//			if e[0] not in (errno.EWOULDBLOCK, errno.EAGAIN)
	//				raise
	//			return;
	//		}
			connection.socket.blocking(false);
			handle_connection(connection, address);
		}
	}

	public void call_connection_ready(ISelectable.Handle fd, uint events) {
		connection_ready(sock, fd, events);
	}

	public void start() {
		int port = 3000;
		int max_waiting_clients = 128;
		bool is_address_reusable = true;
		this.sock = new ServerSocket(new InternetAddress("0.0.0.0", port), max_waiting_clients, is_address_reusable);
		this.sock.socket.blocking(false);

		auto io_loop = IOLoop.instance();
		auto callback = &this.call_connection_ready;
		io_loop.add_handler(this.sock.fileHandle, callback, io_loop.READ);
		Stdout.format("http://localhost:{}", port).newline.flush;
		io_loop.start(sock);
	}
}

public void main() {
	IOLoop.use_epoll = true;
	auto server = new HelloServer();
	server.start();
}

