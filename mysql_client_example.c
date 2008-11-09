

// clear; gcc mysql_client_example.c -o mysql_client_example -lz -lmysqlclient -L /usr/lib/mysql/

#include <mysql/mysql.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

MYSQL mysql;
MYSQL_RES *res;
MYSQL_ROW row;

void db_connect(char* server, char* user_name, char* password, char* database) {
	mysql_init(&mysql);
	mysql_real_connect(&mysql,
					server, 
					user_name, password, 
					database, 
					0, NULL, 0);
}

// Runs the query and returns it as a 3D array of characters
char*** db_query(char* query, int* row_len, int* col_len) {
	char*** retval;

	// Run the query and get the result
	mysql_real_query(&mysql, query, (unsigned int)strlen(query));
	res = mysql_store_result(&mysql);

	// Allocate enough memory to hold the pointers for each row in the return value
	int col_count = 0;
	int row_count = mysql_num_rows(res);
	retval = (char ***) calloc(row_count, sizeof (char **));

	// Iterate through each row
	unsigned int row_cur = 0;
	while(row = mysql_fetch_row(res)) {
		// Allocate enough memory to hold the pointers for each column in the return value
		col_count = mysql_num_fields(res);
		retval[row_cur] = (char **) calloc(col_count, sizeof (char *));

		// Copy each field into the column of the return value
		int i = 0;
		for(i=0; i<col_count; i++) {
			retval[row_cur][i] = (char *) calloc(strlen(row[i])+1, sizeof(char));
			strcpy(retval[row_cur][i], row[i]);
		}

		row_cur++;
	}

	// Free the resources for the result
	mysql_free_result(res);

	// Return the result, number of rows, and columns
	*row_len = row_count;
	*col_len = col_count;
	return retval;
}

// FIXME: This does not seem to free all of the resources
void free_db_query(char*** result, int row_len, int col_len) {
	int i, j;
	for(i=0; i < row_len; i++) {
		for(j=0; j < col_len; j++) {
			free(result[i][j]);
		}
		result[i];
	}
	free(result);
}

int main() {
	db_connect("localhost", "root", "letmein", "me_love_movies_development");

	char* query = "select id, name from titles order by id limit 30;";

	int n = 1;
	while(n > 0) {
		int row_len, col_len;
		char*** result = db_query(query, &row_len, &col_len);

		int i, j;
		for(i=0; i<row_len; i++) {
			for(j=0; j<col_len; j++) {
				printf("%s\n", result[i][j]);
			}
		}
		
		free_db_query(result, row_len, col_len);

		n--;
	}

	return 0; 
}


