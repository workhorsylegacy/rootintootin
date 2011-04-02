#!/usr/bin/env python
# -*- coding: UTF-8 -*-
#-------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-------------------------------------------------------------------------------

import os, sys
import shutil
import inspect
from subprocess import *

# Move the path to the location of the current file
os.chdir(os.sys.path[0])
pwd = os.sys.path[0]

# Make sure we are in python 2.6 or 2.7
version = "%s.%s" % (sys.version_info[0:2])
if version not in ['2.6', '2.7']:
	print "Only Python 2.6 and 2.7 are supported, not %s. Exiting ..." % (version)
	exit()

def __line__():
	return str(inspect.getframeinfo(inspect.currentframe().f_back)[1])

def cd(name):
	if not os.path.isdir(name):
		print "The command cd will only change to an existing directory. '%s' is not a directory. Exiting ..." % (source)
		exit()

	os.chdir(name)
	print "Changed to '%s'" % (name)

def cpfile(source, dest):
	if not os.path.isfile(source):
		print "The command cpfile will only copy a file. '%s' is not a file. Exiting ..." % (source)
		exit()

	shutil.copy2(source, dest)
	print "Copied the file '%s' to '%s'" % (source, dest)

def cpdir(source, dest):
	if not os.path.isdir(source):
		print "The command cpdir will only copy a directory. '%s' is not a directory. Exiting ..." % (source)
		exit()

	shutil.copytree(source, dest)
	print "Copied the dir '%s' to '%s'" % (source, dest)

def mkdir(source):
	fail = None

	if os.path.isdir(source):
		fail = 'directory'
	if os.path.isfile(source):
		fail = 'file'
	if os.path.islink(source):
		fail = 'symlink'

	if fail:
		print "The command mkdir will only create a directory if nothing exists with the same name."
		print "'%s' is used by a %s. Exiting ..." % (source, fail)
		exit()

	os.mkdir(source)
	print "Made the dir '%s'" % (source)

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
	if os.path.isdir('/usr/local/lib/python%s/site-packages/' % (version)):
		rmfile('/usr/local/lib/python%s/site-packages/lib_rootintootin.py' % (version))
		rmfile('/usr/local/lib/python%s/site-packages/lib_rootintootin_scripts.py' % (version))
	elif os.path.isdir('/usr/local/lib/python%s/dist-packages/' % (version)):
		rmfile('/usr/local/lib/python%s/dist-packages/lib_rootintootin.py' % (version))
		rmfile('/usr/local/lib/python%s/dist-packages/lib_rootintootin_scripts.py' % (version))
	elif os.path.isdir('/usr/lib/python%s/site-packages/' % (version)):
		rmfile('/usr/lib/python%s/site-packages/lib_rootintootin.py' % (version))
		rmfile('/usr/lib/python%s/site-packages/lib_rootintootin_scripts.py' % (version))
	elif os.path.isdir('/usr/lib/python%s/dist-packages/' % (version)):
		rmfile('/usr/lib/python%s/dist-packages/lib_rootintootin.py' % (version))
		rmfile('/usr/lib/python%s/dist-packages/lib_rootintootin_scripts.py' % (version))

def dev():
	symlink(pwd, '/usr/share/rootintootin')
	symlink('/usr/share/rootintootin/bin/rootintootin', '/usr/bin/rootintootin')
	symlink('/usr/share/rootintootin/bin/rootintootin_run', '/usr/bin/rootintootin_run')
	symlink('/usr/share/rootintootin/bin/rootintootin_gen', '/usr/bin/rootintootin_gen')
	symlink('/usr/share/rootintootin/bin/rootintootin_deploy', '/usr/bin/rootintootin_deploy')
	symlink('/usr/share/rootintootin/bin/rootintootin_test', '/usr/bin/rootintootin_test')
	if os.path.isdir('/usr/local/lib/python%s/site-packages/' % (version)):
		symlink('/usr/share/rootintootin/bin/lib_rootintootin.py', '/usr/local/lib/python%s/site-packages/lib_rootintootin.py' % (version))
		symlink('/usr/share/rootintootin/bin/lib_rootintootin_scripts.py', '/usr/local/lib/python%s/site-packages/lib_rootintootin_scripts.py' % (version))
	elif os.path.isdir('/usr/local/lib/python%s/dist-packages/' % (version)):
		symlink('/usr/share/rootintootin/bin/lib_rootintootin.py', '/usr/local/lib/python%s/dist-packages/lib_rootintootin.py' % (version))
		symlink('/usr/share/rootintootin/bin/lib_rootintootin_scripts.py', '/usr/local/lib/python%s/dist-packages/lib_rootintootin_scripts.py' % (version))
	elif os.path.isdir('/usr/lib/python%s/site-packages/' % (version)):
		symlink('/usr/share/rootintootin/bin/lib_rootintootin.py', '/usr/lib/python%s/site-packages/lib_rootintootin.py' % (version))
		symlink('/usr/share/rootintootin/bin/lib_rootintootin_scripts.py', '/usr/lib/python%s/site-packages/lib_rootintootin_scripts.py' % (version))
	elif os.path.isdir('/usr/lib/python%s/dist-packages/' % (version)):
		symlink('/usr/share/rootintootin/bin/lib_rootintootin.py', '/usr/lib/python%s/dist-packages/lib_rootintootin.py' % (version))
		symlink('/usr/share/rootintootin/bin/lib_rootintootin_scripts.py', '/usr/lib/python%s/dist-packages/lib_rootintootin_scripts.py' % (version))


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
	if os.path.isdir('/usr/local/lib/python%s/site-packages/' % (version)):
		symlink('/usr/share/rootintootin/bin/lib_rootintootin.py', '/usr/local/lib/python%s/site-packages/lib_rootintootin.py' % (version))
		symlink('/usr/share/rootintootin/bin/lib_rootintootin_scripts.py', '/usr/local/lib/python%s/site-packages/lib_rootintootin_scripts.py' % (version))
	elif os.path.isdir('/usr/local/lib/python%s/dist-packages/' % (version)):
		symlink('/usr/share/rootintootin/bin/lib_rootintootin.py', '/usr/local/lib/python%s/dist-packages/lib_rootintootin.py' % (version))
		symlink('/usr/share/rootintootin/bin/lib_rootintootin_scripts.py', '/usr/local/lib/python%s/dist-packages/lib_rootintootin_scripts.py' % (version))
	elif os.path.isdir('/usr/lib/python%s/site-packages/' % (version)):
		symlink('/usr/share/rootintootin/bin/lib_rootintootin.py', '/usr/lib/python%s/site-packages/lib_rootintootin.py' % (version))
		symlink('/usr/share/rootintootin/bin/lib_rootintootin_scripts.py', '/usr/lib/python%s/site-packages/lib_rootintootin_scripts.py' % (version))
	elif os.path.isdir('/usr/lib/python%s/dist-packages/' % (version)):
		symlink('/usr/share/rootintootin/bin/lib_rootintootin.py', '/usr/lib/python%s/dist-packages/lib_rootintootin.py' % (version))
		symlink('/usr/share/rootintootin/bin/lib_rootintootin_scripts.py', '/usr/lib/python%s/dist-packages/lib_rootintootin_scripts.py' % (version))

def ensure_root():
	# Make sure we are root
	if run('whoami') != 'root':
		print "Must be run as root. Exiting ..."
		exit()

def ensure_not_root():
	# Make sure we are NOT root
	if run('whoami') == 'root':
		print "Must not be run as root. Exiting ..."
		exit()

def ensure_requirements():
	# Make sure lsb release is installed
	if run('which lsb_release') == '':
		print 'Please install lsb_release. Exiting ...'
		exit()

	# Make sure all the requirements are installed
	os_name = run('lsb_release -is').lower()
	if os_name in ['ubuntu', 'debian']:
		missing_libs = []
		# build-essential
		if not os.path.isdir('/usr/share/build-essential/'):
			missing_libs.append('build-essential')
		# python-mysqldb
		if not os.path.isfile('/usr/share/pyshared/MySQLdb/__init__.py'):
			missing_libs.append('python-mysqldb')
		# python-pexpect
		if not os.path.isfile('/usr/share/pyshared/pexpect.py'):
			missing_libs.append('python-pexpect')
		# python-mako
		if not os.path.isfile('/usr/share/pyshared/mako/__init__.py'):
			missing_libs.append('python-mako')
		# LDC
		if not os.path.isfile('/usr/bin/ldc'):
			missing_libs.append('ldc')
		# Tango setup for LDC
		if not os.path.isfile('/usr/lib/d/libtango-user-ldc.a'):
			missing_libs.append('libtango-ldc-dev')
		# mysql-client
		if not os.path.isfile('/usr/bin/mysql_client_test'):
			missing_libs.append('mysql-client')
		# mysql-server
		if not os.path.isfile('/usr/bin/mysqltest'):
			missing_libs.append('mysql-server')
		# libmysqlclient-dev
		if not os.path.isfile('/usr/include/mysql/mysql.h'):
			missing_libs.append('libmysqlclient-dev')
		# libpcre3-dev
		if not os.path.isfile('/usr/include/pcre.h'):
			missing_libs.append('libpcre3-dev')
		# libfcgi-dev
		if not os.path.isfile('/usr/include/fastcgi.h'):
			missing_libs.append('libfcgi-dev')
		# inotify-tools
		if not os.path.isfile('/usr/bin/inotifywatch'):
			missing_libs.append('inotify-tools')

		# Tell the user which packages to install
		if missing_libs:
			print 'Please install the missing requirements. Exiting ...'
			print 'sudo apt-get install ' + str.join(' ', missing_libs)
			exit()
	elif os_name == 'fedora':
		tango = '-I /usr/include/d/ldc/ -L /usr/lib/libtango.a'
		mysql = '/usr/lib/mysql/libmysqlclient'
	else:
		print "Unknown Operating System. Please update the code '" + __file__ + \
		"' around line " + __line__() + " to be able to detect your OS. Exiting ..."
		exit()

def run(command):
	p = Popen(command, stderr=PIPE, stdout=PIPE, shell=True)
	p.wait()
	if p.returncode:
		raise Exception(p.stderr.read().rstrip())

	return p.stdout.read().rstrip()

def run_say(command):
	print command
	output = run(command)
	if len(output) > 0:
		print output

def test_ubuntu():
	test_debian()

def test_debian():
	# Remove the old test files
	rmdir('test/')
	cpdir('src/', 'test/')
	cd('test')

	# Compile the D wrappers for the C libraries and combine them into a static library
	run_say('gcc -g -c -Wall -Werror db.c -o db.o -lmysqlclient')
	run_say('gcc -g -c -Wall -Werror file_system.c -o file_system.o')
	run_say('gcc -g -c -Wall -Werror regex.c -o regex.o -lpcre')
	run_say('gcc -g -c -Wall -Werror shared_memory.c -o shared_memory.o')
	run_say('gcc -g -c -Wall -Werror socket.c -o socket.o')
	run_say('gcc -g -c -Wall -Werror fcgi.c -o fcgi.o -lfcgi')
	run_say('ar rcs clibs.a db.o file_system.o regex.o shared_memory.o socket.o fcgi.o')

	# Compile all the Rootin Tootin files into object files
	run_say('ldc -unittest -g -w -c language_helper.d web_helper.d rootintootin.d ' + \
	'ui.d rootintootin_server.d http_server.d tcp_server.d ' + \
	'rootintootin_process.d app_builder.d ' + \
	'db.d file_system.d regex.d shared_memory.d socket.d fcgi.d ' + \
	'-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a')

	# Combine the Rootin Tootin object files into a static library
	run_say('ar rcs rootintootin.a language_helper.o web_helper.o ' + \
	'rootintootin.o ui.o rootintootin_server.o http_server.o ' + \
	'tcp_server.o rootintootin_process.o app_builder.o ' + \
	'db.o file_system.o regex.o shared_memory.o socket.o fcgi.o')

	# Compile the test program and link against the static libraries
	run_say('ldc -unittest -g -w -of test test.d -L rootintootin.a -L clibs.a ' + \
	'-L-lz ' + \
	'-L/usr/lib/libmysqlclient.a -L/usr/lib/libpcre.a -L/usr/lib/libfcgi.a ' + \
	'-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a')

	# Run the tests
	run_say('./test')

	# Remove the old test files
	rmdir('test/')

def test_fedora():
	# Remove the old test files
	rmdir('test/')
	cpdir('src/', 'test/')
	cd('test/')

	# Compile the D wrappers for the C libraries and combine them into a static library
	run_say('gcc -g -c -Wall -Werror db.c -o db.o -lmysqlclient')
	run_say('gcc -g -c -Wall -Werror file_system.c -o file_system.o')
	run_say('gcc -g -c -Wall -Werror regex.c -o regex.o -lpcre')
	run_say('gcc -g -c -Wall -Werror shared_memory.c -o shared_memory.o')
	run_say('gcc -g -c -Wall -Werror socket.c -o socket.o')
	run_say('gcc -g -c -Wall -Werror fcgi.c -o fcgi.o -lfcgi')
	run_say('ar rcs clibs.a db.o file_system.o regex.o shared_memory.o socket.o fcgi.o')

	# Compile all the Rootin Tootin files into object files
	run_say('ldc -unittest -g -w -c language_helper.d web_helper.d rootintootin.d ' + \
	'ui.d rootintootin_server.d http_server.d tcp_server.d ' + \
	'rootintootin_process.d app_builder.d ' + \
	'db.d file_system.d regex.d shared_memory.d socket.d fcgi.d ' + \
	'-I /usr/include/d/ldc/ -L /usr/lib/libtango.a')

	# Combine the Rootin Tootin object files into a static library
	run_say('ar rcs rootintootin.a language_helper.o web_helper.o ' + \
	'rootintootin.o ui.o rootintootin_server.o http_server.o ' + \
	'tcp_server.o rootintootin_process.o app_builder.o ' + \
	'db.o file_system.o regex.o shared_memory.o socket.o fcgi.o')

	# Compile the test program and link against the static and shared libraries
	run_say('ldc -unittest -g -w -of test test.d -L rootintootin.a -L clibs.a ' + \
	'-L/usr/lib/mysql/libmysqlclient.so -L-lpcre -L-lfcgi ' + \
	'-I /usr/include/d/ldc/ -L /usr/lib/libtango.a')

	# Run the tests
	run_say('./test')

	# Remove the old test files
	rmdir('test/')

if len(sys.argv) == 2 and sys.argv[1] == 'remove':
	ensure_root()
	remove()
elif len(sys.argv) == 2 and sys.argv[1] == 'uninstall':
	ensure_root()
	remove()
elif len(sys.argv) == 2 and sys.argv[1] == 'dev':
	ensure_root()
	ensure_requirements()
	remove()
	dev()
elif len(sys.argv) == 2 and sys.argv[1] == 'install':
	ensure_root()
	ensure_requirements()
	remove()
	install()
elif len(sys.argv) == 2 and sys.argv[1] == 'test_debian':
	ensure_not_root()
	test_debian()
elif len(sys.argv) == 2 and sys.argv[1] == 'test_ubuntu':
	ensure_not_root()
	test_ubuntu()
elif len(sys.argv) == 2 and sys.argv[1] == 'test_fedora':
	ensure_not_root()
	test_fedora()
else:
	all()



