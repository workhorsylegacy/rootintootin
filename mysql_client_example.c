

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

char** thing_query(char* query_sql) {
	char** retval;

	mysql_real_query(&mysql, query_sql, (unsigned int)strlen(query_sql));
	res = mysql_store_result(&mysql);

	int row_count = mysql_num_rows(res);
	retval = (char **) calloc (row_count, sizeof (char *));

	unsigned int n = 0;
	while(row = mysql_fetch_row(res)) {
		//printf("%s %sn", row[0], row[1]);
		unsigned int column_count = mysql_num_fields(res);
		retval[n] = "poop";
		printf("blah: %d\n", n);
		//unsigned long* column_lengths = mysql_fetch_lengths(res);
		n++;
	}

	mysql_free_result(res);

	return retval;
}

int main() {
	thing_connect("localhost", "root", "letmein", "me_love_movies_development");

	char* query_sql = "select id, name from titles limit 30;";

	int n = 1;
	while(n > 0) {
		thing_query(query_sql);
		n--;
	}

	return 0; 
}


