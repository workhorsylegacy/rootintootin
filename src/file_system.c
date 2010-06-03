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
#include <stdlib.h>
#include <dirent.h>


char** c_dir_entries(char* dir_name, int* len) {
	char** retval;
	DIR* dp;
	struct dirent* ep;
	dp = opendir(dir_name);

	// Print an error if we can't open the dir
	if(dp == NULL) {
		perror("Couldn't open the directory");
		return NULL;
	}

	// Count how many entries are in the directory
	int entry_count = 0;
	while(ep = readdir(dp)) {
		entry_count++;
	}
	rewinddir(dp);

	// Copy the entries to the retval
	retval = (char **) calloc(entry_count, sizeof(char *));
	int i = 0;
	while(ep = readdir(dp)) {
		retval[i] = (char *) calloc(strlen(ep->d_name)+1, sizeof(char));
		strcpy(retval[i], ep->d_name);
		i++;
	}

	closedir(dp);
	*len = entry_count;
	return retval;
}

void c_free_dir_entries(char** entries, int len) {
	int i = 0;
	for(i=0; i<len; i++) {
		free(entries[i]);
	}
	free(entries);
}


