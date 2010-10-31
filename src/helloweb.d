



private import fcgi;


int main(char[][] args) {
	char[] request;

	while(fcgi_accept(request)) {
		fcgi_printf("Content-Type: text/plain\r\n\r\n");
		fcgi_printf("Hello World Wide Web\n");
		fcgi_printf("request: " ~ request ~ "\n");
	}

	return 0;
}

