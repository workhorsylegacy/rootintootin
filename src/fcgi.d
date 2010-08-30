

private import tango.sys.Environment;
private import tango.io.device.File;

int fcgi_accept() {
	return c_fcgi_accept();
}

void printf(char[] message) {
	c_printf(message.ptr);
}

bool fcgi_accept(out char[] agent, out char[] cookie, out char[] method, out char[] path) {
	if(c_fcgi_accept() >= 0) {
		agent = Environment.get("HTTP_USER_AGENT", "");
		cookie = Environment.get("HTTP_COOKIE", "");
		method = Environment.get("REQUEST_METHOD", "");
		path = Environment.get("PATH_INFO", "");

		/*
		REMOTE_ADDR
		REMOTE_HOST
		REMOTE_ADDR

		PATH_INFO
		CONTENT_LENGTH
		CONTENT_TYPE
		*/
		//++count;
		return true;
	} else {
		return false;
	}
}

private:

extern (C):

int c_fcgi_accept();
void c_printf(char* message);



