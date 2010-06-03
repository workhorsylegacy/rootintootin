

all:
	gcc -g -c file_system.c -o file_system.o
	ar rcs file_system.a file_system.o

	ldc -g -of main main.d file_system.a file_system.d -I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a

clean:
	rm *.o
	rm *.a
