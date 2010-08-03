/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/time.h>
#include <sys/uio.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>


static struct sockaddr_un unix_socket_name = {0};

int c_create_unix_socket_fd(char* path) {
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
	int unix_socket_fd = socket(PF_UNIX, SOCK_DGRAM, 0);
	if(unix_socket_fd == -1)
		return -1;
	if(bind(unix_socket_fd, (const struct sockaddr*)&unix_socket_name, sizeof(unix_socket_name))) {
		close(unix_socket_fd);
		return -1;
	}
	return unix_socket_fd;
}

int c_connect_unix_socket_fd(char* path) {
	unix_socket_name.sun_family = AF_UNIX;
	if(strlen(path) >= sizeof(unix_socket_name.sun_path) - 1)
		return 0;
	strcpy(unix_socket_name.sun_path, path);
	int unix_socket_fd = socket(PF_UNIX, SOCK_DGRAM, 0);

	return unix_socket_fd;
}

int c_socket_read(int fd, char* buffer) {
	return read(fd, buffer, strlen(buffer));
}

void c_socket_write(int fd, char* buffer) {
	write(fd, buffer, strlen(buffer));
}

void c_socket_close(int fd) {
	close(fd);
}

int c_write_client_fd(int unix_socket_fd, int fd) {
	char ccmsg[CMSG_SPACE(sizeof(int))];

	struct iovec vec;
	vec.iov_base = "X";
	vec.iov_len = 1;

	struct msghdr msg;
	msg.msg_name = (struct sockaddr*)&unix_socket_name;
	msg.msg_namelen = sizeof(unix_socket_name);
	msg.msg_iov = &vec;
	msg.msg_iovlen = 1;
	msg.msg_control = ccmsg;
	msg.msg_controllen = sizeof(ccmsg);

	struct cmsghdr* cmsg = CMSG_FIRSTHDR(&msg);
	cmsg->cmsg_level = SOL_SOCKET;
	cmsg->cmsg_type = SCM_RIGHTS;
	cmsg->cmsg_len = CMSG_LEN(sizeof(fd));
	*(int*)CMSG_DATA(cmsg) = fd;
	msg.msg_controllen = cmsg->cmsg_len;
	msg.msg_flags = 0;

	int rv = (sendmsg(unix_socket_fd, &msg, 0) != -1);
	if(rv)
		close(fd);
	return rv;
}

int c_read_client_fd(int unix_socket_fd) {
	char buf[1];
	char ccmsg[CMSG_SPACE(sizeof(int))];

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

	if(recvmsg(unix_socket_fd, &msg, 0) == -1) {
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

