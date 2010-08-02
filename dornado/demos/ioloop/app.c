
#include "socket.c"


void run(char* path, char* string) {
	// Get the unix socket connection to the parent process
	int fd = c_create_unix_socket_fd(path);
	if(fd == -1) {
		perror("c_create_unix_socket_fd");
		return;
	}

	// Get the client connection from the parent process
	// Then read the request and write the response
	char buffer[1024];
	while(1) {
		int connfd = c_read_client_fd(fd);
		if(connfd == -1) {
			close(fd);
			return;
		}
		read(connfd, buffer, sizeof(buffer));

		write(connfd, string, strlen(string));
		close(connfd);
	}
}

int main(int argc, char** argv) {
	char* response = "HTTP/1.1 200 OK\r\nContent-Length: 7\r\nConnection: close\r\nContent-Type: text/html; charset=UTF-8\r\n\r\npoopies";

	run("socket", response);
	return 0;
}

