/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/

private import tango.io.Stdout;
private import inotify;

void on_create(char[] file_name) {
	Stdout("create: {}\n", file_name);
}

void on_read(char[] file_name) {
	Stdout("read: {}\n", file_name);
}

void on_update(char[] file_name) {
	Stdout("update: {}\n", file_name);
}

void on_delete(char[] file_name) {
	Stdout("delete: {}\n", file_name);
}


int main() {

	fs_watch("/home/matt", &on_create, &on_read, &on_update, &on_delete);

	return 0;
}


