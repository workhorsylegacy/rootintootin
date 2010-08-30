

/*
#setup fcgi on ubuntu:

sudo apt-get install lighttpd php5-cgi
sudo lighty-enable-mod fastcgi 
sudo /etc/init.d/lighttpd force-reload

# change the port in /etc/lighttpd/lighttpd.conf :
server.port               = 90

# change /etc/lighttpd/conf-available/10-fastcgi.conf :
fastcgi.server = ( "/fastcgi/helloweb" => 
	((
		"bin-path" => "/var/fastcgi/helloweb",
		"socket" => "/tmp/helloweb.socket",
		"check-local" => "disable"
	))
)

*/


private import tango.io.Stdout;
private import fcgi;
private import language_helper;


int main(char[][] args) {
	char[] agent, cookie, method, path;

	while(fcgi_accept(agent, cookie, method, path)) {
		printf("Content-Type: text/plain\r\n\r\n");
		printf("Hello World Wide Web\n");
		printf("agent: " ~ agent ~ "\n");
		printf("cookie: " ~ cookie ~ "\n");
		printf("method: " ~ method ~ "\n");
		printf("path: " ~ path ~ "\n");
	}

	return 0;
}

