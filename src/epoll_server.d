

private import tango.core.Thread;
private import tango.io.selector.EpollSelector;
private import tango.net.device.Socket;
private import tango.net.InternetAddress;
private import tango.io.Stdout;


public class SocketThread : Thread {
	private Socket _socket = null;
	private EpollSelector _selector = null;

	public this(Socket socket, EpollSelector selector) {
		_socket = socket;
		_selector = selector;
		super(&run);
	}

	private void run() {
		_socket.write("da response yo");
		_socket.shutdown();
		_socket.detach();
		_selector.unregister(_socket);
	}
}


public class TcpServer {
	private	ushort _port;
	private	ushort _max_waiting_clients;
	private	ServerSocket _server = null;
	private	EpollSelector _selector = null;

	public this(ushort port, ushort max_waiting_clients) {
		this._port = port;
		this._max_waiting_clients = max_waiting_clients;
	}

	public void start() {
		// Create a server socket that is non-blocking, can re-use dangling addresses, and can hold many connections.
		Socket client = null;
		this._server = new ServerSocket(new InternetAddress(this._port), this._max_waiting_clients, true);
		this._server.socket.blocking(false);

		// Create an epoll selector
		this._selector = new EpollSelector();
		this._selector.open(); //open(10, 3);
		Stdout.format("Running on http://localhost:{} ...\n", this._port).flush;

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
						SocketThread thread = new SocketThread(client, this._selector);
						thread.start();
					} catch(tango.core.Exception.ThreadException err) {
						client.write("500: Too many connections");
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



void main() {
	ushort port = 3000;
	ushort max_waiting_clients = 1000;

	TcpServer server = new TcpServer(port, max_waiting_clients);
	server.start();
}


