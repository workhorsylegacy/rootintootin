/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


#include <mysql/mysql.h>
#include <mysql/errmsg.h>
#include <mysql/mysqld_error.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>


char* error_message;

typedef size_t MysqlAddress;

typedef enum { 
	query_result_unknown, 
	query_result_success, 
	query_result_foreign_key_constraint_error, 
	query_result_not_unique_error
} QueryResult;

char* c_db_get_error_message() {
	return error_message;
}

MysqlAddress c_db_connect(char* server, char* user_name, char* password, char* database) {
	MysqlAddress address = 0;

	MYSQL* mysql = calloc(1, sizeof(MYSQL*));
	mysql_init(mysql);
	mysql_real_connect(mysql,
					server, 
					user_name, password, 
					database, 
					0, NULL, 0);

	address = (MysqlAddress) mysql;
	return address;
}

// Runs the query and returns the id of the last inserted row
unsigned long long c_db_insert_query_with_result_id(MysqlAddress address, char* query, QueryResult* result) {
	MYSQL* mysql = (MYSQL*) address;
	*result = query_result_unknown;
	error_message = NULL;
	unsigned long long id = -1;

	// Run the query and get the result
	mysql_real_query(mysql, query, (unsigned int)strlen(query));
	MYSQL_RES* res = mysql_store_result(mysql);

	// Return the id of the last inserted row
	id = mysql_insert_id(mysql);

	// Free the resources for the result
	mysql_free_result(res);

	// Check for duplicate error
	unsigned int errno = mysql_errno(mysql);
	if(errno == 0) {
		*result = query_result_success;
	} else if(errno == ER_DUP_ENTRY) {
		error_message = (char*) mysql_error(mysql);
		*result = query_result_not_unique_error;
	}

	return id;
}

void c_db_delete_query(MysqlAddress address, char* query, QueryResult* result) {
	MYSQL* mysql = (MYSQL*) address;
	*result = query_result_unknown;
	error_message = NULL;

	// Run the query and get the result
	int status = mysql_real_query(mysql, query, (unsigned int)strlen(query));
	if(status == 0) {
		*result = query_result_success;
	} else if(status != 0 && mysql_errno(mysql) == ER_ROW_IS_REFERENCED_2) {
		printf("errno: %d\n", ER_ROW_IS_REFERENCED_2);
		fflush(stdout);
		*result = query_result_foreign_key_constraint_error;
		error_message = (char*) mysql_error(mysql);
	}
	MYSQL_RES* res = mysql_store_result(mysql);

	// Free the resources for the result
	mysql_free_result(res);
}

// Runs the query and returns nothing
void c_db_update_query(MysqlAddress address, char* query, QueryResult* result) {
	MYSQL* mysql = (MYSQL*) address;
	*result = query_result_unknown;
	error_message = NULL;
	// Run the query and get the result
	mysql_real_query(mysql, query, (unsigned int)strlen(query));
	MYSQL_RES* res = mysql_store_result(mysql);

	// Free the resources for the result
	mysql_free_result(res);

	// Check for duplicate error
	unsigned int errno = mysql_errno(mysql);
	if(errno == 0) {
		*result = query_result_success;
	} else if(errno == ER_DUP_ENTRY) {
		*result = query_result_not_unique_error;
		error_message = (char*) mysql_error(mysql);
	}
}

// Runs the query and returns it as a 3D array of characters
char*** c_db_query_with_result(MysqlAddress address, char* query, int* row_len, int* col_len) {
	MYSQL* mysql = (MYSQL*) address;
	char*** retval;
	error_message = NULL;

	// Run the query and get the result
	mysql_real_query(mysql, query, (unsigned int)strlen(query));
	MYSQL_RES* res = mysql_store_result(mysql);

	// Allocate enough memory to hold the pointers for each row in the return value
	int col_count = 0;
	int row_count = mysql_num_rows(res);
	retval = (char***) calloc(row_count, sizeof(char**));

	// Iterate through each row
	MYSQL_ROW row;
	unsigned int row_cur = 0;
	while((row = mysql_fetch_row(res))) {
		// Allocate enough memory to hold the pointers for each column in the return value
		col_count = mysql_num_fields(res);
		retval[row_cur] = (char**) calloc(col_count, sizeof(char*));

		// Copy each field into the column of the return value
		int i = 0;
		for(i=0; i<col_count; i++) {
			// If the field is null, just make the value null too
			if(row[i] == NULL) {
				retval[row_cur][i] = NULL;
			} else {
				// Otherwise copy the field as a string
				retval[row_cur][i] = (char*) calloc(strlen(row[i])+1, sizeof(char));
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


