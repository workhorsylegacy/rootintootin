/*------------------------------------------------------------------------------
#
#	This file is part of the Rootin Tootin web framework and licensed under the
#	GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#	This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


#include <sys/types.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <pcre.h>


int main() {
	char* pattern = "^/users/\\d+$";
	char value[]  = "/users/24";

	const int OVECCOUNT = 3;
	int ovector[OVECCOUNT];
	const char* error;
	int erroffset;

	// Compile the regex or print an error
	pcre* regex = pcre_compile(
			pattern, 	// the pattern
			0,			// default options
			&error,		// for error message
			&erroffset,	// for error offset
			0);

	if (!regex) {
		printf("pcre_compile failed (offset: %d), %s\n", erroffset, error);
		return -1;
	}

	// Test the string against the regex, and print
	int rc = pcre_exec(
		regex,				// the compiled pattern
		0,					// no extra data - pattern was not studied
		value,				// the string to match
		strlen(value),		// the length of the string
		0,					// start at offset 0 in the subject
		0,					// default options
		ovector,			// output vector for substring information
		OVECCOUNT);			// number of elements in the output vector

	//printf("rc: %d\n", PCRE_ERROR_NOMATCH);
	if(rc == PCRE_ERROR_NOMATCH) {
		printf("String didn't match\n");
	// FIXME: Add other error codes: http://pcre.org/pcre.txt
	} else if(rc < 0) {
		printf("Error while matching: %d\n", rc);
	} else {
	int i = 0;
		for(i=0; i<rc; i++) {
			printf("%2d: %.*s\n", i, ovector[2*i+1] - ovector[2*i], value + ovector[2*i]);
		}
	}

	free(regex);
	return 0;
}


