#!/usr/bin/env python2.6

import os, sys
import commands
import platform

def exec_file(file, globals, locals):
	with open(file, "r") as fh:
		exec(fh.read()+"\n", globals, locals)

class Helper(object):
	def require_dependencies(other_globals):
		if platform.system() == 'Linux':
			# Make sure we have all the requirements installed
			os_name = "unknown"

			# Make sure we can get the OS name
			if commands.getoutput('which') != '':
				print "The command 'which' is not in your path. Exiting ..."
				exit()
			elif commands.getoutput('which lsb_release') != '':
				os_name = commands.getoutput('lsb_release -is')
			elif commands.getoutput('test -f /etc/fedora-release; echo $?') == '0':
				os_name = "Fedora"
			elif commands.getoutput('test -f /etc/SuSE-release; echo $?') == '0':
				os_name = "SuSE"
			elif commands.getoutput('test -f /etc/mandriva-release; echo $?') == '0':
				os_name = "Mandriva"
			elif commands.getoutput('test -f /etc/distro-release; echo $?') == '0':
				os_name = commands.getoutput('cat /etc/distro-release')
			elif commands.getoutput('test -f /etc/*-release; echo $?') == '0':
				os_name = str.split(str.split(commands.getoutput('cat /etc/*-release'), "DISTRIB_ID=")[1], "\n")[0]


			try:
				other_globals['pexpect'] = __import__("pexpect")
				other_globals['MySQLdb'] = __import__("MySQLdb")

				# Make sure ldc exists
				for command in ['gcc', 'ldc']:
					if commands.getoutput("which " + command) == '':
						raise Exception('')

			except:
				if ['Ubuntu', 'Debian'].count(os_name):
					print "Please install requirements:\n" + \
							"    sudo apt-get install mysql-client mysql-server libmysqlclient15-dev python-pexpect python-mysqldb gcc ldc"
					exit()
				elif ['Fedora'].count(os_name):
					print "Please install requirements:\n" + \
							"    sudo yum install mysql-client mysql-server libmysqlclient15-dev pexpect MySQL-python gcc ldc"
					exit()
				elif ['Foresight Linux'].count(os_name):
					print "Please install requirements:\n" + \
							"    mysql-client mysql-server libmysqlclient15-dev, python-pexpect, python-mysqldb, gcc, tango-ldc, and ldc"
					exit()
				else:
					print "Please install requirements for your unknown Linux distro:\n" + \
							"    mysql-client, mysql-server, libmysqlclient15-dev, python-pexpect, python-mysqldb, gcc, tango-ldc, and ldc"
					exit()

			# Make sure the mysql libs are installed
			if commands.getoutput('test -f ' + "'/usr/include/mysql/mysql.h'" + '; echo $?') == '1':
				print "Please install the MySQL development libraries."
				exit()

		elif platform.system() == 'Windows':
			print 'Does not yet work on Windows. Exiting ...'
			exit()

		elif platform.system() == 'SunOS':
			print 'Does not yet work on Open Solaris. Exiting ...'
			exit()

		else:
			print "Does not know how to work on the system '" + platform.system() + "'. Exiting ..."
			exit()

	require_dependencies = staticmethod(require_dependencies)


