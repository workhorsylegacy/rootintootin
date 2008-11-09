

// clear; gcc mysql_client_example.c -o mysql_client_example -lz -lmysqlclient -L /usr/lib/mysql/

#include <mysql/mysql.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

MYSQL mysql;
MYSQL_RES *res;
MYSQL_ROW row;

void thing_connect(char* server, char* user_name, char* password, char* database) {
	mysql_init(&mysql);
	mysql_real_connect(&mysql,
					server, 
					user_name, password, 
					database, 
					0, NULL, 0);
}

// Runs the query and restuns it as a 3D array of characters
char*** thing_query(char* query_sql) {
	char*** retval;

	// Run the query and get the result
	mysql_real_query(&mysql, query_sql, (unsigned int)strlen(query_sql));
	res = mysql_store_result(&mysql);

	// Allocated enough memory to hold the pointers for each row into the return value
	int row_count = mysql_num_rows(res);
	retval = (char ***) calloc(row_count, sizeof (char **));

	// Iterate through each row
	unsigned int row_cur = 0;
	while(row = mysql_fetch_row(res)) {
		// Allocated enough memory to hold the pointers for each column into the return value
		unsigned int col_count = mysql_num_fields(res);
		retval[row_cur] = (char **) calloc(col_count, sizeof (char *));

		// Copy each row into the return calue
		int i = 0;
		for(i=0; i<col_count; i++) {
			retval[row_cur][i] = (char *) calloc(strlen(row[i])+1, sizeof(char));
			strcpy(retval[row_cur][i], row[i]);
			printf("row: %s\n", row[i]);
		}

		row_cur++;
	}

	// Free the resources for the result
	mysql_free_result(res);

	// Return the result
	return retval;
}

int main() {
	thing_connect("localhost", "root", "letmein", "me_love_movies_development");

	char* query_sql = "select id, name from titles order by id limit 30;";

	int n = 10000;
	while(n > 0) {
		char*** result = thing_query(query_sql);
		
		// Free all the memory for the strings
		// FIXME: This needs to free the all the child strings too
		free(result);

		n--;
	}

	return 0; 
}


