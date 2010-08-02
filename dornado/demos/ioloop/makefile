
CORELIB=	-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a

all:
	gcc -g -c -Wall -Werror socket.c -o socket.o
	ar rcs socket.a socket.o
	gcc -g -Wall -Werror -o app app.c -L socket.a
	ldc -g hello_ioloop.d ../../ioloop.d ../../language_helper.d socket.d -L socket.a ${CORELIB}

clean:
	rm *.o
	rm *.a
	rm hello_ioloop
	rm app
	rm socket

