

private import tango.core.Thread;
private import tango.io.selector.EpollSelector;
private import tango.net.device.Socket;
private import tango.net.InternetAddress;
private import tango.io.Stdout;


public class SocketThread : Thread {
	private Socket _socket = null;
	private void delegate(Socket socket) _trigger_on_read_request;

	public this(Socket socket, void delegate(Socket socket) trigger_on_read_request) {
		_socket = socket;
		_trigger_on_read_request = trigger_on_read_request;
		super(&run);
	}

	private void run() {
		_trigger_on_read_request(_socket);
		_socket.shutdown();
		_socket.detach();
	}
}


public class TcpServer {
	protected ushort _port;
	protected ushort _max_waiting_clients;
	private ServerSocket _server = null;
	private EpollSelector _selector = null;

	public this(ushort port, ushort max_waiting_clients) {
		this._port = port;
		this._max_waiting_clients = max_waiting_clients;
	}

	public void on_started() {
		Stdout.format("Running on port: {} ...\n", this._port).flush;
	}

	public void on_read_request(Socket socket) {
		socket.write("The 'normal' response goes here.");
	}

	public void on_respond_too_many_threads(Socket socket) {
		socket.write("The 'too many threads' response goes here.");
	}

	protected void trigger_on_started() {
		this.on_started();
	}

	protected void trigger_on_read_request(Socket socket) {
		this.on_read_request(socket);
	}

	protected void trigger_on_respond_too_many_threads(Socket socket) {
		this.on_respond_too_many_threads(socket);
	}

	public void start() {
		// Create a server socket that is non-blocking, can re-use dangling addresses, and can hold many connections.
		Socket client = null;
		this._server = new ServerSocket(new InternetAddress(this._port), this._max_waiting_clients, true);
		this._server.socket.blocking(false);

		// Create an epoll selector
		this._selector = new EpollSelector();
		this._selector.open(); //open(10, 3);
		this.trigger_on_started();

		while(true) {
			// Wait forever for any read, hangup, error, or invalid handle events
			this._selector.register(this._server, Event.Read | Event.Hangup | Event.Error | Event.InvalidHandle);;
			if(this._selector.select(-1) == 0) {
				continue;
			}

			// Respond to any accepts or errors
			foreach(SelectionKey item; this._selector.selectedSet()) {
				if(item.conduit is this._server) {
					client = (cast(ServerSocket) item.conduit).accept();

					try {
						SocketThread thread = new SocketThread(client, &this.trigger_on_read_request);
						thread.start();
					} catch(tango.core.Exception.ThreadException err) {
						this.trigger_on_respond_too_many_threads(client);
						client.shutdown();
						client.detach();
						this._selector.unregister(item.conduit);
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
}


