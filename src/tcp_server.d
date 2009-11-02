

private import tango.core.Thread;
private import tango.core.sync.Semaphore;
private import tango.core.sync.Mutex;
private import tango.io.selector.EpollSelector;
private import tango.net.device.Socket;
private import tango.net.InternetAddress;
private import tango.io.Stdout;

private import language_helper;


public class SocketThread : Thread {
	private Semaphore _semaphore;
	private Socket _socket = null;
	private void delegate(Socket socket) _trigger_on_read_request = null;
	private void delegate(SocketThread t) _on_end = null;

	public this(void delegate(SocketThread t) on_end) {
		_semaphore = new Semaphore();
		_on_end = on_end;
		super(&run);
	}

	public void run_socket(Socket socket, void delegate(Socket socket) trigger_on_read_request) {
		_socket = socket;
		_trigger_on_read_request = trigger_on_read_request;
		_semaphore.notify();
	}

	private void run() {
		while(true) {
			_semaphore.wait();
			_trigger_on_read_request(_socket);
			_socket.shutdown();
			_socket.detach();
			_on_end(this);
		}
	}
}

public class SocketThreadPool {
	private size_t _number_of_threads;
	private SocketThread[] _idle_threads;
	private SocketThread[] _busy_threads;
	private Mutex _thread_mutex;

	public this(size_t number_of_threads) {
		_number_of_threads = number_of_threads;
		_thread_mutex = new Mutex();

		// Create a thread for each socket
		size_t i = 0;
		try {
			for(i=0; i<_number_of_threads; i++) {
				auto t = new SocketThread( &socket_on_end);
				t.isDaemon = true;
				t.start();
				_idle_threads ~= t;
			}
		} catch(tango.core.Exception.ThreadException err) {
			throw new Exception("Thread pool could not create " ~ to_s(_number_of_threads)  ~ " threads. System ran out at " ~ to_s(i) ~ " threads.");
		}
	}

	public bool run_socket(Socket socket, void delegate(Socket socket) trigger_on_read_request) {
		SocketThread t = null;

		try {
			_thread_mutex.lock();
			// Get an idle thread
			if(_idle_threads.length > 0) {
				t = _idle_threads[0];
				Array!(SocketThread[]).remove(_idle_threads, 0);
				_busy_threads ~= t;
				t.run_socket(socket, trigger_on_read_request);
			}
		} finally {
			_thread_mutex.unlock();
		}
		return t !is null;
	}

	private void socket_on_end(SocketThread t) {
		// Remove the thread from the busy list
		try {
			_thread_mutex.lock();
			for(size_t i=0; i<_busy_threads.length; i++) {
				if(_busy_threads[i] is t)
					Array!(SocketThread[]).remove(_busy_threads, i);
			}
		
			// Add the thread to the idle list
			_idle_threads ~= t;
		} finally {
			_thread_mutex.unlock();
		}
	}
}


public class TcpServer {
	protected ushort _port;
	protected ushort _max_waiting_clients;
	protected ushort _max_threads;
	private ServerSocket _server = null;
	private EpollSelector _selector = null;
	private SocketThreadPool _pool = null;

	public this(ushort port, ushort max_waiting_clients, ushort max_threads) {
		this._port = port;
		this._max_waiting_clients = max_waiting_clients;
		this._max_threads = max_threads;
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
		this._pool = new SocketThreadPool(this._max_threads);
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

					bool ran_successfully = this._pool.run_socket(client, &this.trigger_on_read_request);
					if(!ran_successfully) {
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


