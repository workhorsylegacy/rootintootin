
CORELIB=	-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a

all:
	gcc -g -c regex.c -o regex.o
	ar rcs regex.a regex.o

	#gcc -g -o main main.c regex.a
	ldc -g -of main main.d regex.a regex.d

clean:
	rm *.o
	rm *.a

