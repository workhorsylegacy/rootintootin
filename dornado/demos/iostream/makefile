
CORELIB=	-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a

all:
	ldc -g hello_iostream.d ../../ioloop.d ../../iostream.d ../../language_helper.d ${CORELIB}

clean:
	rm hello_iostream
	rm *.o
