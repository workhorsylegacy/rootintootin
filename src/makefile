
CORELIB=	-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a

all: clean
	gcc -g -c -Wall -Werror fcgi.c  -o fcgi.o  -Wl,-static -lfcgi
	ar rcs clibs.a fcgi.o
	ldc -g -w helloweb.d language_helper.d fcgi.d -L clibs.a \
	-L"-lz" -L="/usr/lib/libfcgi.a" ${CORELIB}

	sudo rm -f /home/matt/fastcgi/application
	sudo cp helloweb /home/matt/fastcgi/application
	sudo rm -f /var/log/lighttpd/error.log
	sudo rm -f /var/log/lighttpd/access.log
	sudo /etc/init.d/lighttpd force-reload
	@echo "View the site at: http://127.0.0.1:90"

clean:
	rm -f *.o
	rm -f *.a
	rm -f helloweb

