

/*
#setup fcgi on ubuntu:

sudo apt-get install lighttpd php5-cgi
sudo lighty-enable-mod fastcgi 
sudo /etc/init.d/lighttpd force-reload

# change the port in /etc/lighttpd/lighttpd.conf :
server.port               = 90

# change /etc/lighttpd/conf-available/10-fastcgi.conf :
fastcgi.server = ( "/" => 
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
	char[] request;

	while(fcgi_accept(request)) {
		fcgi_printf("Content-Type: text/html\r\n\r\n");
		fcgi_printf("<html><h1>Boooo!</h1></html>\n");
	}

	return 0;
}

