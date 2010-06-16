
//#include <stdbool.h>
#include <sys/shm.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


int c_shm_open(char* name, size_t buffer_size) {
	key_t key = ftok(name, 'S');

	// Create a new memory block
	int shmid = shmget(key, buffer_size, IPC_CREAT | IPC_EXCL | 0666);
	if(shmid != -1) {
		return shmid;
	}

	// If that failed, use the existing memory block
	shmid = shmget(key, buffer_size, 0);
	if(shmid == -1) {
		perror("shmget");
		exit(1);
	}

	return shmid;
}

// Attach the memory block to the process
char* c_shm_attach(int shmid) {
	char* segptr = (char*)shmat(shmid, 0, 0);
	if(segptr == (char*)-1) {
		perror("shmat");
		exit(1);
	}

	return segptr;
}

void c_shm_set_value(int shmid, char* segptr, char* text) {
	strcpy(segptr, text);
}

char* c_shm_get_value(int shmid, char* segptr) {
	return segptr;
}

void c_shm_delete(int shmid) {
	shmctl(shmid, IPC_RMID, 0);
}


