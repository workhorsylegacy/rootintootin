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
import commands
import platform, re, glob

# Move the path to the location of the current file
os.chdir(os.sys.path[0])
pwd = os.sys.path[0]

# Make sure we are in python 2.6 or 2.7
version = "%s.%s" % (sys.version_info[0:2])
if version not in ['2.6', '2.7']:
	print "Only Python 2.6 and 2.7 are supported, not %s. Exiting ..." % (version)
	exit()

# Figure out if the CPU is 32bit or 64bit
bits = None
if platform.architecture()[0] == '64bit':
	bits = '64'
else:
	bits = '32'

# Figure out the CPU architecture
arch = None
if re.match('^i\d86', platform.machine()):
	arch = 'i386'
elif platform.machine() == 'x86_64':
	arch = 'x86_64'
else:
	print "Unknown architecture: " + platform.machine() + " . Exiting ..."
	exit()

user_name = os.environ["LOGNAME"]
if os.getenv("SUDO_USER"):
	user_name = os.getenv("SUDO_USER")

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
	print "'./make test' - Compiles it and runs all the unit tests."

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
	# Make sure all the requirements are installed
	if os_name in ['ubuntu', 'debian', 'linuxmint']:
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
		# libconfig++8
		if not os.path.isfile('/usr/lib/libconfig++.so.8'):
			missing_libs.append('libconfig++8')

		# Tell the user which packages to install
		if missing_libs:
			print 'Please install the missing requirements. Exiting ...'
			print 'sudo apt-get install ' + str.join(' ', missing_libs)
			exit()
	elif os_name == 'fedora':
		missing_libs = []
		# GCC
		if not os.path.isfile('/usr/bin/gcc'):
			missing_libs.append('gcc')
		# MySQL-python
		if bits == '32':
			if not os.path.isfile('/usr/lib/python2.7/site-packages/MySQLdb/__init__.py'):
				missing_libs.append('MySQL-python')
		elif bits == '64':
			if not os.path.isfile('/usr/lib64/python2.7/site-packages/MySQLdb/__init__.py'):
				missing_libs.append('MySQL-python')
		# pexpect
		if not os.path.isfile('/usr/lib/python2.7/site-packages/pexpect.py'):
			missing_libs.append('pexpect')
		# python-mako
		if not os.path.isfile('/usr/lib/python2.7/site-packages/mako/__init__.py'):
			missing_libs.append('python-mako')
		# mysql-client
		if not os.path.isfile('/usr/bin/mysqladmin'):
			missing_libs.append('mysql')
		# mysql-server
		if not os.path.isfile('/usr/bin/mysqltest'):
			missing_libs.append('mysql-server')
		# mysql-devel
		if not os.path.isfile('/usr/include/mysql/mysql.h'):
			missing_libs.append('mysql-devel')
		# pcre-devel
		if not os.path.isfile('/usr/include/pcre.h'):
			missing_libs.append('pcre-devel')
		# libfcgi-dev
		if not os.path.isfile('/usr/include/fastcgi.h'):
			missing_libs.append('fcgi-devel')
		# inotify-tools
		if not os.path.isfile('/usr/bin/inotifywatch'):
			missing_libs.append('inotify-tools')
		# libconfig
		if bits == '32':
			if not glob.glob('/usr/lib/libconfig++.so.*'):
				missing_libs.append('libconfig')
		elif bits == '64':
			if not glob.glob('/usr/lib64/libconfig++.so.*'):
				missing_libs.append('libconfig')

		# Tell the user which packages to install
		if missing_libs:
			print 'Please install the missing requirements. Exiting ...'
			print 'sudo yum install ' + str.join(' ', missing_libs)
			exit()

		# Install libconfig
		if bits == '32':
			if not '/usr/lib/libconfig++.so.8' in glob.glob('/usr/lib/libconfig++.so.*'):
				c = glob.glob('/usr/lib/libconfig++.so.*')[0]
				print 'Please link your libconfig++ so it can be used by LDC. Exiting ...'
				print 'sudo ln -s ' + c + ' /usr/lib/libconfig++.so.8'
				exit()
		elif bits == '64':
			if not '/usr/lib64/libconfig++.so.8' in glob.glob('/usr/lib64/libconfig++.so.*'):
				c = glob.glob('/usr/lib64/libconfig++.so.*')[0]
				print 'Please link your libconfig++ so it can be used by LDC. Exiting ...'
				print 'sudo ln -s ' + c + ' /usr/lib64/libconfig++.so.8'
				exit()

	elif os_name == 'suse linux':
		missing_libs = []
		# GCC
		if not os.path.isfile('/usr/bin/gcc'):
			missing_libs.append('gcc')
		# GCC C++
		if not os.path.isfile('/usr/bin/g++'):
			missing_libs.append('gcc-c++')
		# MySQL-python
		if not os.path.isfile('/usr/lib/python2.7/site-packages/MySQLdb/constants/__init__.py'):
			missing_libs.append('python-mysql')
		# python-pexpect
		if not os.path.isfile('/usr/lib/python2.7/site-packages/pexpect.py'):
			missing_libs.append('python-pexpect')
		# python-mako
		if not os.path.isfile('/usr/lib/python2.7/site-packages/mako/__init__.py'):
			missing_libs.append('python-mako')
		if not os.path.isfile('/usr/bin/mysqladmin'):
			missing_libs.append('mysql-community-server-client')
		# mysql-community-server
		if not os.path.isfile('/usr/bin/innochecksum'):
			missing_libs.append('mysql-community-server')
		# libmysqlclient-devel
		if not os.path.isfile('/usr/include/mysql/mysql.h'):
			missing_libs.append('libmysqlclient-devel')
		# pcre-devel
		if not os.path.isfile('/usr/include/pcre.h'):
			missing_libs.append('pcre-devel')
		# FastCGI-devel
		if not os.path.isfile('/usr/include/fastcgi/fastcgi.h'):
			missing_libs.append('FastCGI-devel')
		# inotify-tools
		#if not os.path.isfile('/usr/bin/inotifywatch'):
		#	missing_libs.append('inotify-tools')

		# Tell the user which packages to install
		if missing_libs:
			print 'Please install the missing requirements. Exiting ...'
			print 'sudo zypper install ' + str.join(' ', missing_libs)
			exit()

	else:
		print "Unknown Operating System. Please update the code '" + __file__ + \
		"' around line " + __line__() + " to be able to detect your OS. Exiting ..."
		exit()

	# LDC and Tango
	if not os.path.isfile(os.path.expanduser('~' + user_name + '/tango-bundle/bin/ldc')) or \
		not os.path.isfile(os.path.expanduser('~' + user_name + '/tango-bundle/lib/libtango-ldc.a')):

		print "Please install LDC and Tango for %sbit. Exiting ..." % (bits)
		print "cd ~"
		print "wget http://downloads.dsource.org/projects/tango/0.99.9/tango-0.99.9-bin-linux" + bits + "-with-ldc.1.056.tar.gz"
		print "tar -zxvf tango-0.99.9-bin-linux" + bits + "-with-ldc.1.056.tar.gz"
		print "echo 'export PATH=$PATH:$HOME/tango-bundle/bin' >> ~/.bashrc"
		print ". ~/.bashrc"
		exit()

def run(command):
	p = Popen(command, stderr=PIPE, stdout=PIPE, shell=True)
	p.wait()
	if p.returncode:
		raise Exception(p.stderr.read().rstrip())

	return p.stdout.read().rstrip()

def run_say(command):
	print command
	p = Popen(command, stderr=PIPE, stdout=PIPE, shell=True)
	p.wait()
	o = p.stdout.read().rstrip()
	e = p.stderr.read().rstrip()
	if len(o):
		print o
	if len(e):
		print e
	if p.returncode:
		print "Failed to run command. Exiting ..."
		exit()

def test():
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
	if os_name == 'suse linux':
		run_say('gcc -g -c -Wall -Werror fcgi.c -o fcgi.o -lfcgi -I/usr/include/fastcgi/')
	else:
		run_say('gcc -g -c -Wall -Werror fcgi.c -o fcgi.o -lfcgi')
	run_say('ar rcs clibs.a db.o file_system.o regex.o shared_memory.o socket.o fcgi.o')

	# Compile all the Rootin Tootin files into object files
	run_say('ldc -unittest -g -w -c language_helper.d web_helper.d rootintootin.d ' + \
	'ui.d rootintootin_server.d http_server.d tcp_server.d ' + \
	'rootintootin_process.d app_builder.d ' + \
	'db.d file_system.d regex.d shared_memory.d socket.d fcgi.d')

	# Combine the Rootin Tootin object files into a static library
	run_say('ar rcs rootintootin.a language_helper.o web_helper.o ' + \
	'rootintootin.o ui.o rootintootin_server.o http_server.o ' + \
	'tcp_server.o rootintootin_process.o app_builder.o ' + \
	'db.o file_system.o regex.o shared_memory.o socket.o fcgi.o')

	if os_name in ['ubuntu', 'debian', 'linuxmint']:
		# Compile the test program and link against the static libraries
		run_say('ldc -unittest -g -w -of test test.d -L rootintootin.a -L clibs.a ' + \
		'-L-lz ' + \
		'-L/usr/lib/libmysqlclient.a -L/usr/lib/' + arch + '-linux-gnu/libpcre.a -L/usr/lib/libfcgi.a ' + \
		'-I ~/tango-bundle/import/ -L ~/tango-bundle/lib/libtango-ldc.a')
	elif os_name == 'fedora':
		# Compile the test program and link against the static and shared libraries
		if bits == '32':
			run_say('ldc -unittest -g -w -of test test.d -L rootintootin.a -L clibs.a ' + \
			'-L/usr/lib/mysql/libmysqlclient.so -L-lpcre -L-lfcgi ' + \
			'-I ~/tango-bundle/import/ -L ~/tango-bundle/lib/libtango-ldc.a')
		elif bits == '64':
			run_say('ldc -unittest -g -w -of test test.d -L rootintootin.a -L clibs.a ' + \
			'-L/usr/lib64/mysql/libmysqlclient.so -L-lpcre -L-lfcgi ' + \
			'-I ~/tango-bundle/import/ -L ~/tango-bundle/lib/libtango-ldc.a')
	elif os_name == 'suse linux':
		# Compile the test program and link against the static and shared libraries
		run_say('ldc -unittest -g -w -of test test.d -L rootintootin.a -L clibs.a ' + \
		'-L/usr/lib/libmysqlclient.so -L-lpcre -L-lfcgi ' + \
		'-I ~/tango-bundle/import/ -L ~/tango-bundle/lib/libtango-ldc.a')
	else:
		print "Unknown Operating System. Please update the code '" + __file__ + \
		"' around line " + __line__() + " to be able to detect your OS. Exiting ..."
		exit()

	# Run the tests
	run_say('./test')

	# Remove the old test files
	rmdir('test/')

# Make sure we can get an OS
os_name = platform.dist()[0].lower()

# Run the command depending on the args
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
elif len(sys.argv) == 2 and sys.argv[1] == 'test':
	ensure_not_root()
	ensure_requirements()
	test()
else:
	all()



