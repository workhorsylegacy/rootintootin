


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcgi_stdio.h>


int c_fcgi_accept() {
	return FCGI_Accept();
}

void c_printf(char* message) {
	printf(message);
}

