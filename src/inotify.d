/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


module inotify;
private import tango.io.Stdout;
private import tango.stdc.stringz;

enum file_status {
	access, 
	modify, 
	attrib, 
	close_write, 
	close_nowrite, 
	open, 
	moved_from, 
	moved_to, 
	create, 
	_delete, 
	delete_self, 
	move_self
}

struct c_file_change {
	char* name;
	file_status status;
}

struct file_change {
	char[] name;
	file_status status;
}

char[] to_s(file_status status) {
	return fromStringz(c_to_s(status));
}

file_change[] fs_watch(char[] path_name, out size_t len) {
	size_t c_len;
	c_file_change* c_changes = c_fs_watch(toStringz(path_name), &c_len);
	len = c_len;

	file_change[] changes;
	for(size_t i=0; i<len; i++) {
		file_change c;
		c.name = fromStringz(c_changes[i].name);
		c.status = c_changes[i].status;
		changes ~= c;
	}

	return changes;
}


private:
extern (C):

char* c_to_s(file_status status);
c_file_change* c_fs_watch(char* path_name, size_t* out_len);

