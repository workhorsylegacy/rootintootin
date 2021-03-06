/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


module shared_memory;
private import dlang_helper;
private import tango.stdc.stringz;


public class SharedMemory {
	private int _shmid;
	private char* _segptr;
	private size_t _buffer_size;

	public this(char[] name, size_t buffer_size = 1024*256) {
		_buffer_size = buffer_size;

		if(buffer_size < 100)
			throw new Exception("Failed to create shared memory. The min size of the buffer is 100.");

		// Get the key
		int key = c_create_key(toStringz(name));
		if(key == -1)
			throw new Exception("Failed to create shared memory key. The name may not be an existing path, or may be invalid.");

		// Open the shm
		_shmid = c_shm_open(key, _buffer_size);
		if(_shmid == -1)
			throw new Exception("Failed to open shared memory.");

		// Attach the shm
		_segptr = c_shm_attach(_shmid);
		if(_segptr == cast(char*)-1)
			throw new Exception("Failed to attach the shared memory to the current process.");
	}

	public void set_value(char* value, size_t len) {
		// Make sure the length isn't bigger than the buffer
		if(len > _buffer_size) {
			throw new Exception("Shared memory error: The message is " ~ to_s(len) ~ " bytes long, but the max size is " ~ to_s(_buffer_size) ~ ".");
		}

		c_shm_set_value(_shmid, _segptr, value, len);
	}

	public char* get_value() {
		return c_shm_get_value(_shmid, _segptr);
	}

	//public void close() {
	//	c_shm_close(_shm_fd);
	//}

	public void destroy() {
		c_shm_delete(_shmid);
	}
}

private:

extern (C):

int c_create_key(char* name);
int c_shm_open(int key, size_t buffer_size);
char* c_shm_attach(int shmid);
void c_shm_set_value(int shmid, char* segptr, char* text, size_t len);
char* c_shm_get_value(int shmid, char* segptr);
void c_shm_delete(int shmid);

