#!/usr/bin/env python

import os, sys
import pexpect
import MySQLdb

first = sys.argv[1]
second = sys.argv[2]
third = sys.argv[3]

execfile('config/database.py')
db = MySQLdb.connect(
			host=database_configuration['host'], 
			user=database_configuration['user'], 
			passwd=database_configuration['password'])

# create database
if first == "create" and second == "database":
	cursor = db.cursor()
	db_name = database_configuration['name']
	try:
		cursor.execute("create database " + db_name)
	except MySQLdb.ProgrammingError:
		print "Database '" + third + "' already exists."
	cursor.close()

# drop database
if first == "drop" and second == "database":
	cursor = db.cursor()
	db_name = database_configuration['name']
	try:
		cursor.execute("drop database " + db_name)
	except MySQLdb.ProgrammingError:
		print "Database '" + third + "' does not exists."
	cursor.close()

# create migration [name] [field:type] ...
if first == "create" and second == "migration":
	db_name = database_configuration['name']
	query = "create table `" + db_name + "`.`" + third + "` (id int, "
	for field in sys.argv[4:]:
		field_name, field_type = field.split(':')
		query += "`" + field_name + "` " + field_type + ", "
	query = str.rstrip(query, ', ')
	query += ") ENGINE=innoDB;"

	cursor = db.cursor()
	cursor.execute(query)
	cursor.close()

# create controller [name]
if first == "" and second == "controller":
	pass

# migrate

