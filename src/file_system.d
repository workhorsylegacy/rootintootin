/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


module file_system;
private import tango.stdc.stringz;


char** list_dirs(char[] dir_name, out int len) {
	return c_list_dirs(toStringz(dir_name), &len);
}

void free_list_dirs(char** entries, int len) {
	c_free_list_dirs(entries, len);
}

private:

extern (C):

char** c_list_dirs(char* dir_name, int* len);
void c_free_list_dirs(char** entries, int len);

