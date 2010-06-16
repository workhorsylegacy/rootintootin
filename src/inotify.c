/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


#include <sys/types.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/inotify.h>

#define BUFF_SIZE ((sizeof(struct inotify_event)+FILENAME_MAX)*1024)

typedef enum {
	file_status_access, 
	file_status_modify, 
	file_status_attrib, 
	file_status_close_write, 
	file_status_close_nowrite, 
	file_status_open, 
	file_status_moved_from, 
	file_status_moved_to, 
	file_status_create, 
	file_status_delete, 
	file_status_delete_self, 
	file_status_move_self
} FileStatus;

typedef struct {
	char* name;
	FileStatus status;
} FileChange;

char* c_to_s(FileStatus status) {
	switch(status) {
		case(file_status_access): return "file_status_access";
		case(file_status_modify): return "file_status_modify";
		case(file_status_attrib): return "file_status_attrib";
		case(file_status_close_write): return "file_status_close_write";
		case(file_status_close_nowrite): return "file_status_close_nowrite";
		case(file_status_open): return "file_status_open";
		case(file_status_moved_from): return "file_status_moved_from";
		case(file_status_moved_to): return "file_status_moved_to";
		case(file_status_create): return "file_status_create";
		case(file_status_delete): return "file_status_delete";
		case(file_status_delete_self): return "file_status_delete_self";
		case(file_status_move_self): return "file_status_move_self";
		default: return NULL;
	}
}

FileChange* c_fs_watch(char* path_name, size_t* out_len) {
	FileChange* retval;
	int fd = inotify_init();
	/*int wd = */inotify_add_watch(fd, path_name, IN_ALL_EVENTS);

	// Read the new file changes
	char buff[BUFF_SIZE] = {0};
	ssize_t len = read(fd, buff, BUFF_SIZE);

	// Allocate enough memory to hold all the changes
	size_t length = 0;
	ssize_t i = 0;
	while(i < len) {
		struct inotify_event* event = (struct inotify_event*)&buff[i];
		i += sizeof(struct inotify_event) + event->len;
		length++;
	}
	retval = (FileChange*) calloc(length, sizeof(FileChange));

	// Get all the file changes
	i = 0;
	while(i < len) {
		struct inotify_event* event = (struct inotify_event*)&buff[i];

		if(event->len == 0 || strlen(event->name) == 0) {
			char* unknown = "unknown";
			retval[i].name = (char*) calloc(strlen(unknown)+1, sizeof(char));
			strcpy(retval[i].name, unknown);
		} else {
			retval[i].name = (char*) calloc(strlen(event->name)+1, sizeof(char));
			strcpy(retval[i].name, event->name);
		}

		if(IN_ACCESS & event->mask) {
			retval[i].status = file_status_access;
		} else if(IN_MODIFY & event->mask) {
			retval[i].status = file_status_modify;
		} else if(IN_ATTRIB & event->mask) {
			retval[i].status = file_status_attrib;
		} else if(IN_CLOSE_WRITE & event->mask) {
			retval[i].status = file_status_close_write;
		} else if(IN_CLOSE_NOWRITE & event->mask) {
			retval[i].status = file_status_close_nowrite;
		} else if(IN_OPEN & event->mask) {
			retval[i].status = file_status_open;
		} else if(IN_MOVED_FROM & event->mask) {
			retval[i].status = file_status_moved_from;
		} else if(IN_MOVED_TO & event->mask) {
			retval[i].status = file_status_moved_to;
		} else if(IN_CREATE & event->mask) {
			retval[i].status = file_status_create;
		} else if(IN_DELETE & event->mask) {
			retval[i].status = file_status_delete;
		} else if(IN_DELETE_SELF & event->mask) {
			retval[i].status = file_status_delete_self;
		} else if(IN_MOVE_SELF & event->mask) {
			retval[i].status = file_status_move_self;
		}

		i += sizeof(struct inotify_event) + event->len;
	}

	*out_len = length;
	return retval;
}


