/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.io.Stdout;
private import tango.core.Thread;

private import language_helper;
private import socket;


class TcpServer {
	private int _sock = -1;
	private char[1024*256] _buffer;
	private char[] _response;
	protected ushort _port;
	protected int _max_waiting_clients;
	protected bool _is_address_reusable;
	protected bool _is_configuration_changed;

	public this(ushort port, int max_waiting_clients) {
		_port = port;
		_max_waiting_clients = max_waiting_clients;
		_is_address_reusable = true;
	}

	public void start() {
		// Get a new socket
		this.open();

		while(true) {
			// If the configuration is different get a new socket
			if(_is_configuration_changed) {
				this.close();
				this.open(false);
				_is_configuration_changed = false;
			}

			// Connect to a client
			int fd = accept_socket_fd(_sock);
			
			// Sleep for 10 milliseconds if there were no clients
			if(fd == -1) {
				Thread.sleep(0.01);
				continue;
			}

			on_connection_ready(fd);
		}
	}

	private void open(bool is_event_triggered = true) {
		_sock = create_socket_fd(_port, _max_waiting_clients, false);
		if(_sock == -1) {
			// Close the connection to the client
			socket_close(_sock);
			throw new Exception("The port '" ~ to_s(_port) ~ "' is already in use.");
		}

		this.on_started(is_event_triggered);
	}

	private void close() {
		// Just return if it is already not running
		if(_sock == -1)
			return;

		// Stop the socket
		socket_close(_sock);
		_sock = -1;
	}

	protected void on_connection_ready(int fd) {
		
	}

	protected void on_started(bool is_event_triggered = true) {
		Stdout.format("Server running on http://localhost:{}", this._port).newline.flush;
	}
}


