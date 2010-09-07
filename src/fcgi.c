/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


#include <fcgi_stdio.h>

void c_fcgi_write_stderr(char* message, size_t length) {
	FCGI_fwrite(message, length, 1, FCGI_stderr);
}

int c_fcgi_accept() {
	return FCGI_Accept();
}

void c_fcgi_printf(char* message) {
	FCGI_printf(message);
}

void c_fcgi_puts(char* message) {
	FCGI_puts(message);
}

void c_fcgi_get_stdin(char* buffer, size_t len) {
	size_t i;
	for(i=0; i<len; i++) {
		buffer[i] = FCGI_getchar();
	}
}
