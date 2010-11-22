



private import fcgi;
private import db;
private import language_helper;


int main(char[][] args) {
	char[] request;

	Db.connect("mattjonesdb.workhorsy.org", "bloguser", "password", "mattjonesdb");

	while(fcgi_accept(request)) {
		fcgi_printf("Content-Type: text/plain\r\n\r\n");
		fcgi_printf("Hello World Wide Web\n");

		int row_len, col_len;
		char[] query = "select post_title from wp_posts;";
		char*** result = Db.query_with_result(query, row_len, col_len);
		for(int i=0; i<row_len; i++) {
			fcgi_printf("post_title: " ~ tango.stdc.stringz.fromStringz(result[i][0]) ~ "\n");
		}
		Db.free_query_with_result(result, row_len, col_len);

		fcgi_printf("request: " ~ request ~ "\n");
	}

	return 0;
}

