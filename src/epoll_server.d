

private import tango.core.Thread;
private import tango.io.selector.EpollSelector;
private import tango.net.device.Socket;
private import tango.net.InternetAddress;
private import tango.io.Stdout;


public class SocketThread : Thread {
	private Socket _socket = null;
	private char[] delegate() _on_respond_normal;

	public this(Socket socket, char[] delegate() on_respond_normal) {
		_socket = socket;
		_on_respond_normal = on_respond_normal;
		super(&run);
	}

	private void run() {
		_socket.write(_on_respond_normal());
		_socket.shutdown();
		_socket.detach();
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
		this.on_started();

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
						SocketThread thread = new SocketThread(client, &this.on_respond_normal);
						thread.start();
					} catch(tango.core.Exception.ThreadException err) {
						client.write(this.on_respond_too_many_threads());
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

	public void on_started() {
		Stdout.format("Running on port: {} ...\n", this._port).flush;
	}

	public char[] on_respond_normal() {
		return "The 'normal' response goes here.";
	}

	public char[] on_respond_too_many_threads() {
		return "The 'too many threads' response goes here.";
	}
}

public class HttpServer : TcpServer {
	public this(ushort port, ushort max_waiting_clients) {
		super(port, max_waiting_clients);
	}

	public void on_started() {
		Stdout.format("Running on http://localhost:{} ...\n", this._port).flush;
	}

	public char[] on_respond_normal() {
		return "200 da normal response";
	}

	public char[] on_respond_too_many_threads() {
		return "500 da boom response";
	}
}

void main() {
	ushort port = 3000;
	ushort max_waiting_clients = 1000;

	auto server = new HttpServer(port, max_waiting_clients);
	server.start();
}


