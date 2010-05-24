
CORELIB=	-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a

all:
	gcc -g -c ../src/db.c -o db.o
	ar rcs db.a db.o
	ldc -g main.d ../src/tcp_server.d ../src/http_server.d ../dornado/ioloop.d ../src/language_helper.d ../src/helper.d ${CORELIB}
	#ldc -g -of run language_helper.d helper.d rootintootin.d rootintootin_server.d http_server.d tcp_server.d ui.d run.d db.d db.a -L="-lmysqlclient"

clean:
	rm main
	rm *.a
	rm *.o
