

private import tango.sys.Environment;
private import tango.io.device.File;

int fcgi_accept() {
	return c_fcgi_accept();
}

void fcgi_printf(char[] message) {
	c_fcgi_printf(message.ptr);
}

bool fcgi_accept(out char[] request) {
	// Just return false on no connections
	if(c_fcgi_accept() < 0)
		return false;

	// Get the request data from the fcgi server
	// These are called Standard CGI environment variables
	char[] REQUEST_METHOD = Environment.get("REQUEST_METHOD");
	char[] REQUEST_URI = Environment.get("REQUEST_URI");
	char[] HTTP_USER_AGENT = Environment.get("HTTP_USER_AGENT");
	char[] HTTP_COOKIE = Environment.get("HTTP_COOKIE");
	char[] REMOTE_ADDR = Environment.get("REMOTE_ADDR");
	char[] HTTP_REFERER = Environment.get("HTTP_REFERER");
	char[] HTTP_HOST = Environment.get("HTTP_HOST");
	char[] CONTENT_LENGTH = Environment.get("CONTENT_LENGTH");
	char[] CONTENT_TYPE = Environment.get("CONTENT_TYPE");

	// Reconstruct the request
	request = REQUEST_METHOD ~ " " ~ REQUEST_URI ~ " HTTP/1.1\r\n";

	if(HTTP_HOST) request ~= "Host: " ~ HTTP_HOST ~ "\r\n";
	if(HTTP_USER_AGENT) request ~= "User-Agent: " ~ HTTP_USER_AGENT ~ "\r\n";
	if(HTTP_COOKIE) request ~= "Cookie: " ~ HTTP_COOKIE ~ "\r\n";
	if(REMOTE_ADDR) request ~= "Remove-Addr: " ~ REMOTE_ADDR ~ "\r\n";
	if(HTTP_REFERER) request ~= "Referer: " ~ HTTP_REFERER ~ "\r\n";
	if(CONTENT_TYPE) request ~= "Content-type: " ~ CONTENT_TYPE ~ "\r\n";
	if(CONTENT_LENGTH) request ~= "Content-Length: " ~ CONTENT_LENGTH ~ "\r\n";

	request ~= "\r\n";

	return true;
}

private:

extern (C):

int c_fcgi_accept();
void c_fcgi_printf(char* message);



