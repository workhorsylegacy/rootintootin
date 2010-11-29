
CORELIB=	-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a

all: clean
	gcc -g -c -Wall -Werror fcgi.c -o fcgi.o -Wl,-static -lfcgi
	gcc -g -c -Wall -Werror db.c -o db.o -Wl,-static -lmysqlclient
	ar rcs clibs.a fcgi.o db.o
	ldc -g -w helloweb.d language_helper.d fcgi.d db.d \
	-L clibs.a \
	-L"-lz" \
	-L="/usr/lib/libfcgi.a" \
	-L="/usr/lib/libmysqlclient.a" \
	${CORELIB}

clean:
	rm -f *.o
	rm -f *.a
	rm -f helloweb

