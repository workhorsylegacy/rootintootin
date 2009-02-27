#!/usr/bin/env python

import os, sys
import commands
import platform

class Helper(object):
	def require_dependencies(other_globals):
		if platform.system() == 'Linux':
			try:
				other_globals['pexpect'] = __import__("pexpect")
				other_globals['MySQLdb'] = __import__("MySQLdb")

				# Make sure gdc, and gcc exists
				for command in ['gdc', 'gcc']:
					if commands.getoutput("which " + command) == '':
						raise Exception('')

				# Make sure the mysql and tango libs are installed
				for lib in ["'/usr/include/mysql/mysql.h'", "'/usr/lib/tango-gdc/libgtango.a'"]:
					if commands.getoutput('test -f ' + lib + '; echo $?') == '1':
						raise Exception('')
			except:
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

				if ['Ubuntu', 'Debian'].count(os_name):
					print "Please install requirements:\n" + \
							"    sudo apt-get install mysql-client mysql-server libmysqlclient15-dev python-pexpect python-mysqldb gcc"
					exit()
				elif ['Fedora'].count(os_name):
					print "Please install requirements:\n" + \
							"    sudo yum install mysql-client mysql-server libmysqlclient15-dev pexpect MySQL-python gcc gdc"
					exit()
				elif ['Foresight Linux'].count(os_name):
					print "Please install requirements:\n" + \
							"    mysql-client mysql-server libmysqlclient15-dev, python-pexpect, python-mysqldb, gcc, tango-gdc, and gdc"
					exit()
				else:
					print "Please install requirements for your unknown Linux distro:\n" + \
							"    mysql-client, mysql-server, libmysqlclient15-dev, python-pexpect, python-mysqldb, gcc, tango-gdc, and gdc"
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


