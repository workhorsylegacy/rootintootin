/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


//#include <stdbool.h>
#include <sys/shm.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


int c_create_key(char* name) {
	key_t r = ftok(name, 1);
	return (int)r;
}

int c_shm_open(int key, size_t buffer_size) {
	key_t k = (key_t)key;

	// Create a new memory block
	int shmid = shmget(k, buffer_size, 0777 | IPC_CREAT);
	if(shmid != -1) {
		return shmid;
	}

	// If that failed, use the existing memory block
	shmid = shmget(k, buffer_size, 0);
	if(shmid == -1) {
//		perror("shmget");
//		exit(1);
	}

	return shmid;
}

// Attach the memory block to the process
char* c_shm_attach(int shmid) {
	char* segptr = (char*)shmat(shmid, 0, 0);
	if(segptr == (char*)-1) {
//		perror("shmat");
//		exit(1);
	}

	return segptr;
}

void c_shm_set_value(int shmid, char* segptr, char* text, size_t len) {
	memcpy(segptr, text, len);
}

char* c_shm_get_value(int shmid, char* segptr) {
	return segptr;
}

void c_shm_delete(int shmid) {
	shmctl(shmid, IPC_RMID, 0);
}


