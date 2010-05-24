

private import http_server;
public import dornado.ioloop;


public void main() {
	IOLoop.use_epoll = true;
	int port = 3000;
	int max_waiting_clients = 1024;
	bool is_address_reusable = true;

	auto server = new HttpServer(port, max_waiting_clients, is_address_reusable);
	server.start();
}
