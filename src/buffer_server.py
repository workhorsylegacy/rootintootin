#!/usr/bin/env python2.6
# -*- coding: UTF-8 -*-

import errno
import functools
import socket
from tornado import ioloop, iostream

def connection_ready(sock, fd, events):
	while True:
		try:
			connection, address = sock.accept()
		except socket.error, e:
			if e[0] not in (errno.EWOULDBLOCK, errno.EAGAIN):
				raise
			return
		#connection.setblocking(0)

		# Get the request
		request = connection.recv(1024 * 8)

		# Write the request to the rootin tootin server
		# and read the response back
		client = socket.socket(socket.AF_INET, socket.SOCK_STREAM, 0);
		client.connect(('0.0.0.0', 3001))
		client.send(request)
		response = client.recv(1024 * 8)
		client.close()
		#print response

		# Write the response to the client
		stream = iostream.IOStream(connection)
		stream.write(response, stream.close)

if __name__ == '__main__':
	# Create a new tcp socket that is nonblocking, and
	# can reuse dangling addresses.
	sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM, 0)
	sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
	sock.setblocking(0)
	sock.bind(('', 3000))
	sock.listen(10000)

	# Create a tornado loop that uses our 
	# socket and callback to process requests
	io_loop = ioloop.IOLoop.instance()
	callback = functools.partial(connection_ready, sock)
	io_loop.add_handler(sock.fileno(), callback, io_loop.READ)

	# Exit the tornado loop if ctrl + c is pressed.
	try:
		io_loop.start()
	except KeyboardInterrupt:
		io_loop.stop()
		print "Exiting ..."

