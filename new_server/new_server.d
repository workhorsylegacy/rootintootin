

private import tango.net.device.Socket;
private import tango.io.model.IConduit;
private import tango.net.InternetAddress;
private import tango.io.Stdout;
private import tango.io.Console;
private import tango.sys.Process;
public import dornado.ioloop;


class TcpServer {
	private ServerSocket _sock;
	private char[1024] _buffer;
	private char[] _response;

	public void handle_connection(Socket connection, string address) {
		// Get the request from the client
		size_t buffer_length = connection.read(_buffer);
		char[] request = _buffer[0 .. buffer_length];

		// Write the response to the socket
		connection.write("blah");
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
		connection_ready(_sock, fd, events);
	}

	public void start(int port, int max_waiting_clients, bool is_address_reusable) {
		_sock = new ServerSocket(new InternetAddress("0.0.0.0", port), max_waiting_clients, is_address_reusable);
		_sock.socket.blocking(false);

		auto io_loop = IOLoop.instance();
		auto callback = &this.call_connection_ready;
		io_loop.add_handler(_sock.fileHandle, callback, io_loop.READ);
		//Stdout.format("http://localhost:{}", port).newline.flush;
		io_loop.start(_sock);
	}
}

public void main() {
	IOLoop.use_epoll = true;

	int port = 3000;
	int max_waiting_clients = 1024;
	bool is_address_reusable = true;
	auto server = new TcpServer();
	server.start(port, max_waiting_clients, is_address_reusable);
}

