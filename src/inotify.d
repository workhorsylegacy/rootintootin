/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


module inotify;
private import tango.stdc.stringz;

void function(char[] file_name) _on_create;
void function(char[] file_name) _on_read;
void function(char[] file_name) _on_update;
void function(char[] file_name) _on_delete;

void fs_watch(char[] path_name, 
				void function(char[] file_name) on_create, 
				void function(char[] file_name) on_read, 
				void function(char[] file_name) on_update, 
				void function(char[] file_name) on_delete) {

	_on_create = on_create;
	_on_read = on_read;
	_on_update = on_update;
	_on_delete = on_delete;

	c_fs_watch(toStringz(path_name), 
				&wrap_on_create, 
				&wrap_on_read, 
				&wrap_on_update, 
				&wrap_on_delete);
}

void wrap_on_create(char* file_name) {
	_on_create(fromStringz(file_name));
}

void wrap_on_read(char* file_name) {
	_on_create(fromStringz(file_name));
}

void wrap_on_update(char* file_name) {
	_on_create(fromStringz(file_name));
}

void wrap_on_delete(char* file_name) {
	_on_create(fromStringz(file_name));
}

private:
extern (C):

void c_fs_watch(char* path_name, 
				void (*on_create)(char* file_name), 
				void (*on_read)(char* file_name), 
				void (*on_update)(char* file_name), 
				void (*on_delete)(char* file_name));

