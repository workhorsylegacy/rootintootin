/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


#include <sys/types.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <regex.h>

regex_t* regexes = NULL;

void c_regex_init(size_t regex_count) {
	regexes = calloc(regex_count, sizeof(regex_t));
}

void c_setup_regex(size_t index, char* pattern) {
	// Compile the regex
	int ret = regcomp(&regexes[index], pattern, REG_NOSUB);
	if(ret != 0) {
		printf("Failed to compile regex: %s\n", pattern);
	}
}

bool c_match_regex(size_t index, char* value) {
	// Test the pattern
	int ret = regexec(&regexes[index], value, 0, NULL, 0);
	if(ret != 0) {
		printf("no match\n");
		return false;
	} else {
		printf("match: %s\n", value);
		return true;
	}
}

