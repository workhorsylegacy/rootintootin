/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.io.selector.EpollSelector;
private import tango.net.device.Socket;
private import tango.net.InternetAddress;
private import tango.io.Stdout;
private import language_helper;


public class TcpServer {
	protected ushort _port;
	protected int _max_waiting_clients;
	private ServerSocket _server = null;
	private EpollSelector _selector = null;
	private string _buffer;

	public this(ushort port, int max_waiting_clients, string buffer) {
		this._port = port;
		this._max_waiting_clients = max_waiting_clients;
		this._buffer = buffer;
	}

	public void start() {
		// Create a server socket that is non-blocking, can re-use dangling addresses, and can hold many connections.
		Socket client = null;
		this._server = new ServerSocket(new InternetAddress("0.0.0.0", this._port), this._max_waiting_clients, true);
		this._server.socket.blocking(false);

		// Create an epoll selector
		this._selector = new EpollSelector();
		this._selector.open(); //open(10, 3);
		this.on_started();

		while(true) {
			// Wait forever for any read, hangup, error, or invalid handle events
			this._selector.register(this._server, Event.Read | Event.Hangup | Event.Error | Event.InvalidHandle);
			if(this._selector.select(-1) == 0) {
				continue;
			}

			// Respond to any accepts or errors
			foreach(SelectionKey item; this._selector.selectedSet()) {
				if(item.conduit is this._server) {
					client = (cast(ServerSocket) item.conduit).accept();
					try {
						// Have the event process the request
						this.trigger_on_request(client, _buffer);

						client.shutdown();
						client.detach();
					} catch(Exception err) {
						Stdout("FIXME: inner loop threw").flush;
					}
				} else if(item.isError() || item.isHangup() || item.isInvalidHandle()) {
					Stdout("FIXME: error, hangup, or invalid handle").flush;
					this._selector.unregister(item.conduit);
				} else {
					Stdout("FIXME: unexpected result from selector.selectedSet()").flush;
				}
			}
		}
	}

	protected void on_started() {
		Stdout.format("Server running on http://localhost:{}\n", this._port).flush;
	}

	protected void on_request(Socket socket, string buffer) {
		// Read the request from the client
		int buffer_length = socket.input.read(buffer);
		//Stdout.format("Request: {}", buffer[0 .. buffer_length]).flush;

		// Write the response to the client
		socket.output.write("The 'normal' response goes here.");
	}

	protected void trigger_on_started() {
		this.on_started();
	}

	protected void trigger_on_request(Socket socket, string buffer) {
		this.on_request(socket, buffer);
	}
}



