

private import tango.stdc.stringz;


int send_connection(int fd) {
	return c_send_connection(fd);
}

int open_unix_fd(char[] path) {
	return c_open_unix_fd(toStringz(path));
}

private:

extern (C):

int c_send_connection(int fd);
int c_open_unix_fd(char* path);

