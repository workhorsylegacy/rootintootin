/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


module regex;
private import tango.stdc.stringz;

void regex_init(size_t regex_count) {
	c_regex_init(regex_count);
}

void setup_regex(size_t index, char[] pattern) {
	c_setup_regex(index, toStringz(pattern));
}

bool match_regex(size_t index, char[] value) {
	return c_match_regex(index, toStringz(value));
}

private:

extern (C):

void c_regex_init(size_t regex_count);
void c_setup_regex(size_t index, char* pattern);
bool c_match_regex(size_t index, char* value);

