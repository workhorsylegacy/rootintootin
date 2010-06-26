/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


module file_system;
private import tango.io.Stdout;
private import tango.stdc.stringz;
private import tango.stdc.time;

enum EntryType { 
	unknown = 0, 
	file = 1, 
	dir = 2
}

bool is_file_newer(char[] a_path, char[] a, char[] b_path, char[] b) {
	time_t ta = file_modify_time(a_path, a);
	time_t tb = file_modify_time(b_path, b);

	return ta > tb;
}

time_t file_modify_time(char[] path, char[] file_name) {
	if(!file_exist(path, file_name)) {
		//Stdout("The file '" ~ path ~ file_name ~ "' does not exist.").newline.flush;
		throw new Exception("The file '" ~ path ~ file_name ~ "' does not exist.");
	}

	if(path == ".")
		path = "";

	return c_file_modify_time(toStringz(path ~ file_name));
}

char[][] dir_entries(char[] dir_name, EntryType type) {
	// Get the entries in C strings
	int len = 0;
	char** c_entries;
	c_entries = c_dir_entries(toStringz(dir_name), &len, type);

	// Convert the C strings to D strings
	char[][] d_entries;
	for(int i=0; i<len; i++) {
		d_entries ~= fromStringz(c_entries[i]).dup;
	}

	// Free the C strings, and return the D strings
	c_free_dir_entries(c_entries, len);
	return d_entries;
}

bool file_exist(char[] path, char[] file_name) {
	return exist(path, file_name, EntryType.file);
}

bool dir_exist(char[] path, char[] dir_name) {
	return exist(path, dir_name, EntryType.dir);
}

bool exist(char[] path, char[] name, EntryType type) {
	foreach(char[] n; dir_entries(path, type)) {
		if(n == name)
			return true;
	}

	return false;
}

private:

extern (C):

time_t c_file_modify_time(char* file_name);
char** c_dir_entries(char* dir_name, int* len, EntryType type);
void c_free_dir_entries(char** entries, int len);

