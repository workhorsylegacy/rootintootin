
CORELIB=	-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a

all:
	ldc -g hello_ioloop.d ../../ioloop.d ../../language_helper.d ${CORELIB}

clean:
	rm *.o
	rm *.a
	rm hello_ioloop

