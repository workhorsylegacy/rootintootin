


#include <fcgi_stdio.h>


int c_fcgi_accept() {
	return FCGI_Accept();
}

void c_fcgi_printf(char* message) {
	FCGI_printf(message);
}

