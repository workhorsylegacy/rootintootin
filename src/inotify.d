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

enum FileStatus {
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

struct FileChange {
	char[] name;
	FileStatus status;
}

char[] to_s(FileStatus status) {
	return fromStringz(c_to_s(status));
}

FileChange[] fs_watch(char[] path_name) {
	size_t c_len;
	CFileChange* c_changes = c_fs_watch(toStringz(path_name), &c_len);

	FileChange[] changes;
	for(size_t i=0; i<c_len; i++) {
		FileChange c;
		c.name = fromStringz(c_changes[i].name);
		c.status = c_changes[i].status;
		changes ~= c;
	}

	return changes;
}


private:
extern (C):

struct CFileChange {
	char* name;
	FileStatus status;
}

char* c_to_s(FileStatus status);
CFileChange* c_fs_watch(char* path_name, size_t* out_len);

