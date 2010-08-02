

private import tango.stdc.stringz;


int write_client_fd(int fd) {
	return c_write_client_fd(fd);
}

int read_client_fd(int fd) {
	return c_read_client_fd(fd);
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
int c_connect_unix_socket_fd(char* path);
int c_create_unix_socket_fd(char* path);

