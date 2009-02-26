#!/usr/bin/env python

import os, sys
import commands
import platform

class Helper(object):
	def require_dependencies():
		if platform.system() == 'Linux':
			try:
				import pexpect, MySQLdb
			except:
				# Make sure we have all the requirements installed
				os_name = "unknown"

				# Make sure we can get the OS name
				if commands.getoutput('which') != '':
					print "The command 'which' is not in your path. Exiting ..."
					exit()
				elif commands.getoutput('which lsb_release') != '':
					os_name = commands.getoutput('lsb_release -is')
				elif commands.getoutput('cat /etc/fedora-release') != '':
					os_name = "Fedora"
				elif commands.getoutput('cat /etc/SuSE-release') != '':
					os_name = "SuSE"
				elif commands.getoutput('cat /etc/mandriva-release') != '':
					os_name = "Mandriva"
				elif commands.getoutput('cat /etc/distro-release') != '':
					os_name = commands.getoutput('cat /etc/distro-release')
				elif commands.getoutput('cat /etc/*-release') != '':
					os_name = str.split(str.split(commands.getoutput('cat /etc/*-release'), "DISTRIB_ID=")[1], "\n")[0]

				if ['Ubuntu', 'Debian'].count(os_name):
					print "Please install requirements:\n    sudo apt-get install python-pexpect python-mysqldb"
					exit()
				elif ['Fedora'].count(os_name):
					print "Please install requirements:\n    sudo yum install pexpect MySQL-python"
					exit()
				elif ['Foresight Linux'].count(os_name):
					print "Please install requirements:\n    python-pexpect and python-mysqldb"
					exit()
				else:
					print "Please install requirements for your unknown Linux distro:\n    python-pexpect and python-mysqldb"
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


