/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.stdc.stringz;


int write_client_fd(int unix_socket_fd, int fd) {
	return c_write_client_fd(unix_socket_fd, fd);
}

int read_client_fd(int unix_socket_fd) {
	return c_read_client_fd(unix_socket_fd);
}

int socket_read(int fd, char* buffer, int buffer_length) {
	return c_socket_read(fd, buffer, buffer_length);
}

void socket_write(int fd, char* buffer) {
	c_socket_write(fd, buffer);
}

void socket_close(int fd) {
	c_socket_close(fd);
}

int connect_unix_socket_fd(char[] path) {
	return c_connect_unix_socket_fd(toStringz(path));
}

int create_unix_socket_fd(char[] path) {
	return c_create_unix_socket_fd(toStringz(path));
}

int create_socket_fd(int port, int max_waiting_clients, bool is_blocking) {
	return c_create_socket_fd(port, max_waiting_clients, is_blocking);
}

int accept_socket_fd(int fd) {
	return c_accept_socket_fd(fd);
}

private:

extern (C):

int c_write_client_fd(int unix_socket_fd, int fd);
int c_read_client_fd(int unix_socket_fd);
int c_socket_read(int fd, char* buffer, int buffer_length);
void c_socket_write(int fd, char* buffer);
void c_socket_close(int fd);
int c_connect_unix_socket_fd(char* path);
int c_create_unix_socket_fd(char* path);
int c_create_socket_fd(int port, int max_waiting_clients, bool is_blocking);
int c_accept_socket_fd(int fd);

