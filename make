#!/usr/bin/env python
# -*- coding: UTF-8 -*-
#-------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-------------------------------------------------------------------------------

import os, sys, shutil

# Move the path to the location of the current file
os.chdir(os.sys.path[0])
pwd = os.sys.path[0]

# Make sure we are in python 2.6 or 2.7
vmaj, vmin = sys.version_info[0:2]
version = str(vmaj) + '.' + str(vmin)
if version not in ['2.6', '2.7']:
	print "Only Python 2.6 and 2.7 are supported."
	exit()

print "Replace the hard coded 2.6 with version variable"
exit()

def rmdir(name):
	if os.path.islink(name):
		os.unlink(name)
	elif os.path.isdir(name):
		shutil.rmtree(name)
	print "Removed " + name

def rmfile(name):
	if os.path.islink(name):
		os.unlink(name)
	elif os.path.isfile(name):
		os.remove(name)
	print "Removed " + name

def symlink(source, link_name):
	os.symlink(source, link_name)
	print "Linking " + source + " to " + link_name

def all():
	print "'sudo ./make install' - Install for normal web development."
	print "'sudo ./make dev' - Install for development on the framework itself."
	print "'sudo ./make remove' - Removes it from the system."
	print "'./make test_debian' - Compiles it and runs all the unit tests on Debian."
	print "',.make test_fedora' - Compiles it and runs all the unit tests on Fedora."
	print "',.make test_ubuntu' - Compiles it and runs all the unit tests on Ubuntu."

def remove():
	rmdir('/usr/share/doc/rootintootin/')
	rmfile('/usr/share/rootintootin')
	rmdir('/usr/share/rootintootin/')
	rmfile('/usr/bin/rootintootin')
	rmfile('/usr/bin/rootintootin_run')
	rmfile('/usr/bin/rootintootin_gen')
	rmfile('/usr/bin/rootintootin_deploy')
	rmfile('/usr/bin/rootintootin_test')
	if os.path.isdir('/usr/local/lib/python2.6/site-packages/'): 
		rmfile('/usr/local/lib/python2.6/site-packages/lib_rootintootin.py')
		rmfile('/usr/local/lib/python2.6/site-packages/lib_rootintootin_scripts.py')
	elif os.path.isdir('/usr/local/lib/python2.6/dist-packages/'): 
		rmfile('/usr/local/lib/python2.6/dist-packages/lib_rootintootin.py')
		rmfile('/usr/local/lib/python2.6/dist-packages/lib_rootintootin_scripts.py')
	elif os.path.isdir('/usr/lib/python2.6/site-packages/'): 
		rmfile('/usr/lib/python2.6/site-packages/lib_rootintootin.py')
		rmfile('/usr/lib/python2.6/site-packages/lib_rootintootin_scripts.py')
	elif os.path.isdir('/usr/lib/python2.6/dist-packages/'): 
		rmfile('/usr/lib/python2.6/dist-packages/lib_rootintootin.py')
		rmfile('/usr/lib/python2.6/dist-packages/lib_rootintootin_scripts.py')

def dev():
	symlink(pwd, '/usr/share/rootintootin')
	symlink('/usr/share/rootintootin/bin/rootintootin', '/usr/bin/rootintootin')
	symlink('/usr/share/rootintootin/bin/rootintootin_run', '/usr/bin/rootintootin_run')
	symlink('/usr/share/rootintootin/bin/rootintootin_gen', '/usr/bin/rootintootin_gen')
	symlink('/usr/share/rootintootin/bin/rootintootin_deploy', '/usr/bin/rootintootin_deploy')
	symlink('/usr/share/rootintootin/bin/rootintootin_test', '/usr/bin/rootintootin_test')
	if os.path.isdir('/usr/local/lib/python2.6/site-packages/'):
		symlink('/usr/share/rootintootin/bin/lib_rootintootin.py', '/usr/local/lib/python2.6/site-packages/lib_rootintootin.py')
		symlink('/usr/share/rootintootin/bin/lib_rootintootin_scripts.py', '/usr/local/lib/python2.6/site-packages/lib_rootintootin_scripts.py')
	elif os.path.isdir('/usr/local/lib/python2.6/dist-packages/'):
		symlink('/usr/share/rootintootin/bin/lib_rootintootin.py', '/usr/local/lib/python2.6/dist-packages/lib_rootintootin.py')
		symlink('/usr/share/rootintootin/bin/lib_rootintootin_scripts.py', '/usr/local/lib/python2.6/dist-packages/lib_rootintootin_scripts.py')
	elif os.path.isdir('/usr/lib/python2.6/site-packages/'):
		symlink('/usr/share/rootintootin/bin/lib_rootintootin.py', '/usr/lib/python2.6/site-packages/lib_rootintootin.py')
		symlink('/usr/share/rootintootin/bin/lib_rootintootin_scripts.py', '/usr/lib/python2.6/site-packages/lib_rootintootin_scripts.py')
	elif os.path.isdir('/usr/lib/python2.6/dist-packages/'):
		symlink('/usr/share/rootintootin/bin/lib_rootintootin.py', '/usr/lib/python2.6/dist-packages/lib_rootintootin.py')
		symlink('/usr/share/rootintootin/bin/lib_rootintootin_scripts.py', '/usr/lib/python2.6/dist-packages/lib_rootintootin_scripts.py')


def install():
	cpdir('.', '/usr/share/rootintootin/')
	#robodoc --src src/ --doc istall_doc/ --multidoc --index --html --tabsize 4 --documenttitle "WIP Rootin Tootin 0.7 API"
	mkdir('/usr/share/doc/rootintootin/')
	#mv istall_doc/ /usr/share/doc/rootintootin/html/
	cpfile('README', '/usr/share/doc/rootintootin/README')
	cpfile('LICENSE', '/usr/share/doc/rootintootin/LICENSE')
	cpfile('COPYRIGHT', '/usr/share/doc/rootintootin/COPYRIGHT')
	cpfile('ChangeLog', '/usr/share/doc/rootintootin/ChangeLog')
	symlink('/usr/share/rootintootin/bin/rootintootin', '/usr/bin/rootintootin')
	symlink('/usr/share/rootintootin/bin/rootintootin_run', '/usr/bin/rootintootin_run')
	symlink('/usr/share/rootintootin/bin/rootintootin_gen', '/usr/bin/rootintootin_gen')
	symlink('/usr/share/rootintootin/bin/rootintootin_deploy', '/usr/bin/rootintootin_deploy')
	symlink('/usr/share/rootintootin/bin/rootintootin_test', '/usr/bin/rootintootin_test')
	if os.path.isdir('/usr/local/lib/python2.6/site-packages/'):
		symlink('/usr/share/rootintootin/bin/lib_rootintootin.py', '/usr/local/lib/python2.6/site-packages/lib_rootintootin.py')
		symlink('/usr/share/rootintootin/bin/lib_rootintootin_scripts.py', '/usr/local/lib/python2.6/site-packages/lib_rootintootin_scripts.py')
	elif os.path.isdir('/usr/local/lib/python2.6/dist-packages/'):
		symlink('/usr/share/rootintootin/bin/lib_rootintootin.py', '/usr/local/lib/python2.6/dist-packages/lib_rootintootin.py')
		symlink('/usr/share/rootintootin/bin/lib_rootintootin_scripts.py', '/usr/local/lib/python2.6/dist-packages/lib_rootintootin_scripts.py')
	elif os.path.isdir('/usr/lib/python2.6/site-packages/'):
		symlink('/usr/share/rootintootin/bin/lib_rootintootin.py', '/usr/lib/python2.6/site-packages/lib_rootintootin.py')
		symlink('/usr/share/rootintootin/bin/lib_rootintootin_scripts.py', '/usr/lib/python2.6/site-packages/lib_rootintootin_scripts.py')
	elif os.path.isdir('/usr/lib/python2.6/dist-packages/'):
		symlink('/usr/share/rootintootin/bin/lib_rootintootin.py', '/usr/lib/python2.6/dist-packages/lib_rootintootin.py')
		symlink('/usr/share/rootintootin/bin/lib_rootintootin_scripts.py', '/usr/lib/python2.6/dist-packages/lib_rootintootin_scripts.py')
'''
uninstall_python2.6: remove_python2.6

uninstall_python2.7: remove_python2.7

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
'''

if len(sys.argv) == 2 and sys.argv[1] == 'remove':
	remove()
if len(sys.argv) == 2 and sys.argv[1] == 'uninstall':
	remove()
elif len(sys.argv) == 2 and sys.argv[1] == 'dev':
	remove()
	dev()
elif len(sys.argv) == 2 and sys.argv[1] == 'install':
	remove()
	install()
else:
	all()

