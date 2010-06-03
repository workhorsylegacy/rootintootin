/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


import file_system;
import tango.io.Stdout;
private import tango.stdc.stringz;


int main() {
	int len = 0;
	char** entries = list_dirs("./", len);

	int i = 0;
	for(i=0; i<len; i++) {
		Stdout.format("entry: {}\n", fromStringz(entries[i])).flush;
	}

	free_list_dirs(entries, len);

	return 0;
}


