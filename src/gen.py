#!/usr/bin/env python

import os, sys
import pexpect
import MySQLdb

def migration_type_to_sql_type(migration_type):
	type_map = {'binary' : 'blob',
				'boolean' : 'tinyint(1)',
				'date' : 'date',
				'datetime' : 'datetime',
				'decimal' : 'datetime',
				'float' : 'float',
				'integer' : 'int(11)',
				'string' : 'varchar(255)',
				'text' : 'text',
				'time' : 'time',
				'timestamp' : 'datetime' }

	return type_map[migration_type]

def create_table(table_name, field_map):
	db_name = database_configuration['name']
	query = "create table `" + db_name + "`.`" + table_name + "` (id int, "
	for field_name, field_type in field_map.items():
		query += "`" + field_name + "` " + migration_type_to_sql_type(field_type) + ", "
	query = str.rstrip(query, ', ')
	query += ") ENGINE=innoDB;"
	cursor = db.cursor()

	try:
		cursor.execute(query)
		print "Created the table '" + table_name + "'."
	except MySQLdb.OperationalError:
		print "Table '" + table_name + "' already exists."
	cursor.close()


execfile('config/database.py')
db = MySQLdb.connect(
			host=database_configuration['host'], 
			user=database_configuration['user'], 
			passwd=database_configuration['password'])

# create database
if len(sys.argv)==3 and sys.argv[1] == "create" and sys.argv[2] == "database":
	cursor = db.cursor()
	db_name = database_configuration['name']
	try:
		cursor.execute("create database " + db_name)
		print "Created the database " + database_configuration['name'] + "."
	except MySQLdb.ProgrammingError:
		print "Database '" + database_configuration['name'] + "' already exists."
	cursor.close()

# drop database
if len(sys.argv)==3 and sys.argv[1] == "drop" and sys.argv[2] == "database":
	cursor = db.cursor()
	db_name = database_configuration['name']
	try:
		cursor.execute("drop database " + db_name)
		print "Dropped the database " + database_configuration['name'] + "."
	except MySQLdb.OperationalError:
		print "Database '" + database_configuration['name'] + "' does not exists."
	cursor.close()

# FIXME: This should not create the table, but the migration file instead
# create migration [name] [field:type] ...
if len(sys.argv)>=4 and sys.argv[1] == "create" and sys.argv[2] == "migration":
	db_name = database_configuration['name']
	query = "create table `" + db_name + "`.`" + sys.argv[3] + "` (id int, "
	for field in sys.argv[4:]:
		field_name, field_type = field.split(':')
		query += "`" + field_name + "` " + migration_type_to_sql_type(field_type) + ", "
	query = str.rstrip(query, ', ')
	query += ") ENGINE=innoDB;"
	cursor = db.cursor()

	try:
		cursor.execute(query)
	except MySQLdb.OperationalError:
		print "Table '" + sys.argv[3] + "' already exists."
	cursor.close()

# create controller [name]
if len(sys.argv)==4 and sys.argv[1] == "create" and sys.argv[2] == "controller":
	print "Not implemented."

# migrate
if len(sys.argv)==2 and sys.argv[1] == "migrate":
	for migration_file in os.listdir('db/migrate/'):
		if not migration_file.endswith('.py'):
			continue

		execfile('db/migrate/' + migration_file)
		migration_instance = globals()['CreateUsers']()
		migration_instance.up()





