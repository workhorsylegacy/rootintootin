
module db;

import tango.stdc.stringz;

void db_connect(char[] server, char[] user_name, char[] password, char[] database) {
	c_db_connect(toStringz(server), toStringz(user_name), toStringz(password), toStringz(database));
}

ulong db_insert_query_with_result_id(char[] query) {
	return c_db_insert_query_with_result_id(toStringz(query));
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
void c_db_update_query(char* query);
char*** c_db_query_with_result(char* query, int* row_len, int* col_len);
void c_free_db_query_with_result(char*** result, int row_len, int col_len);

