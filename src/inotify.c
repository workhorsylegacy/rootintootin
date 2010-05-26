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
#include <sys/inotify.h>

#define BUFF_SIZE ((sizeof(struct inotify_event)+FILENAME_MAX)*1024)

void c_fs_watch(char* path_name, 
				void (*on_create)(char* file_name), 
				void (*on_read)(char* file_name), 
				void (*on_update)(char* file_name), 
				void (*on_delete)(char* file_name)) {
	int fd = inotify_init();
	int wd = inotify_add_watch(fd, path_name, IN_ALL_EVENTS);

	while(true) {
		char buff[BUFF_SIZE] = {0};

		ssize_t i = 0;
		while(i < read(fd, buff, BUFF_SIZE)) {
			struct inotify_event* event = (struct inotify_event*)&buff[i];

			if(event->len == 0) {
				// Skip empty ones
			} else if(IN_ACCESS & event->mask) {
				on_read(event->name);
			} else if(IN_MODIFY & event->mask) {
				on_update(event->name);
			} else if(IN_ATTRIB & event->mask) {
				on_update(event->name);
			} else if(IN_CLOSE_WRITE & event->mask) {
				on_update(event->name);
			} else if(IN_CLOSE_NOWRITE & event->mask) {
				on_update(event->name);
			} else if(IN_OPEN & event->mask) {
				on_update(event->name);
			} else if(IN_MOVED_FROM & event->mask) {
				on_delete(event->name);
			} else if(IN_MOVED_TO & event->mask) {
				on_create(event->name);
			} else if(IN_CREATE & event->mask) {
				on_create(event->name);
			} else if(IN_DELETE & event->mask) {
				on_delete(event->name);
			} else if(IN_DELETE_SELF & event->mask) {
				on_delete(event->name);
			} else if(IN_MOVE_SELF & event->mask) {
				on_create(event->name);
			}

			i += sizeof(struct inotify_event) + event->len;
		}
	}
}

void on_create(char* file_name) {
	printf("create: %s\n", file_name);
}

void on_read(char* file_name) {
	printf("read: %s\n", file_name);
}

void on_update(char* file_name) {
	printf("update: %s\n", file_name);
}

void on_delete(char* file_name) {
	printf("delete: %s\n", file_name);
}

int main() {

	c_fs_watch("/home/matt", on_create, on_read, on_update, on_delete);

	return 0;
}
