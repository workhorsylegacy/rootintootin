
CORELIB=	-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a

all:
	#gcc -g -c regex.c -o regex.o
	#ar rcs regex.a regex.o
	#ldc -g -of main main.d regex.a regex.d ${CORELIB}
	gcc -g -Wall -Werror -o main main.c -lpcre

clean:
	rm *.o


