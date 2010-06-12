/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


#include <fcntl.h>
#include <sys/stat.h>
#include <stdbool.h>
#include <errno.h>
#include <sys/mman.h>
#include <sys/types.h> //shm_open
#include <stdio.h>	//printf
#include <stdlib.h> //exit
#include <unistd.h> //close
#include <string.h> //strerror


int c_shm_create(char* name, bool* is_first, char* buffer) {
	*is_first = false;
	int shm_fd = 0;

	// Try to open the shm instance with O_EXCL,
	// this tests if the shm is already opened by someone else
	if((shm_fd = shm_open(name, 
			(O_CREAT | O_RDWR | O_EXCL),
			(S_IREAD | S_IWRITE))) > 0 ) {
		*is_first = true;
	// Try to open the shm instance normally and share it with
	// existing clients
	} else if((shm_fd = shm_open(name, 
			(O_CREAT | O_RDWR),
			(S_IREAD | S_IWRITE))) < 0) {
		//printf("Could not create shm object. %s\n", strerror(errno));
		//return errno;
	}

	// Set the size of the SHM to be the size of the buffer
	ftruncate(shm_fd, sizeof(char) * strlen(buffer));

	// Connect the value pointer to set to the shared memory area,
	// with desired permissions
	if((buffer = mmap(0, sizeof(char) * strlen(buffer), (PROT_READ | PROT_WRITE),
				MAP_SHARED, shm_fd, 0)) == MAP_FAILED) {
		//return errno;
	}

	return shm_fd;
}

void c_shm_set_value(int shm_fd, char* value, char* buffer) {
	strcpy(buffer, value);
}

char* c_shm_get_value(int shm_fd, char* buffer) {
	return buffer;
}

void c_shm_close(int shm_fd) {
	close(shm_fd);
}

void c_shm_delete(char* value) {
	shm_unlink(value);
}


