#!/usr/bin/env python

import os, sys, re
import pexpect
import MySQLdb

# Move the path to the location of the current file
os.chdir(os.sys.path[0])

#import Inflector

def pluralize(value):
	return value + 's'

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
	query = "create table `" + db_name + "`.`" + table_name + "` ("
	query += "id int not null auto_increment primary key, "
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

def drop_table(table_name):
	db_name = database_configuration['name']
	query = "drop table `" + db_name + "`.`" + table_name + "`;"
	cursor = db.cursor()

	try:
		cursor.execute(query)
		print "Dropped the table '" + table_name + "'."
	except MySQLdb.OperationalError:
		print "Table '" + table_name + "' not dropped."
	cursor.close()

def get_schema_version():
	db_name = database_configuration['name']
	query = "select max(version) from `" + db_name + "`.`schema_version`;"
	cursor = db.cursor()
	cursor.execute(query)
	version = cursor.fetchone()
	cursor.close()
	if version[0] == None:
		return 0
	else:
		return int(version[0])

def add_schema_version(version):
	db_name = database_configuration['name']

	query = "insert into `" + db_name + \
	"`.`schema_version`(version) values('" + \
	str(version) + "');"

	db.query(query)
	db.commit()


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
	create_table("schema_version", {
		'version' : 'integer'
	})

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

'''
create model [name] [field:type] ...
drop model [name]
rename model [name] to [name]
alter model [name] name_of_migration

add field [field:type] to [name]
remove field [field] from [name]
rename field [field] to [field] from [name]
alter field [field] from [name] name_of_migration
'''
# create migration [name] [field:type] ...
if len(sys.argv)>=4 and sys.argv[1] == "create" and sys.argv[2] == "migration":
	# Get the last schema version
	last_version = get_schema_version()
	version = str(last_version + 1).rjust(4, '0')

	model_name = sys.argv[3]
	f = open('db/migrate/' + version + '_create_' + model_name + '.py', 'w')

	f.write(
		"class Create" + model_name.capitalize() + ":\n" +
		"	def up(self):\n" +
		"		create_table('" + pluralize(model_name) + "', {\n"
	)
	for field in sys.argv[4:]:
		f.write("\t\t\t'" + field.split(':')[0] + "' : '" + field.split(':')[1] + "', \n", )
	f.write("		})\n\n" +
		"	def down(self):\n" +
		"		drop_table('" + pluralize(model_name) + "')\n" +
		"\n\n"
	)

# create controller [name]
if len(sys.argv)==4 and sys.argv[1] == "create" and sys.argv[2] == "controller":
	print "Not implemented."

# migrate
if len(sys.argv)==2 and sys.argv[1] == "migrate":
	for migration_file in os.listdir('db/migrate/'):
		# Skip the non python files
		if not migration_file.endswith('.py'):
			continue

		# Run the migration
		version = int(migration_file[0:4])
		execfile('db/migrate/' + migration_file)
		migration_instance = globals()['CreateUsers']()
		migration_instance.up()
		add_schema_version(version)





