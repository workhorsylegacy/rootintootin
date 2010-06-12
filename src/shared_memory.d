/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


module shared_memory;
private import language_helper;
private import tango.stdc.stringz;

public class SharedMemory {
	private int _shm_fd;
	private char* _buffer;
	private int _buffer_size;

	public this(char[] name, int buffer_size = 1024) {
		_buffer_size = buffer_size;
		_buffer = toStringz(new char[_buffer_size]);
		bool is_first = false;
		_shm_fd = c_shm_create(toStringz(name), &is_first, _buffer);
	}

	void set_value(char* value) {
		size_t len = strlenz(value);
		if(len > _buffer_size) {
			throw new Exception("The string with the length of " ~ to_s(len) ~ " is too big for the buffer with the length of " ~ to_s(_buffer_size) ~ ".");
		}

		c_shm_set_value(_shm_fd, value, _buffer);
	}

	char* get_value() {
		return c_shm_get_value(_shm_fd, _buffer);
	}

	void close() {
		c_shm_close(_shm_fd);
	}

	void destroy(char[] value) {
		c_shm_delete(toStringz(value));
	}
}

private:

extern (C):

int c_shm_create(char* name, bool* is_first, char* buffer);
void c_shm_set_value(int shm_fd, char* value, char* buffer);
char* c_shm_get_value(int shm_fd, char* buffer);
void c_shm_close(int shm_fd);
void c_shm_delete(char* value);

