
private import tango.io.Stdout;

private import language_helper;
private import tcp_server;
private import http_server;
private import child_process;


public class ExampleServerChild : TcpServerChild {
	public char[] on_request(char[] request) {
		return "yeah! example time.";
	}
}

int main() {
	auto server = new ExampleServerChild();
	server.start();

	return 0;
}

