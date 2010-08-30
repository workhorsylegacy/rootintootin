
CORELIB=	-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a

all:
	gcc -g -c -Wall -Werror fcgi.c -o fcgi.o -lfcgi
	ar rcs clibs.a fcgi.o
	ldc -g -w helloweb.d fcgi.d language_helper.d -L clibs.a -L="-lfcgi" ${CORELIB}

	sudo rm /var/fastcgi/helloweb
	sudo cp helloweb /var/fastcgi/helloweb
	sudo rm /var/log/lighttpd/error.log
	sudo rm /var/log/lighttpd/access.log
	sudo /etc/init.d/lighttpd force-reload

clean:
	rm *.o
	rm *.a
	rm helloweb

