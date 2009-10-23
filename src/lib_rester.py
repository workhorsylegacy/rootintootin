#!/usr/bin/env python2.6

import os, sys, re
import commands, pexpect
import platform
import MySQLdb

rester_path = os.path.dirname(os.sys.path[0]) + '/'

def exec_file(file, globals, locals):
	with open(file, "r") as fh:
		exec(fh.read()+"\n", globals, locals)

def pluralize(value):
	if value.endswith('s'):
		return value
	else:
		return value + 's'

def camelize(word):
	return ''.join(w[0].upper() + w[1:] for w in re.sub('[^A-Z^a-z^0-9^:]+', ' ', word).split(' '))

def sql_type_to_d_type(sql_type):
	type_map = { 'tinyint(1)' : 'bool',
				 'varchar(255)' : 'char[]',
				 'datetime' : 'char[]',
				 'int(11)' : 'ulong',
				 'text' : 'char[]' }

	return type_map[sql_type]

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

def migration_type_to_d_type(migration_type):
	return sql_type_to_d_type(migration_type_to_sql_type(migration_type))

def convert_string_to_d_type(d_type, d_string_variable_name):
	cast_map = { 'int' : 'to_int(#)',
				'long' : 'to_long(#)',
				'ulong' : 'to_ulong(#)',
				'float' : 'to_float(#)',
				'bool' : 'to_bool(#)',
				'char' : '#',
				'char[]' : 'to_s(#)' }

	return cast_map[d_type].replace('#', d_string_variable_name)

def convert_d_type_to_string(d_type, d_string_variable_name):
	cast_map = { 'int' : 'to_s(#)',
				'long' : 'to_s(#)',
				'ulong' : 'to_s(#)',
				'float' : 'to_s(#)',
				'bool' : 'to_s(#)',
				'char' : '#',
				'char[]' : 'to_s(#)' }

	return cast_map[d_type].replace('#', d_string_variable_name)

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
				query += "`" + field_name + "` " + migration_type_to_sql_type(field_type) + ", "
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

		f = open('db/migrate/' + version + '_create_' + pluralize(model_name) + '.py', 'w')

		f.write(
			"class Create" + pluralize(model_name.capitalize()) + ":\n" +
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

	def create_model(self, model_name, pairs):
		f = open('app/models/' + model_name + '.d', 'w')

		f.write(
			"\n\n" + 
			"import " + model_name + "_base;\n\n" +
			"public class " + model_name.capitalize() + " : " + model_name.capitalize() + "Base {\n\n" + 
			"}\n\n"
		)

		f.close()

	def create_scaffold(self, controller_name, pairs):
		f = open('app/controllers/' + controller_name + '_controller.d', 'w')

		# Add the class opening
		f.write(
			"\n\n" + 
			"import rester;\n" + 
			"import " + controller_name + ";\n\n" + 
			"public class " + controller_name.capitalize() + "Controller : ControllerBase {\n"
		)

		# Add each property
		f.write(
			"	public " + controller_name.capitalize() + "[] _" + controller_name + "s;\n" + 
			"	public " + controller_name.capitalize() + " _" + controller_name + ";\n" + 
			"\n"
		)

		# Add the index action
		f.write(
			"	public void index() {\n" + 
			"		_" + controller_name + "s = " + controller_name.capitalize() + ".find_all();\n" + 
			"	}\n\n"
		)

		# Add the show action
		f.write(
			"	public void show() {\n" + 
			"		_" + controller_name + " = " + controller_name.capitalize() + ".find(to_ulong(_request.params[\"id\"]));\n" + 
			"	}\n\n"
		)

		# Add the new action
		f.write(
			"	public void New() {\n" + 
			"		_" + controller_name + " = new " + controller_name.capitalize() + "();\n" + 
			"	}\n\n"
		)

		# Add the create action
		f.write(
			"	public void create() {\n" + 
			"		_" + controller_name + " = new " + controller_name.capitalize() + "();\n"
		)
		for field in pairs:
			field_name, field_type = field.split(':')
			f.write("\t\t_" + controller_name + "." + field_name + " = to_" + field_type + "(_request.params[\"" + controller_name + "[" + field_name + "]\"]);\n")
		f.write(
			"\n" + 
			"		if(_" + controller_name + ".save()) {\n" + 
			"			flash_notice(\"The " + controller_name + " was saved.\");\n" + 
			"			redirect_to(\"/" + controller_name + "s/show/\" ~ to_s(_" + controller_name + ".id));\n" + 
			"		} else {\n" + 
			"			render_view(\"new\");\n" + 
			"		}\n" + 
			"	}\n\n"
		)

		# Add the edit action
		f.write(
			"	public void edit() {\n" + 
			"		_" + controller_name + " = " + controller_name.capitalize() + ".find(to_ulong(_request.params[\"id\"]));\n" + 
			"	}\n\n"
		)

		# Add the create update
		f.write(
			"	public void update() {\n" + 
			"		_" + controller_name + " = " + controller_name.capitalize() + ".find(to_ulong(_request.params[\"id\"]));\n"
		)
		for field in pairs:
			field_name, field_type = field.split(':')
			f.write("\t\t_" + controller_name + "." + field_name + " = to_" + field_type + "(_request.params[\"" + controller_name + "[" + field_name + "]\"]);\n")
		f.write(
			"\n" + 
			"		if(_" + controller_name + ".save()) {\n" + 
			"			flash_notice(\"The " + controller_name + " was updated.\");\n" + 
			"			redirect_to(\"/" + controller_name + "s/show/\" ~ to_s(_" + controller_name + ".id));\n" + 
			"		} else {\n" + 
			"			render_view(\"edit\");\n" + 
			"		}\n" + 
			"	}\n\n"
		)

		# Add the destroy event
		f.write(
			"	public void destroy() {\n" + 
			"		_" + controller_name + " = " + controller_name.capitalize() + ".find(to_ulong(_request.params[\"id\"]));\n" + 
			"		if(_" + controller_name + ".destroy()) {\n" + 
			"			redirect_to(\"/" + controller_name + "s/index\");\n" + 
			"		} else {\n" + 
			"			flash_error(_" + controller_name + ".errors()[0]);\n" + 
			"			render_view(\"index\");\n" + 
			"		}\n" + 
			"	}\n"
		)

		# End the class
		f.write("}\n\n")

		f.close()

		# Add the views
		if not os.path.isdir('app/views/' + controller_name):
			os.mkdir('app/views/' + controller_name)
		params = {
			'model_name' : controller_name,
			'pairs' : pairs
		}

		self.generate_template(
			params, 
			rester_path + 'src/templates/index.html.ed.py', 
			'app/views/' + controller_name + '/index.html.ed')

		self.generate_template(
			params, 
			rester_path + 'src/templates/edit.html.ed.py', 
			'app/views/' + controller_name + '/edit.html.ed')

		self.generate_template(
			params, 
			rester_path + 'src/templates/new.html.ed.py', 
			'app/views/' + controller_name + '/new.html.ed')

		self.generate_template(
			params, 
			rester_path + 'src/templates/show.html.ed.py', 
			'app/views/' + controller_name + '/show.html.ed')

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

	def configure_routes(self, model_name, pairs):
		f = open('config/routes.py', 'w')

		f.write(
			"routes = {'" + model_name + "' : { 'member' : { 'show' : 'get',\n" + 
			"								'new' : 'get',\n" + 
			"								'create' : 'post',\n" + 
			"								'edit' : 'get',\n" + 
			"								'update' : 'put',\n" + 
			"								'destroy' : 'delete' }\n" + 
			"					,\n" + 
			"					'collection' : { 'index' : 'get' }\n" + 
			"					}\n" + 
			"}"
		)

		f.close()


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


