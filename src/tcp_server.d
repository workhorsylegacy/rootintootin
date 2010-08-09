/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.io.Stdout;
private import socket;


class TcpServer {
	private int _sock;
	private char[1024*256] _buffer;
	private char[] _response;
	protected ushort _port;
	protected int _max_waiting_clients;
	protected bool _is_address_reusable;

	public this(ushort port, int max_waiting_clients) {
		_port = port;
		_max_waiting_clients = max_waiting_clients;
		_is_address_reusable = true;
	}

	public void start() {
		_sock = create_socket_fd(_port, _max_waiting_clients);
		if(_sock == -1) {
			// Close the connection to the client
			socket_close(_sock);
			return;
		}

		this.on_started();
		while(true) {
			int fd = accept_socket_fd(_sock);
			if(fd == -1)
				continue;

			on_connection_ready(fd);
		}
	}

	protected void on_connection_ready(int fd) {
		
	}

	protected void on_started() {
		Stdout.format("Server running on http://localhost:{}\n", this._port).flush;
	}
}


