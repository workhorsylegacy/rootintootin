/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.stdc.stringz;


int write_client_fd(int fd) {
	return c_write_client_fd(fd);
}

int read_client_fd(int fd) {
	return c_read_client_fd(fd);
}

void socket_read(int fd, char* buffer) {
	c_socket_read(fd, buffer);
}

void socket_write(int fd, char* buffer) {
	c_socket_write(fd, buffer);
}

int connect_unix_socket_fd(char[] path) {
	return c_connect_unix_socket_fd(toStringz(path));
}

int create_unix_socket_fd(char[] path) {
	return c_create_unix_socket_fd(toStringz(path));
}

private:

extern (C):

int c_write_client_fd(int fd);
int c_read_client_fd(int fd);
void c_socket_read(int fd, char* buffer);
void c_socket_write(int fd, char* buffer);
int c_connect_unix_socket_fd(char* path);
int c_create_unix_socket_fd(char* path);

