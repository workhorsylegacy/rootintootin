

private import tcp_server;
private import tango.io.Stdout;


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


