/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/



private import tango.stdc.stringz;


public enum QueryResult { 
	unknown, 
	success, 
	foreign_key_constraint_error, 
	not_unique_error
}

public class Db {
	private static MysqlAddress _address;

	public static char[] get_error_message() {
		return fromStringz(c_db_get_error_message());
	}

	public static void connect(char[] server, char[] user_name, char[] password, char[] database) {
		_address = c_db_connect(toStringz(server), toStringz(user_name), toStringz(password), toStringz(database));
	}

	public static ulong insert_query_with_result_id(char[] query, out QueryResult result) {
		return c_db_insert_query_with_result_id(_address, toStringz(query), &result);
	}

	public static void delete_query(char[] query, out QueryResult result) {
		c_db_delete_query(_address, toStringz(query), &result);
	}

	public static void update_query(char[] query, out QueryResult result) {
		c_db_update_query(_address, toStringz(query), &result);
	}

	public static char*** query_with_result(char[] query, out int row_len, out int col_len) {
		return c_db_query_with_result(_address, toStringz(query), &row_len, &col_len);
	}

	public static void free_query_with_result(char*** result, int row_len, int col_len) {
		c_free_db_query_with_result(result, row_len, col_len);
	}
}

private:

extern (C):

alias size_t MysqlAddress;

char* c_db_get_error_message();
MysqlAddress c_db_connect(char* server, char* user_name, char* password, char* database);

ulong c_db_insert_query_with_result_id(MysqlAddress address, char* query, QueryResult* result);
void c_db_delete_query(MysqlAddress address, char* query, QueryResult* result);
void c_db_update_query(MysqlAddress address, char* query, QueryResult* result);

char*** c_db_query_with_result(MysqlAddress address, char* query, int* row_len, int* col_len);
void c_free_db_query_with_result(char*** result, int row_len, int col_len);

