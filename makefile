
all:
	@echo "'sudo make install_python2.6' - Installs Rootin Tootin for normal web development."
	@echo "'sudo make install_python2.7' - Installs Rootin Tootin for normal web development."
	@echo "'sudo make dev_python2.6' - Installs Rootin Tootin for development on the framework itself."
	@echo "'sudo make dev_python2.7' - Installs Rootin Tootin for development on the framework itself."
	@echo "'sudo make remove' - Removes Rootin Tootin from the system."
	@echo "'make test_debian' - Compiles the framework and runs all the unit tests on Debian."
	@echo "'make test_fedora' - Compiles the framework and runs all the unit tests on Fedora."
	@echo "'make test_ubuntu' - Compiles the framework and runs all the unit tests on Ubuntu."

uninstall: remove

remove:
	rm -rf -f /usr/share/doc/rootintootin/
	rm -f -rf /usr/share/rootintootin
	rm -f -rf /usr/share/rootintootin/
	rm -f /usr/bin/rootintootin
	rm -f /usr/bin/rootintootin_run
	rm -f /usr/bin/rootintootin_gen
	rm -f /usr/bin/rootintootin_deploy
	rm -f /usr/bin/rootintootin_test
	rm -f /usr/lib/python2.6/site-packages/lib_rootintootin.py
	rm -f /usr/lib/python2.7/site-packages/lib_rootintootin.py
	rm -f /usr/lib/python2.6/site-packages/lib_rootintootin_scripts.py
	rm -f /usr/lib/python2.7/site-packages/lib_rootintootin_scripts.py

install_python2.6: remove
	cp -R . /usr/share/rootintootin/
	#robodoc --src src/ --doc istall_doc/ --multidoc --index --html --tabsize 4 --documenttitle "WIP Rootin Tootin 0.7 API"
	mkdir /usr/share/doc/rootintootin/
	#mv istall_doc/ /usr/share/doc/rootintootin/html/
	cp README /usr/share/doc/rootintootin/README
	cp LICENSE /usr/share/doc/rootintootin/LICENSE
	cp COPYRIGHT /usr/share/doc/rootintootin/COPYRIGHT
	cp ChangeLog /usr/share/doc/rootintootin/ChangeLog
	ln -s /usr/share/rootintootin/bin/rootintootin /usr/bin/rootintootin
	ln -s /usr/share/rootintootin/bin/rootintootin_run /usr/bin/rootintootin_run
	ln -s /usr/share/rootintootin/bin/rootintootin_gen /usr/bin/rootintootin_gen
	ln -s /usr/share/rootintootin/bin/rootintootin_deploy /usr/bin/rootintootin_deploy
	ln -s /usr/share/rootintootin/bin/rootintootin_test /usr/bin/rootintootin_test
	ln -s /usr/share/rootintootin/bin/lib_rootintootin.py /usr/lib/python2.6/site-packages/lib_rootintootin.py
	ln -s /usr/share/rootintootin/bin/lib_rootintootin_scripts.py /usr/lib/python2.6/site-packages/lib_rootintootin_scripts.py

install_python2.7: remove
	cp -R . /usr/share/rootintootin/
	#robodoc --src src/ --doc istall_doc/ --multidoc --index --html --tabsize 4 --documenttitle "WIP Rootin Tootin 0.7 API"
	mkdir /usr/share/doc/rootintootin/
	#mv istall_doc/ /usr/share/doc/rootintootin/html/
	cp README /usr/share/doc/rootintootin/README
	cp LICENSE /usr/share/doc/rootintootin/LICENSE
	cp COPYRIGHT /usr/share/doc/rootintootin/COPYRIGHT
	cp ChangeLog /usr/share/doc/rootintootin/ChangeLog
	ln -s /usr/share/rootintootin/bin/rootintootin /usr/bin/rootintootin
	ln -s /usr/share/rootintootin/bin/rootintootin_run /usr/bin/rootintootin_run
	ln -s /usr/share/rootintootin/bin/rootintootin_gen /usr/bin/rootintootin_gen
	ln -s /usr/share/rootintootin/bin/rootintootin_deploy /usr/bin/rootintootin_deploy
	ln -s /usr/share/rootintootin/bin/rootintootin_test /usr/bin/rootintootin_test
	ln -s /usr/share/rootintootin/bin/lib_rootintootin.py /usr/lib/python2.7/site-packages/lib_rootintootin.py
	ln -s /usr/share/rootintootin/bin/lib_rootintootin_scripts.py /usr/lib/python2.7/site-packages/lib_rootintootin_scripts.py

dev_python2.6: remove
	ln -s `pwd` /usr/share/rootintootin
	ln -s /usr/share/rootintootin/bin/rootintootin /usr/bin/rootintootin
	ln -s /usr/share/rootintootin/bin/rootintootin_run /usr/bin/rootintootin_run
	ln -s /usr/share/rootintootin/bin/rootintootin_gen /usr/bin/rootintootin_gen
	ln -s /usr/share/rootintootin/bin/rootintootin_deploy /usr/bin/rootintootin_deploy
	ln -s /usr/share/rootintootin/bin/rootintootin_test /usr/bin/rootintootin_test
	ln -s /usr/share/rootintootin/bin/lib_rootintootin.py /usr/lib/python2.6/site-packages/lib_rootintootin.py
	ln -s /usr/share/rootintootin/bin/lib_rootintootin_scripts.py /usr/lib/python2.6/site-packages/lib_rootintootin_scripts.py

dev_python2.7: remove
	ln -s `pwd` /usr/share/rootintootin
	ln -s /usr/share/rootintootin/bin/rootintootin /usr/bin/rootintootin
	ln -s /usr/share/rootintootin/bin/rootintootin_run /usr/bin/rootintootin_run
	ln -s /usr/share/rootintootin/bin/rootintootin_gen /usr/bin/rootintootin_gen
	ln -s /usr/share/rootintootin/bin/rootintootin_deploy /usr/bin/rootintootin_deploy
	ln -s /usr/share/rootintootin/bin/rootintootin_test /usr/bin/rootintootin_test
	ln -s /usr/share/rootintootin/bin/lib_rootintootin.py /usr/lib/python2.7/site-packages/lib_rootintootin.py
	ln -s /usr/share/rootintootin/bin/lib_rootintootin_scripts.py /usr/lib/python2.7/site-packages/lib_rootintootin_scripts.py

test_debian: test_ubuntu

test_ubuntu:
	# Make sure the user is not root
	runner=`whoami` ; \
	if test $$runner != "root" ; \
	then \
		echo "You are not root. Continuing ..."; \
	else \
		echo "You are root. Do not run this as root." ; \
		exit 1 ; \
	fi

	# Remove the old test files
	rm -f -rf test/
	cp -R src/ test/
	cd test; \
	\
	# Compile the D wrappers for the C libraries and combine them into a static library \
	gcc -g -c -Wall -Werror db.c -o db.o -lmysqlclient; \
	gcc -g -c -Wall -Werror file_system.c -o file_system.o; \
	gcc -g -c -Wall -Werror regex.c -o regex.o -lpcre; \
	gcc -g -c -Wall -Werror shared_memory.c -o shared_memory.o; \
	gcc -g -c -Wall -Werror socket.c -o socket.o; \
	gcc -g -c -Wall -Werror fcgi.c -o fcgi.o -lfcgi; \
	ar rcs clibs.a db.o file_system.o regex.o shared_memory.o socket.o fcgi.o; \
	\
	# Compile all the Rootin Tootin files into object files \
	ldc -unittest -g -w -c language_helper.d web_helper.d rootintootin.d \
	ui.d rootintootin_server.d http_server.d tcp_server.d \
	rootintootin_process.d app_builder.d \
	db.d file_system.d regex.d shared_memory.d socket.d fcgi.d \
	-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a; \
	\
	# Combine the Rootin Tootin object files into a static library \
	ar rcs rootintootin.a language_helper.o web_helper.o \
	rootintootin.o ui.o rootintootin_server.o http_server.o \
	tcp_server.o rootintootin_process.o app_builder.o \
	db.o file_system.o regex.o shared_memory.o socket.o fcgi.o; \
	\
	# Compile the test program and link against the static libraries \
	ldc -unittest -g -w -of test test.d -L rootintootin.a -L clibs.a \
	-L-lz \
	-L/usr/lib/libmysqlclient.a -L/usr/lib/libpcre.a -L/usr/lib/libfcgi.a \
	-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a; \
	\
	# Run the tests \
	./test;
	\
	# Remove the old test files
	rm -f -rf test/

test_fedora:
	# Make sure the user is not root
	runner=`whoami` ; \
	if test $$runner != "root" ; \
	then \
		echo "You are not root. Continuing ..."; \
	else \
		echo "You are root. Do not run this as root." ; \
		exit 1 ; \
	fi

	# Remove the old test files
	rm -f -rf test/
	cp -R src/ test/
	cd test; \
	\
	# Compile the D wrappers for the C libraries and combine them into a static library \
	gcc -g -c -Wall -Werror db.c -o db.o -lmysqlclient; \
	gcc -g -c -Wall -Werror file_system.c -o file_system.o; \
	gcc -g -c -Wall -Werror regex.c -o regex.o -lpcre; \
	gcc -g -c -Wall -Werror shared_memory.c -o shared_memory.o; \
	gcc -g -c -Wall -Werror socket.c -o socket.o; \
	gcc -g -c -Wall -Werror fcgi.c -o fcgi.o -lfcgi; \
	ar rcs clibs.a db.o file_system.o regex.o shared_memory.o socket.o fcgi.o; \
	\
	# Compile all the Rootin Tootin files into object files \
	ldc -unittest -g -w -c language_helper.d web_helper.d rootintootin.d \
	ui.d rootintootin_server.d http_server.d tcp_server.d \
	rootintootin_process.d app_builder.d \
	db.d file_system.d regex.d shared_memory.d socket.d fcgi.d \
	-I /usr/include/d/ldc/ -L /usr/lib/libtango.a; \
	\
	# Combine the Rootin Tootin object files into a static library \
	ar rcs rootintootin.a language_helper.o web_helper.o \
	rootintootin.o ui.o rootintootin_server.o http_server.o \
	tcp_server.o rootintootin_process.o app_builder.o \
	db.o file_system.o regex.o shared_memory.o socket.o fcgi.o; \
	\
	# Compile the test program and link against the static and shared libraries \
	ldc -unittest -g -w -of test test.d -L rootintootin.a -L clibs.a \
	-L/usr/lib/mysql/libmysqlclient.so -L-lpcre -L-lfcgi \
	-I /usr/include/d/ldc/ -L /usr/lib/libtango.a; \
	\
	# Run the tests \
	./test;
	\
	# Remove the old test files
	rm -f -rf test/

