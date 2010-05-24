/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/



private import tango.net.device.Socket;
private import tango.io.model.IConduit;
private import tango.net.InternetAddress;
private import tango.io.Stdout;
private import tango.io.Console;
private import tango.sys.Process;
public import dornado.ioloop;


public class TcpServer {
	private ServerSocket _sock;
	private char[1024] _buffer;
	private char[] _response;
	protected ushort _port;
	protected int _max_waiting_clients;
	protected bool _is_address_reusable;

	public this(ushort port, int max_waiting_clients, bool is_address_reusable) {
		_port = port;
		_max_waiting_clients = max_waiting_clients;
		_is_address_reusable = is_address_reusable;
	}

	private void handle_connection(Socket connection, string address) {
		// Get the request from the client
		size_t buffer_length = connection.read(_buffer);
		char[] request = _buffer[0 .. buffer_length];

		// Process the request and get the response
		char[] response = on_request(request);

		// Write the response to the socket
		connection.write(response);
		connection.shutdown();
		connection.detach();
	}

	private void connection_ready(ServerSocket sock, ISelectable.Handle fd, uint events) {
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
			this.handle_connection(connection, address);
		}
	}

	private void call_connection_ready(ISelectable.Handle fd, uint events) {
		this.connection_ready(_sock, fd, events);
	}

	protected void on_started() {
		Stdout.format("Server running on http://localhost:{}\n", this._port).flush;
	}

	public void start() {
		_sock = new ServerSocket(new InternetAddress("0.0.0.0", _port), _max_waiting_clients, _is_address_reusable);
		_sock.socket.blocking(false);

		auto io_loop = IOLoop.instance();
		auto callback = &this.call_connection_ready;
		io_loop.add_handler(_sock.fileHandle, callback, io_loop.READ);
		this.on_started();
		io_loop.start(_sock);
	}

	protected char[] on_request(char[] request) {
		throw new Exception("The on_request method of TcpServer needs to be overloaded on children.");
	}
}


