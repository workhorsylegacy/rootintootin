/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/

private import tango.io.Stdout;
private import inotify;

int main() {
	file_change[] changes;
	size_t len=0;
	while(true) {
		changes = fs_watch("/home/matt", len);

		Stdout.format("len: {}\n", len).flush;
		size_t i=0;
		//for(i=0; i<len; i++) {
		//	Stdout.format("changes[i].name: {}\n", changes[i].name).flush;
		//	Stdout.format("status: {}\n", to_s(changes[i].status)).flush;
		//}
		//Stdout("\n\n").flush;
	}

	return 0;
}


