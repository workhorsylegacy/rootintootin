

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
	private	uint _max_threads;
	private	uint _port;
	private	uint _max_waiting_clients;
	private	ServerSocket _server;
	private	EpollSelector _selector;

	public this(uint port, uint max_threads, uint max_waiting_clients) {
		this._max_threads = max_threads;
		this._port = port;
		this._max_waiting_clients = max_waiting_clients;
		this._server = new ServerSocket(new InternetAddress(_port), _max_waiting_clients, true);
	}

	public void start() {
		Socket client;

		this._selector = new EpollSelector();
		this._selector.open(); //open(10, 3);
		this._server.socket.blocking(false);

		Stdout.format("Running on http://localhost:{} ...\n", this._port).flush;
		while(true) {
			this._selector.register(this._server, Event.Read | Event.Hangup | Event.Error | Event.InvalidHandle);
			if(this._selector.select(-1) == 0) {
				continue;
			}

			foreach(SelectionKey item; this._selector.selectedSet()) {
				if(item.conduit is this._server) {
					client = (cast(ServerSocket) item.conduit).accept();
					SocketThread thread = new SocketThread(client, this._selector);
					thread.start();
				} else if(item.isError() || item.isHangup() || item.isInvalidHandle()) {
					Stdout("FIXME: error, hangup, or invalid handle").flush;
					this._selector.unregister(item.conduit);
				} else {
					Stdout("FIXME: unexpected result from selector.selectedSet()");
				}
			}
		}
	}
}



void main() {
	TcpServer server = new TcpServer(3000, 10, 1000);
	server.start();
}


