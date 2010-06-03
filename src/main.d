/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


import file_system;
import tango.io.Stdout;


int main() {
	char[][] entries = dir_entries("/home/matt/Desktop/");

	foreach(char[] entry; entries) {
		Stdout.format("entry: {}\n", entry).flush;
	}

	return 0;
}


