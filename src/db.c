


#include <mysql/mysql.h>
#include <mysql/errmsg.h>
#include <mysql/mysqld_error.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>


MYSQL* mysqls = NULL;

enum query_result { 
	query_result_unknown, 
	query_result_success, 
	query_result_foreign_key_constraint_failed
};


void c_db_init(size_t connection_count) {
	mysqls = calloc(connection_count, sizeof(MYSQL));
}

void c_db_connect(size_t connection, char* server, char* user_name, char* password, char* database) {
	mysql_init(&mysqls[connection]);
	mysql_real_connect(&mysqls[connection],
					server, 
					user_name, password, 
					database, 
					0, NULL, 0);
}

// Runs the query and returns the id of the last inserted row
unsigned long long c_db_insert_query_with_result_id(size_t connection, char* query) {
	MYSQL_RES *res;
	unsigned long long id = -1;

	// Run the query and get the result
	mysql_real_query(&mysqls[connection], query, (unsigned int)strlen(query));
	res = mysql_store_result(&mysqls[connection]);

	// Return the id of the last inserted row
	id = mysql_insert_id(&mysqls[connection]);

	// Free the resources for the result
	mysql_free_result(res);

	return id;
}

void c_db_delete_query(size_t connection, char* query, enum query_result *result) {
	MYSQL_RES *res;
	*result = query_result_unknown;

	// Run the query and get the result
	int status = mysql_real_query(&mysqls[connection], query, (unsigned int)strlen(query));
	if(status == 0) {
		*result = query_result_success;
	} else if(status != 0 && mysql_errno(&mysqls[connection]) == ER_ROW_IS_REFERENCED_2) {
		printf("errno: %d\n", ER_ROW_IS_REFERENCED_2);
		fflush(stdout);
		*result = query_result_foreign_key_constraint_failed;
	}
	res = mysql_store_result(&mysqls[connection]);

	// Free the resources for the result
	mysql_free_result(res);
}

// Runs the query and returns nothing
void c_db_update_query(size_t connection, char* query) {
	MYSQL_RES *res;

	// Run the query and get the result
	mysql_real_query(&mysqls[connection], query, (unsigned int)strlen(query));
	res = mysql_store_result(&mysqls[connection]);

	// Free the resources for the result
	mysql_free_result(res);
}

// Runs the query and returns it as a 3D array of characters
char*** c_db_query_with_result(size_t connection, char* query, int* row_len, int* col_len) {
	MYSQL_RES *res;
	char*** retval;

	// Run the query and get the result
	mysql_real_query(&mysqls[connection], query, (unsigned int)strlen(query));
	res = mysql_store_result(&mysqls[connection]);

	// Allocate enough memory to hold the pointers for each row in the return value
	int col_count = 0;
	int row_count = mysql_num_rows(res);
	retval = (char ***) calloc(row_count, sizeof (char **));

	// Iterate through each row
	MYSQL_ROW row;
	unsigned int row_cur = 0;
	while((row = mysql_fetch_row(res))) {
		// Allocate enough memory to hold the pointers for each column in the return value
		col_count = mysql_num_fields(res);
		retval[row_cur] = (char **) calloc(col_count, sizeof (char *));

		// Copy each field into the column of the return value
		int i = 0;
		for(i=0; i<col_count; i++) {
			// If the field is null, just make the value null too
			if(row[i] == NULL) {
				retval[row_cur][i] = NULL;
			} else {
				// Otherwise copy the field as a string
				retval[row_cur][i] = (char *) calloc(strlen(row[i])+1, sizeof(char));
				strcpy(retval[row_cur][i], row[i]);
			}
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

void c_free_db_query_with_result(char*** result, int row_len, int col_len) {
	int i, j;
	for(i=0; i < row_len; i++) {
		for(j=0; j < col_len; j++) {
			// Free the memory for each field
			free(result[i][j]);
		}
		// Free the memory for each row
		free(result[i]);
	}
	// Free the memory for the result
	free(result);
}


