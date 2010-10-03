#!/usr/bin/env python2.6
# -*- coding: UTF-8 -*-
#-------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-------------------------------------------------------------------------------

import os, sys, re
import commands, pexpect
import platform
import json
import MySQLdb

rootintootin_path = os.path.dirname(os.sys.path[0]) + '/'

# Returns true if file_a is newer than file_b
# Returns true if file_b does not exist
def is_file_newer(file_a, file_b):
	if not os.path.exists(file_b):
		return True
	return os.path.getmtime(file_a) > os.path.getmtime(file_b)

def exec_file(file, globals, locals):
	with open(file, "r") as fh:
		exec(fh.read()+"\n", globals, locals)

def camelize(word):
	return ''.join(w[0].upper() + w[1:] for w in re.sub('[^A-Z^a-z^0-9^:]+', ' ', word).split(' '))

def migration_type_default_sql_value(migration_type):
	p = re.compile("^decimal\[\d+\,\d+\]$")
	if p.match(migration_type):
		return 'not null default 0'

	p = re.compile("^unique_decimal\[\d+\,\d+\]$")
	if p.match(migration_type):
		return 'not null default 0'

	type_map = {'boolean'             : 'not null default 0',
				'date'                : 'not null default 0',
				'datetime'            : 'not null default 0',
				'decimal'             : 'not null default 0',
				'float'               : 'not null default 0',
				'integer'             : 'not null default 0',
				'string'              : 'default null',
				'text'                : 'default null',
				'time'                : 'not null default 0',
				'timestamp'           : 'not null default 0',
				'unique_date'         : 'not null default 0',
				'unique_datetime'     : 'not null default 0',
				'unique_decimal'      : 'not null default 0',
				'unique_float'        : 'not null default 0',
				'unique_integer'      : 'not null default 0',
				'unique_string'       : 'not null',
				'unique_time'         : 'not null default 0',
				'unique_timestamp'    : 'not null default 0'}

	return type_map[migration_type]

def sql_type_to_default_d_value(sql_type):
	p = re.compile("^decimal\(\d+\,\d+\)$")
	if p.match(sql_type):
		precision = sql_type.split('(')[1].split(',')[0]
		scale = sql_type.split(',')[1].split(')')[0]
		return 'null'

	type_map = {'tinyint(1)'   : 'false',
				'date'         : '"0"',
				'datetime'     : '"0"',
				'decimal'      : 'null',
				'float'        : '0',
				'int(11)'      : '0',
				'varchar(255)' : 'null',
				'text'         : 'null',
				'time'         : '"0"',
				'timestamp'    : '"0"' }

	return type_map[sql_type]

def is_valid_migration_type(migration_type):
	try:
		migration_type_to_sql_type(migration_type)
		return True
	except:
		return False

def sql_type_to_xml_type(sql_type):
	p = re.compile("^decimal\(\d+\,\d+\)$")
	if p.match(sql_type):
		return 'decimal'

	type_map = {'tinyint(1)'   : 'boolean',
				'date'         : 'date',
				'datetime'     : 'dateTime',
				'decimal'      : 'decimal',
				'float'        : 'float',
				'int(11)'      : 'long',
				'varchar(255)' : 'string',
				'text'         : 'string',
				'time'         : 'time',
				'timestamp'    : 'dateTime'}

	return type_map[sql_type]

def sql_type_to_d_type(sql_type):
	p = re.compile("^decimal\(\d+\,\d+\)$")
	if p.match(sql_type):
		precision = sql_type.split('(')[1].split(',')[0]
		scale = sql_type.split(',')[1].split(')')[0]
		return 'FixedPoint'

	type_map = {'tinyint(1)'   : 'bool',
				'date'         : 'string',
				'datetime'     : 'string',
				'decimal'      : 'FixedPoint',
				'float'        : 'float',
				'int(11)'      : 'ulong',
				'varchar(255)' : 'string',
				'text'         : 'string',
				'time'         : 'string',
				'timestamp'    : 'string'}

	return type_map[sql_type]

def migration_type_to_sql_type(migration_type):
	p = re.compile("^decimal\[\d+\,\d+\]$")
	if p.match(migration_type):
		precision = migration_type.split('[')[1].split(',')[0]
		scale = migration_type.split(',')[1].split(']')[0]
		return 'decimal(' + precision + ',' + scale + ')'

	p = re.compile("^unique_decimal\[\d+\,\d+\]$")
	if p.match(migration_type):
		precision = migration_type.split('[')[1].split(',')[0]
		scale = migration_type.split(',')[1].split(']')[0]
		return 'decimal(' + precision + ',' + scale + ')'

	type_map = {'boolean'          : 'tinyint(1)',
				'date'             : 'date',
				'datetime'         : 'datetime',
				'decimal'          : 'decimal(20,2)',
				'float'            : 'float',
				'integer'          : 'int(11)',
				'string'           : 'varchar(255)',
				'text'             : 'text',
				'time'             : 'time',
				'timestamp'        : 'datetime',
				'unique_date'      : 'date',
				'unique_datetime'  : 'datetime',
				'unique_decimal'   : 'decimal(20,2)',
				'unique_float'     : 'float',
				'unique_integer'   : 'int(11)',
				'unique_string'    : 'varchar(255)',
				'unique_time'      : 'time',
				'unique_timestamp' : 'datetime'}

	return type_map[migration_type]

def migration_type_to_html_type(migration_type):
	p = re.compile("^decimal\[\d+\,\d+\]$")
	if p.match(migration_type):
		return 'double'

	p = re.compile("^unique_decimal\[\d+\,\d+\]$")
	if p.match(migration_type):
		return 'double'

	type_map = {'boolean'          : 'bool', 
				'date'             : 'string', 
				'datetime'         : 'string', 
				'decimal'          : 'double', 
				'float'            : 'float', 
				'integer'          : 'integer', 
				'string'           : 'string', 
				'text'             : 'string', 
				'time'             : 'string', 
				'timestamp'        : 'string',
				'unique_date'      : 'string', 
				'unique_datetime'  : 'string', 
				'unique_decimal'   : 'double', 
				'unique_float'     : 'float', 
				'unique_integer'   : 'integer', 
				'unique_string'    : 'string', 
				'unique_time'      : 'string', 
				'unique_timestamp' : 'string'}

	return type_map[migration_type]

def migration_type_to_d_type(migration_type):
	return sql_type_to_d_type(migration_type_to_sql_type(migration_type))

def convert_string_to_d_type(d_type, d_string_variable_name):
	cast_map = { 'int' : 'to_int(#)',
				'long' : 'to_long(#)',
				'ulong' : 'to_ulong(#)',
				'float' : 'to_float(#)',
				'double' : 'to_double(#)',
				'bool' : 'to_bool(#)',
				'char' : '#',
				'string' : 'to_s(#)',
				'FixedPoint' : 'to_FixedPoint(#)' }

	return cast_map[d_type].replace('#', d_string_variable_name)

def convert_d_type_to_string(d_type, d_string_variable_name):
	cast_map = { 'int' : 'to_s(#)',
				'long' : 'to_s(#)',
				'ulong' : 'to_s(#)',
				'float' : 'to_s(#)',
				'double' : 'to_s(#)',
				'bool' : 'to_s(#)',
				'char' : '#',
				'string' : 'to_s(#)',
				'FixedPoint' : 'to_s(#)' }

	return cast_map[d_type].replace('#', d_string_variable_name)

class Blacklist(object):
	def __init__(self):
		# Load the blacklist
		exec_file(rootintootin_path + '/bin/blacklist.py', globals(), locals())
		self._blacklist = locals()['blacklist']

	def check_blacklist(self, name):
		if name.lower() in self._blacklist:
			print("The name '" + name + "' is blacklisted and cannnot be used. Exiting ...")
			exit()

class Generator(object):
	def __init__(self):
		self._db = None
		self._mode = None
		self._config = None
		self._nouns = None
		self.load_configuration()
		self.load_nouns()

	def set_mode(self, mode):
		self._mode = mode

	def singularize(self, noun):
		for singular, plural in self._nouns.items():
			if noun == singular or noun == plural:
				return singular
			elif noun == singular.capitalize() or noun == plural.capitalize():
				return singular.capitalize()

		raise Exception("No noun found for: '" + noun + "'.")

	def pluralize(self, noun):
		for singular, plural in self._nouns.items():
			if noun == singular or noun == plural:
				return plural
			elif noun == singular.capitalize() or noun == plural.capitalize():
				return plural.capitalize()

		raise Exception("No noun found for: '" + noun + "'.")

	def check_pluralization(self, noun):
		try:
			self.pluralize(noun)
		except:
			print "No noun called '" + noun + "' found."
			print "Please add it using './gen create noun singular:blah plural:blahs'"
			print "Exiting ..."
			exit()

	def create_table(self, table_name, field_map):
		self.connect_to_database()

		# Create the query that will create the table
		db_name = self._config[self._mode]['database']['name']
		query = "create table `" + db_name + "`.`" + table_name + "` ("
		query += "id int not null auto_increment primary key, "
		for field_name, field_type in field_map.items():
			if field_type == "reference":
				query += "`" + field_name + "_id` int not null, "
				query += "foreign key(`" + field_name + "_id`) references `" + self.pluralize(field_name) + "`(`id`), "
			else:
				query += "`" + field_name + "` " + migration_type_to_sql_type(field_type) + " " + migration_type_default_sql_value(field_type) + ", "
		for field_name, field_type in field_map.items():
			if field_type.startswith('unique_'):
				query += "CONSTRAINT uc_" + field_name + " UNIQUE(`" + field_name + "`),"
		query = query.rstrip(', ')
		query += ") ENGINE=innoDB;"

		cursor = self._db.cursor()

		# Try running the query
		try:
			cursor.execute(query)
			print "Created the table '" + table_name + "'."
		except MySQLdb.OperationalError:
			raise Exception("Table '" + table_name + "' already exists.")
		finally:
			cursor.close()

	def drop_table(self, table_name):
		self.connect_to_database()

		# Create the query that will drop the table
		db_name = self._config[self._mode]['database']['name']
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

		# Create the database
		cursor = self._db.cursor()
		db_name = self._config[self._mode]['database']['name']
		try:
			cursor.execute("create database " + db_name)
			print "Created the database '" + self._config[self._mode]['database']['name'] + "'."
		except MySQLdb.ProgrammingError:
			print "Database '" + self._config[self._mode]['database']['name'] + "' already exists."
		finally:
			cursor.close()

		# Add the schema version table
		try:
			self.create_table("schema_version", {
				'version' : 'integer'
			})
		except Exception, err:
			print err

	def drop_database(self):
		self.connect_to_database()
		cursor = self._db.cursor()
		db_name = self._config[self._mode]['database']['name']
		try:
			cursor.execute("drop database " + db_name)
			print "Dropped the database '" + self._config[self._mode]['database']['name'] + "'."
		except MySQLdb.OperationalError:
			print "Database '" + self._config[self._mode]['database']['name'] + "' does not exists."
		cursor.close()

	def create_migration(self, model_name, pairs):
		# Get the name singularized
		model_name = self.singularize(model_name)

		# Get the last schema version
		last_version = self.get_schema_version_from_files()
		version = str(last_version + 1).rjust(4, '0')

		# Get the files and parameters
		params = {
			'model_name' : model_name, 
			'pairs' : pairs, 
			'pluralize' : self.pluralize
		}
		template_file = rootintootin_path + 'src/templates/0000_create_model.py.mako'
		out_file = 'db/migrate/' + version + '_create_' + self.pluralize(model_name) + '.py'

		# Generate the file from the template
		self.generate_template(params, template_file, out_file)

	def create_model(self, model_name, pairs):
		# Get the name singularized
		model_name = self.singularize(model_name)

		# Add the validates params
		validates = {}
		has_validates = False
		for pair in pairs:
			if pair == 'validates':
				has_validates = True
			elif has_validates:
				key, value = pair.split(':')
				if not value in validates:
					validates[value] = []
				validates[value].append(key)

		# Get the files and parameters
		params = {
			'model_name' : model_name, 
			'validates' : validates
		}
		template_file = rootintootin_path + 'src/templates/model.d.mako'
		out_file = 'app/models/' + model_name + '.d'

		# Generate the file from the template
		self.generate_template(params, template_file, out_file)

	def create_scaffold(self, controller_name, pairs):
		# Make sure the field types are valid
		for pair in pairs:
			key, value = pair.split(':')
			if not is_valid_migration_type(value):
				print "The type '" + str(value) + "' is not a valid migration type. Exiting ..."
				exit()

		# Get the name singularized
		controller_name = self.singularize(controller_name)

		# Make sure the view dir exists
		if not os.path.isdir('app/views/' + self.pluralize(controller_name)):
			os.mkdir('app/views/' + self.pluralize(controller_name))

		# Get the files and parameters
		params = {
			'controller_name' : controller_name, 
			'controller_names' : self.pluralize(controller_name), 
			'model_name' : controller_name, 
			'pairs' : pairs, 
			'pluralize' : self.pluralize, 
			'migration_type_to_html_type' : migration_type_to_html_type,
			'migration_type_to_d_type' : migration_type_to_d_type
		}
		template_file = rootintootin_path + 'src/templates/name_controller.d.mako'
		out_file = 'app/controllers/' + controller_name + '_controller.d'

		# Generate name_controller.d
		self.generate_template(params, template_file, out_file)

		# Generate index.html.ed
		self.generate_template(
			params, 
			rootintootin_path + 'src/templates/index.html.ed.mako', 
			'app/views/' + self.pluralize(controller_name) + '/index.html.ed')

		# Generate edit.html.ed
		self.generate_template(
			params, 
			rootintootin_path + 'src/templates/edit.html.ed.mako', 
			'app/views/' + self.pluralize(controller_name) + '/edit.html.ed')

		# Generate new.html.ed
		self.generate_template(
			params, 
			rootintootin_path + 'src/templates/new.html.ed.mako', 
			'app/views/' + self.pluralize(controller_name) + '/new.html.ed')

		# Generate show.html.ed
		self.generate_template(
			params, 
			rootintootin_path + 'src/templates/show.html.ed.mako', 
			'app/views/' + self.pluralize(controller_name) + '/show.html.ed')

	def migrate(self):
		self.connect_to_database()

		# Get the last schema version
		last_version = self.get_schema_version_from_db()

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
				self.save_schema_version(version)
			except Exception as err:
				print "Broke on migration file: '" + migration_file + "'."
				print err.message
				return

	def configure_database(self, pairs):
		# Add each key-value pair to the configuration hash
		for pair in pairs:
			key, value = pair.split(':')

			if key == 'user':
				self._config[self._mode]['database']['user'] = value
			elif key == 'password':
				self._config[self._mode]['database']['password'] = value
			elif key == 'name':
				self._config[self._mode]['database']['name'] = value

		self.save_configuration()

	def configure_server(self, pairs):
		# Add each key-value pair to the configuration hash
		for pair in pairs:
			key, value = pair.split(':')

			if key == 'port':
				self._config[self._mode]['server']['port'] = value
			elif key == 'max_waiting_clients':
				self._config[self._mode]['server']['max_waiting_clients'] = value
			elif key == 'header_max_size':
				self._config[self._mode]['server']['header_max_size'] = value
			elif key == 'directory':
				self._config[self._mode]['server']['directory'] = value
			elif key == 'httpd':
				self._config[self._mode]['server']['httpd'] = value
			elif key == 'ip':
				self._config[self._mode]['server']['ip'] = value
			elif key == 'user':
				self._config[self._mode]['server']['user'] = value

		self.save_configuration()

	def configure_routes(self, model_name, pairs):
		model_name = self.pluralize(model_name)

		f = open('config/routes.json', 'w')

		f.write(
			"{\n" + 
			"	\"routes\" : 	{\"" + model_name + "\" : \n" + 
			"		{\"index\"  : {\"^/" + model_name + "$\"        : \"GET\"}, \n" + 
			"		 \"create\" : {\"^/" + model_name + "$\"        : \"POST\"}, \n" + 
			"		 \"new\"    : {\"^/" + model_name + "/new$\"    : \"GET\"}, \n" + 
			"		 \"show\"   : {\"^/" + model_name + "/\\\\d+$\"      : \"GET\"}, \n" + 
			"		 \"update\" : {\"^/" + model_name + "/\\\\d+$\"      : \"PUT\"}, \n" + 
			"		 \"edit\"   : {\"^/" + model_name + "/\\\\d+;edit$\" : \"GET\"}, \n" + 
			"		 \"destroy\" : {\"^/" + model_name + "/\\\\d+$\"      : \"DELETE\"}}\n" + 
			"	}\n" + 
			"}"
		)

		f.close()

	def create_noun(self, pairs):
		singular, plural = None, None

		for pair in pairs:
			key, value = pair.split(':')

			if key == 'singular':
				singular = value
			elif key == 'plural':
				plural = value

		# Don't allow the plural and singular nouns are the same.
		if plural == singular:
			print "The singular and plural nouns cannot be the same."
			exit()

		self._nouns[singular] = plural
		self.save_nouns()

#private

	def load_configuration(self):
		with open('config/config.json', 'r') as f:
			self._config = json.loads(f.read())

	def save_configuration(self):
		with open('config/config.json', 'w') as f:
			f.write(json.dumps(self._config, sort_keys=True, indent=4))

	def load_nouns(self):
		with open('config/nouns.json', 'r') as f:
			self._nouns = json.loads(f.read())["nouns"]

	def save_nouns(self):
		f = open('config/nouns.json', 'w')

		f.write("\n{\n")
		f.write("\n	\"nouns\" : {\n")
		lines = []
		for key, value in self._nouns.items():
			lines.append("		\"" + key + "\" : \"" + value + "\"")
		f.write(str.join(", \n", lines))
		f.write("	}\n")
		f.write("}\n")

		f.close()

	def connect_to_database(self):
		if self._db != None:
			return

		try:
			self._db = MySQLdb.connect(
						host = self._config[self._mode]['database']['host'], 
						user = self._config[self._mode]['database']['user'], 
						passwd = self._config[self._mode]['database']['password'])
		except MySQLdb.OperationalError, err:
			if err.args[0] == 2002:
				print "Can't connect to the mysql server. Make sure it is running. Exiting ..."
			elif err.args[0] == 1045:
				print "Can't log into the mysql server. Make sure the user name and password are correct in config/config.json. Exiting ..."
			else:
				print "MySQL error# " + str(err.args[0]) + " : " + err.args[1]
			exit()

	def get_schema_version_from_files(self):
		# Get all the migration files
		migration_files = os.listdir('db/migrate/')
		migration_files.sort()

		# Return zero if there are no files
		if len(migration_files) == 0:
			return 0

		# Return the version of the last file
		return int(migration_files[-1][0:4])

	def get_schema_version_from_db(self):
		self.connect_to_database()

		db_name = self._config[self._mode]['database']['name']
		query = "select max(version) from `" + db_name + "`.`schema_version`;"
		cursor = self._db.cursor()
		cursor.execute(query)
		version = cursor.fetchone()
		cursor.close()
		if version[0] == None:
			return 0
		else:
			return int(version[0])

	def save_schema_version(self, version):
		db_name = self._config[self._mode]['database']['name']

		query = "insert into `" + db_name + \
		"`.`schema_version`(version) values('" + \
		str(version) + "');"

		self._db.query(query)
		self._db.commit()

	def generate_template(self, params, template_file, out_file):
		from mako.template import Template
		from mako.lookup import TemplateLookup
		from mako import exceptions

		template_dir = os.path.dirname(template_file) + '/'
		template_name = os.path.basename(template_file)

		with open(out_file, 'w') as view_file:
			try:
				lookup = TemplateLookup(directories=[template_dir], output_encoding='utf-8')
				template = lookup.get_template(template_name)
				view_file.write(template.render(**params).replace("@@", "%"))
			except:
				print "Broken template file: '" + template_file + "'"
				print exceptions.text_error_template().render()
				print "Exiting ..."
				exit()


