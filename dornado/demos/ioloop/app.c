
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/uio.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>


int get_unix_socket_fd(char* path) {
	struct sockaddr_un unix_socket_name = {0};

	// Remove any old fd from the previous unix socket
	if(unlink(path) < 0) {
		if(errno != ENOENT) {
			fprintf(stderr, "%s: ", path);
			perror("unlink");
			return -1;
		}
	}

	// Make sure the path is small enough
	unix_socket_name.sun_family = AF_UNIX;
	if(strlen(path) >= sizeof(unix_socket_name.sun_path))
		return -1;
	strcpy(unix_socket_name.sun_path, path);

	// Connect to the unix socket and return the fd
	int fd = socket(PF_UNIX, SOCK_DGRAM, 0);
	if(fd == -1)
		return -1;
	if(bind(fd, (const struct sockaddr*)&unix_socket_name, sizeof(unix_socket_name))) {
		close(fd);
		return -1;
	}
	return fd;
}

int get_client_fd(int fd) {
	char buf[1];
	char ccmsg[CMSG_SPACE(sizeof((int)-1))];

	struct iovec iov;
	iov.iov_base = buf;
	iov.iov_len = 1;

	struct msghdr msg;
	msg.msg_name = 0;
	msg.msg_namelen = 0;
	msg.msg_iov = &iov;
	msg.msg_iovlen = 1;
	msg.msg_control = ccmsg;
	msg.msg_controllen = sizeof(ccmsg);

	if(recvmsg(fd, &msg, 0) == -1) {
		perror("recvmsg");
		return -1;
	}

	struct cmsghdr* cmsg = CMSG_FIRSTHDR(&msg);
	if(!cmsg->cmsg_type == SCM_RIGHTS) {
		fprintf(stderr, "got control message of unknown type %d\n", 
				cmsg->cmsg_type);
		return -1;
	}
	return *(int*)CMSG_DATA(cmsg);
}

void run(char* path, char* string) {
	// Get the unix socket connection to the parent process
	int fd = get_unix_socket_fd(path);
	if(fd == -1) {
		perror("get_unix_socket_fd");
		return;
	}

	// Get the client connection from the parent process
	// Then read the request and write the response
	char buffer[1024];
	while(1) {
		int connfd = get_client_fd(fd);
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

