
module db;

import tango.stdc.stringz;


enum query_result { 
	unknown, 
	success, 
	foreign_key_constraint_failed
}

void db_init(size_t connection_count) {
	c_db_init(connection_count);
}

void db_connect(size_t connection, char[] server, char[] user_name, char[] password, char[] database) {
	c_db_connect(connection, toStringz(server), toStringz(user_name), toStringz(password), toStringz(database));
}

ulong db_insert_query_with_result_id(size_t connection, char[] query) {
	return c_db_insert_query_with_result_id(connection, toStringz(query));
}

void db_delete_query(size_t connection, char[] query, out query_result result) {
	c_db_delete_query(connection, toStringz(query), &result);
}

void db_update_query(size_t connection, char[] query) {
	c_db_update_query(connection, toStringz(query));
}

char*** db_query_with_result(size_t connection, char[] query, out int row_len, out int col_len) {
	return c_db_query_with_result(connection, toStringz(query), &row_len, &col_len);
}

void free_db_query_with_result(char*** result, int row_len, int col_len) {
	c_free_db_query_with_result(result, row_len, col_len);
}

private:

extern (C):

void c_db_init(size_t connection_count);
void c_db_connect(size_t connection, char* server, char* user_name, char* password, char* database);

ulong c_db_insert_query_with_result_id(size_t connection, char* query);
void c_db_delete_query(size_t connection, char* query, query_result *result);
void c_db_update_query(size_t connection, char* query);

char*** c_db_query_with_result(size_t connection, char* query, int* row_len, int* col_len);
void c_free_db_query_with_result(char*** result, int row_len, int col_len);

