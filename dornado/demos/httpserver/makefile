
CORELIB=	-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a

all:
	ldc -g hello_httpserver.d ../../ioloop.d ../../iostream.d ../../httpserver.d ../../language_helper.d ../../helper.d ${CORELIB}

clean:
	rm hello_httpserver
	rm *.o
