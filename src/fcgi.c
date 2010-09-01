


#include <fcgi_stdio.h>


int c_fcgi_accept() {
	return FCGI_Accept();
}

void c_fcgi_printf(char* message) {
	FCGI_printf(message);
}

void c_fcgi_get_stdin(char* buffer, size_t len) {
	size_t i;
	for(i=0; i<len; i++) {
		buffer[i] = FCGI_getchar();
	}
}
