
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

static int unix_socket_fd = -1;
static struct sockaddr_un unix_socket_name = {0};


int c_send_connection(int fd) {
	char ccmsg[CMSG_SPACE(sizeof(fd))];

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

int c_open_unix_fd(char* path) {
	unix_socket_name.sun_family = AF_UNIX;
	if(strlen(path) >= sizeof(unix_socket_name.sun_path) - 1)
		return 0;
	strcpy(unix_socket_name.sun_path, path);
	unix_socket_fd = socket(PF_UNIX, SOCK_DGRAM, 0);
	if(unix_socket_fd == -1)
		return 0;

	return 1;
}


