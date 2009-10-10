#!/usr/bin/env python2.6

import os, sys
import commands, pexpect
import platform
import MySQLdb

def exec_file(file, globals, locals):
	with open(file, "r") as fh:
		exec(fh.read()+"\n", globals, locals)

class Generator(object):
	def __init__(self):
		self._db = None
		self._database_configuration = None
		self._server_configuration = None
		self.load_configuration()

	def create_table(self, table_name, field_map):
		self.connect_to_database()

		# Create the query that will create the table
		db_name = self._database_configuration['name']
		query = "create table `" + db_name + "`.`" + table_name + "` ("
		query += "id int not null auto_increment primary key, "
		for field_name, field_type in field_map.items():
			if field_type == "reference":
				query += "`" + field_name + "_id` int not null, "
				query += "foreign key(`" + field_name + "_id`) references `" + pluralize(field_name) + "`(`id`), "
			else:
				query += "`" + field_name + "` " + self.migration_type_to_sql_type(field_type) + ", "
		query = str.rstrip(query, ', ')
		query += ") ENGINE=innoDB;"

		cursor = self._db.cursor()

		# Try running the query
		try:
			cursor.execute(query)
			print "Created the table '" + table_name + "'."
		except MySQLdb.OperationalError:
			raise Exception("Table '" + table_name + "' already exists.")
		cursor.close()

	def drop_table(self, table_name):
		self.connect_to_database()

		# Create the query that will drop the table
		db_name = self._database_configuration['name']
		query = "drop table `" + db_name + "`.`" + table_name + "`;"
		cursor = self._db.cursor()

		# Try running the query
		try:
			cursor.execute(query)
			print "Dropped the table '" + table_name + "'."
		except MySQLdb.OperationalError:
			raise Exception("Table '" + table_name + "' not dropped.")
		cursor.close()

	def create_database(self):
		self.connect_to_database()
		cursor = self._db.cursor()
		db_name = self._database_configuration['name']
		try:
			cursor.execute("create database " + db_name)
			print "Created the database '" + self._database_configuration['name'] + "'."
		except MySQLdb.ProgrammingError:
			print "Database '" + self._database_configuration['name'] + "' already exists."
		cursor.close()
		self.create_table("schema_version", {
			'version' : 'integer'
		})

	def drop_database(self):
		self.connect_to_database()
		cursor = self._db.cursor()
		db_name = self._database_configuration['name']
		try:
			cursor.execute("drop database " + db_name)
			print "Dropped the database '" + self._database_configuration['name'] + "'."
		except MySQLdb.OperationalError:
			print "Database '" + self._database_configuration['name'] + "' does not exists."
		cursor.close()

	def create_migration(self, model_name, pairs):
		self.connect_to_database()

		# Get the last schema version
		last_version = self.get_schema_version()
		version = str(last_version + 1).rjust(4, '0')

		f = open('db/migrate/' + version + '_create_' + model_name + '.py', 'w')

		f.write(
			"class Create" + model_name.capitalize() + ":\n" +
			"	def up(self, generator):\n" +
			"		generator.create_table('" + pluralize(model_name) + "', {\n"
		)
	
		for field in pairs:
			field_name, field_type = field.split(':')
			f.write("\t\t\t'" + field_name + "' : '" + field_type + "', \n")
		f.write("		}) \n")

		f.write("	def down(self, generator):\n" +
			"		generator.drop_table('" + pluralize(model_name) + "')\n" +
			"\n\n"
		)

	def migrate(self):
		self.connect_to_database()
		# Get the last schema version
		last_version = self.get_schema_version()

		migration_files = os.listdir('db/migrate/')
		migration_files.sort()

		# Check to see if there are no files to migrate
		if len(migration_files) == 0:
			print "There are no migration files."
			return

		# Check to see if we don't need to migrate
		if last_version == int(migration_files[-1][0:4]):
			print "Already migrated to latest version: " + str(last_version) + "."
			return

		for migration_file in migration_files:
			# Skip the non python files
			if not migration_file.endswith('.py'):
				continue

			# Skip previous migrations
			version = int(migration_file[0:4])
			if version <= last_version:
				continue

			# Run the migration
			class_name = camelize(migration_file[5:-3])
			exec_file('db/migrate/' + migration_file, globals(), locals())
			migration_instance = locals()[class_name]()
			try:
				migration_instance.up(self)
				self.add_schema_version(version)
			except Exception as err:
				print "Broke on migration file: '" + migration_file + "'."
				print err.message
				return

	def configure_database(self, pairs):
		# Add each key-value pair to the configuration hash
		for pair in pairs:
			key, value = pair.split(':')

			if key == 'user':
				self._database_configuration['user'] = value
			elif key == 'password':
				self._database_configuration['password'] = value
			elif key == 'name':
				self._database_configuration['name'] = value

		self.save_configuration()

	def configure_server(self, pairs):
		# Add each key-value pair to the configuration hash
		for pair in pairs:
			key, value = pair.split(':')

			if key == 'port':
				self._server_configuration['port'] = value
			elif key == 'max_connections':
				self._server_configuration['max_connections'] = value

		self.save_configuration()

#private

	def load_configuration(self):
		exec_file('config/config.py', globals(), locals())
		self._database_configuration = locals()['database_configuration']
		self._server_configuration = locals()['server_configuration']

	def save_configuration(self):
		f = open('config/config.py', 'w')

		f.write("\ndatabase_configuration = {\n")
		for key, value in self._database_configuration.items():
			f.write("	\"" + key + "\" : \"" + value + "\", \n")
		f.write("}\n\n")

		f.write("server_configuration = {\n")
		for key, value in self._server_configuration.items():
			f.write("	\"" + str(key) + "\" : \"" + str(value) + "\", \n")
		f.write("}\n\n")

		f.close()

	def connect_to_database(self):
		if self._db != None:
			return

		try:
			self._db = MySQLdb.connect(
						host = self._database_configuration['host'], 
						user = self._database_configuration['user'], 
						passwd = self._database_configuration['password'])
		except MySQLdb.OperationalError, err:
			print "MySQL error# " + str(err.args[0]) + " : " + err.args[1]
			exit()

	def get_schema_version(self):
		self.connect_to_database()

		db_name = self._database_configuration['name']
		query = "select max(version) from `" + db_name + "`.`schema_version`;"
		cursor = self._db.cursor()
		cursor.execute(query)
		version = cursor.fetchone()
		cursor.close()
		if version[0] == None:
			return 0
		else:
			return int(version[0])

	def add_schema_version(self, version):
		self.connect_to_database()
		db_name = self._database_configuration['name']

		query = "insert into `" + db_name + \
		"`.`schema_version`(version) values('" + \
		str(version) + "');"

		self._db.query(query)
		self._db.commit()

	def migration_type_to_sql_type(self, migration_type):
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

