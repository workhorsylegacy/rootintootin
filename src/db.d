/*-------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 2 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


module db;
private import tango.stdc.stringz;


enum query_result { 
	unknown, 
	success, 
	foreign_key_constraint_failed
}

void db_connect(char[] server, char[] user_name, char[] password, char[] database) {
	c_db_connect(toStringz(server), toStringz(user_name), toStringz(password), toStringz(database));
}

ulong db_insert_query_with_result_id(char[] query) {
	return c_db_insert_query_with_result_id(toStringz(query));
}

void db_delete_query(char[] query, out query_result result) {
	c_db_delete_query(toStringz(query), &result);
}

void db_update_query(char[] query) {
	c_db_update_query(toStringz(query));
}

char*** db_query_with_result(char[] query, out int row_len, out int col_len) {
	return c_db_query_with_result(toStringz(query), &row_len, &col_len);
}

void free_db_query_with_result(char*** result, int row_len, int col_len) {
	c_free_db_query_with_result(result, row_len, col_len);
}

private:

extern (C):

void c_db_connect(char* server, char* user_name, char* password, char* database);

ulong c_db_insert_query_with_result_id(char* query);
void c_db_delete_query(char* query, query_result *result);
void c_db_update_query(char* query);

char*** c_db_query_with_result(char* query, int* row_len, int* col_len);
void c_free_db_query_with_result(char*** result, int row_len, int col_len);

