#!/usr/bin/env python
# -*- coding: UTF-8 -*-
#-------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-------------------------------------------------------------------------------

import os, sys, shutil, signal, subprocess
import inspect
import threading, time, distutils.core
import errno
import functools
import commands
import json
import platform, re
from lib_rootintootin import *

def __line__():
	return str(inspect.getframeinfo(inspect.currentframe().f_back)[1])

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

# Determine the OS specific locations of libraries
tango, mysql, pcre = None, None, None
os_name = platform.dist()[0].lower()
if os_name in ['ubuntu', 'debian']:
	tango = "-I ~/tango-bundle/import/ -L ~/tango-bundle/lib/libtango-ldc.a"
	mysql = "/usr/lib/libmysqlclient"
	if os.path.exists("/usr/lib/" + arch + "-linux-gnu/libpcre.a"):
		pcre = "/usr/lib/" + arch + "-linux-gnu/libpcre.a"
	elif os.path.exists("/usr/lib/libpcre.a"):
		pcre = "/usr/lib/libpcre.a"
elif os_name == "fedora":
	tango = "-I ~/tango-bundle/import/ -L ~/tango-bundle/lib/libtango-ldc.a"
	if bits == '32':
		mysql = "/usr/lib/mysql/libmysqlclient"
	elif bits == '64':
		mysql = "/usr/lib64/mysql/libmysqlclient"
elif os_name == 'suse':
	tango = "-I ~/tango-bundle/import/ -L ~/tango-bundle/lib/libtango-ldc.a"
	mysql = "/usr/lib/libmysqlclient"
else:
	print "Unknown Operating System. Please update the code '" + __file__ + \
	"' around line " + __line__() + " to be able to detect your OS. Exiting ..."
	exit()


def _model_generated_properties_class(model_name, model_map, reference_map, model_names):
	generator = Generator()
	generator.set_mode(mode)
	# Add class opening
	properties = \
			"private import rootintootin;\n" + \
			"private import tango.text.json.Json;\n" + \
			"private import tango.text.xml.Document;\n" + \
			"private import tango.text.xml.DocPrinter;\n\n"

	for entry in model_names:
		properties += "private import " + entry + ";\n"
		if model_name != entry:
			properties += "private import " + entry + "_base;\n"
	properties += "\n"

	properties += "public class " + model_name.capitalize() + "Base : ModelBase {\n"
	properties += "	mixin ModelBaseMixin!(" + model_name.capitalize() + ", \"" + model_name + "\", \""+ generator.pluralize(model_name) + "\");\n\n"

	# Add a list of all field names
	properties += "	protected static string[] _field_names = ["
	for field, values in model_map.items():
		properties += "\"" + field + "\", ";
	properties += "];\n\n";

	# Add a list of the unique field names
	properties += "	protected static string[] _unique_field_names = ["
	for field, values in model_map.items():
		if field == "id":
			continue
		properties += "\"" + field + "\", ";
	properties += "];\n\n";

	# Add all the fields with default values
	for field, values in model_map.items():
		if not field.endswith('_id'):
			properties += "	protected " + sql_type_to_d_type(values['type']) + " _" + field + " = " + sql_type_to_default_d_value(values['type']) + ";\n"

	# Add the field properties
	for field, values in model_map.items():
		if field.endswith('_id'):
			continue

		# Add getter
		properties += \
						"	// " + values['type'] + "\n" + \
						"	public " + sql_type_to_d_type(values['type']) + " " + field + "() {\n" + \
						"		ensure_was_pulled_from_database();\n" + \
						"		return _" + field + ";\n" + \
						"	}\n"
		# Add setter, but not for id
		if field != 'id':
			properties += \
						"	public void " + field + "(" + sql_type_to_d_type(values['type']) + " value) {\n" + \
						"		ensure_was_pulled_from_database();\n" + \
						"		_" + field + " = value;\n" + \
						"	}\n"

	# Add the belongs_to references
	for table_name, has_manys in reference_map.iteritems():
		table_name = table_name[:-1]
		for has_many in has_manys:
			if has_many[:-1] == model_name:
				properties += \
						"	public " + table_name.capitalize() + "Base _" + table_name + " = null;\n" + \
						"\n" + \
						"	public void parent(" + table_name.capitalize() + "Base value) {\n" + \
						"		ensure_was_pulled_from_database();\n" + \
						"		_" + table_name + " = value;\n" + \
						"	}\n" + \
						"	public " + table_name.capitalize() + "Base parent() {\n" + \
						"		ensure_was_pulled_from_database();\n" + \
						"		return _" + table_name + ";\n" + \
						"	}\n"
	
	# Add the has_many references
	table_name = generator.pluralize(model_name)
	if table_name in reference_map:
		for has_many in reference_map[table_name]:
			has_many = has_many[:-1]
			has_manies = generator.pluralize(has_many)
			properties += \
					"	protected class " + has_many.capitalize() + "s {\n" + \
					"		mixin ModelArrayMixin!(" + model_name.capitalize() + "Base, \n" + \
					"								" + has_many.capitalize() + "Base);\n" + \
					"	}\n" + \
					"\n" + \
					"	protected " + has_manies.capitalize() + " _" + has_manies + ";\n\n" + \
					"	public void after_this() {\n" + \
					"		_" + has_manies + " = new " + has_manies.capitalize() + "(\n" + \
 					"		" + has_many.capitalize() + "Base.find_all(where(_model_name ~ \"_id = \" ~ to_s(_id)))\n" + \
					"		);\n" + \
					"	}\n\n" + \
					"	public void " + has_manies + "(" + has_manies.capitalize() + " value) {\n" + \
					"		ensure_was_pulled_from_database();\n" + \
					"		_" + has_manies + " = value;\n" + \
					"	}\n" + \
					"	public " + has_manies.capitalize() + " " + has_manies + "() {\n" + \
					"		ensure_was_pulled_from_database();\n" + \
					"		return _" + has_manies + ";\n" + \
					"	}\n"


	# Add the set_field_by_name method
	properties += \
				"	public void set_field_by_name(string field_name, string value, bool must_check_database_first = true) {\n" + \
				"		if(must_check_database_first)\n" + \
				"			ensure_was_pulled_from_database();\n\n" + \
				"		switch(field_name) {\n"

	for field, values in model_map.items():
		if field.endswith('_id'):
			reference_type = field.split('_id')[0]
			value_with_cast = convert_string_to_d_type(sql_type_to_d_type(values['type']), 'value')
			properties += \
					"			case \"" + field + "\":\n" + \
					"				_" + reference_type + " = new " + reference_type.capitalize() + "();\n" + \
					"				_" + reference_type + ".set_field_by_name(\"id\", value, false);\n" + \
					"				_" + reference_type + "._was_pulled_from_database = false;\n" + \
					"				break;\n"
		else:
			value_with_cast = convert_string_to_d_type(sql_type_to_d_type(values['type']), 'value')
			properties += \
					"			case \"" + field + "\":\n" + \
					"				_" + field + " = " + value_with_cast + ";\n" + \
					"				break;\n"

	properties += \
				"			default:\n" + \
				"				break;\n" + \
				"		}\n" + \
				"	}\n"

	# Add the get_field_by_name method
	properties += \
				"	public string get_field_by_name(string field_name) {\n" + \
				"		switch(field_name) {\n"

	for field, values in model_map.items():
		if field.endswith('_id'):
			reference_type = field.split('_id')[0]
			value_to_string = convert_d_type_to_string(sql_type_to_d_type(values['type']), "_" + field)
			properties += \
					"			case \"" + field + "\":\n" + \
					"				return _" + reference_type + " is null ? null : to_s(_" + reference_type + ".id);\n"
		else:
			value_to_string = convert_d_type_to_string(sql_type_to_d_type(values['type']), "this." + field)
			properties += \
					"			case \"" + field + "\":\n" + \
					"				return " + value_to_string + ";\n"

	properties += \
				"			default:\n" + \
				"				break;\n" + \
				"		}\n" + \
				"		return null;\n" + \
				"	}\n"

	# Add the to_json method
	properties += \
				"	public string to_json() {\n" + \
				"		return \"{}\";/*auto jsoner = new Json!(char);\n" + \
				"		with(jsoner)\n" + \
				"			value = object(pair(\"" + model_name + "\", object(\n"

	model_map_len = len(model_map)
	for field, values in model_map.items():
		comma = ", "
		if model_map_len == 1:
			comma = ""
		if field.endswith('_id'):
			reference_type = field.split('_id')[0]
			properties += \
				"						pair(\"" + field + "\", value(_" + reference_type + ".id))" + comma + "\n"
		elif values['type'].startswith('decimal'):
			properties += \
				"						pair(\"" + field + "\", value(_" + field + ".toDouble()))" + comma + "\n"
		else:
			properties += \
				"						pair(\"" + field + "\", value(_" + field + "))" + comma + "\n"
		model_map_len -= 1

	properties += \
				"			)));\n" + \
				"\n" + \
				"		char[] data = \"\";\n" + \
				"		jsoner.print((char[] s) {\n" + \
				"			data ~= s;\n" + \
				"		});\n" + \
				"		return data;*/\n" + \
				"	}\n"

	# Add the to_xml method
	properties += \
				"	public string to_xml() {\n" + \
				"		auto doc = new Document!(char);\n" + \
				"		auto top = doc.tree.element(null, \"" + model_name + "\");\n" + \
				"\n"

	for field, values in model_map.items():
		if field.endswith('_id'):
			reference_type = field.split('_id')[0]
			properties += \
				"		top.element(null, \"" + field + "\")\n" + \
				"			.data(to_s(_" + reference_type + ".id))\n" + \
				"			.attribute(null, \"type\", \"" + sql_type_to_xml_type(values['type']) + "\");\n"
		else:
			properties += \
				"		top.element(null, \"" + field + "\")\n" + \
				"			.data(to_s(_" + field + "))\n" + \
				"			.attribute(null, \"type\", \"" + sql_type_to_xml_type(values['type']) + "\");\n"

	properties += \
				"\n" + \
				"		auto printer = new DocPrinter!(char);\n" + \
				"		return printer.print(doc);\n" + \
				"	}\n"

	# Add class closing
	properties += "}"

	return properties


def _generate_models():
	# Connect to the database
	generator = Generator()
	generator.set_mode(mode)
	db = None
	try:
		db = MySQLdb.connect(host = config[mode]['database']['host'], 
							user = config[mode]['database']['user'], 
							passwd = config[mode]['database']['password'], 
							db = config[mode]['database']['name'])
	except MySQLdb.OperationalError, err:
		if err.args[0] == 2002:
			print "Can't connect to the mysql server. Make sure it is running. Exiting ..."
		elif err.args[0] == 1045:
			print "Can't log into the mysql server. Make sure the user name and password are correct in config/config.json. Exiting ..."
		else:
			print "MySQL error# " + str(err.args[0]) + " : " + err.args[1]
		exit()

	# Get all the tables
	table_map = {}
	cursor = db.cursor()
	cursor.execute("show tables;")
	result = cursor.fetchall()
	for row in result:
		table_map[row[0]] = {}
	cursor.close()

	# Get the fields for each table
	for table in table_map:
		cursor = db.cursor()
		cursor.execute('desc ' + table + ';')
		result = cursor.fetchall()

		for row in result:
			field = row[0]

			table_map[table][field] = {}
			table_map[table][field]['type'] = row[1]
			table_map[table][field]['null'] = row[2]
			table_map[table][field]['key'] = row[3]
			table_map[table][field]['default'] = row[4]
			table_map[table][field]['extra'] = row[5]

		cursor.close()

	# Add the relationships to the table
	reference_map = {}
	for table, fields in table_map.items():
		cursor = db.cursor()
		query = "select column_name, referenced_table_name, referenced_column_name from " + \
				"information_schema.key_column_usage where " + \
				"table_schema='" + config[mode]['database']['name'] + "' " + \
				"and table_name='" + table + "' and " + \
				"referenced_table_name is not null and referenced_column_name is not null;"
		cursor.execute(query)
		result = cursor.fetchall()

		for row in result:
			column_name, referenced_table_name, referenced_column_name = row
			if not referenced_table_name in reference_map:
				reference_map[referenced_table_name] = []
			reference_map[referenced_table_name].append(table)

		cursor.close()

	# Get the names of all the models
	model_names = []
	for entry in os.listdir('app/models/'):
		if entry.endswith('.d'):
			model_names.append(str.split(entry, '.')[0])

	# Write the generated model base classes into the files
	for model_name in model_names:
		model_map = table_map[generator.pluralize(model_name)]

		with open(model_name + '_base.d', 'w') as f:
			f.write("\n\n")
			f.write(_model_generated_properties_class(model_name, model_map, reference_map, model_names))
			f.write("\n\n")

		with open('app/models/' + model_name + '.d', 'r') as f_in:
			with open(model_name + '.d', 'w') as f_out:
				f_out.write(f_in.read())

	return table_map, reference_map

def _generate_controllers():
	for controller in os.listdir('app/controllers/'):
		if not controller.endswith('.d'):
			continue

		with open('app/controllers/' + controller, 'r') as f_in:
			with open(controller, 'w') as f_out:
				f_out.write(f_in.read())

def _generate_views(routes):
	generator = Generator()
	generator.set_mode(mode)

	# Get the names of all the models
	model_names = []
	for entry in os.listdir('app/models/'):
		if entry.endswith('.d'):
			model_names.append(str.split(entry, '.')[0])

	for controller, route_maps in routes.items():
		for member, route_map in route_maps.items():
			# If there is no template, then skip it
			if not os.path.exists('app/views/' + controller + '/' + member + '.html.ed'):
				continue

			# Get the template file as a string
			f = open('app/views/' + controller + '/' + member + '.html.ed', 'r')
			body = f.read()
			f.close()

			# Print the openining of the function
			output = []
			output.append(
			"private import rootintootin;" +
			"private import ui;")

			for model_name in model_names:
				output.append("private import " + generator.singularize(model_name) + ";")

			for controller_name, route_maps in routes.items():
				output.append("private import " + generator.singularize(controller_name) + "_controller;")

			output.append(
			"private import view_layouts_default;" +
			"public class " + controller.capitalize() + member.capitalize() + "View { " +
			"public static string render(" + generator.singularize(controller).capitalize() + "Controller controller) { " +
			"set_controller(controller);"
			"AutoStringArray b = new AutoStringArray();")

			_process_template_body(body, output)

			# Print the closing of the function
			output.append(
			"\n" +
			"	if(controller.use_layout) {\n" + 
			"		return DefaultLayout.render(controller, b.toString()); \n" + 
			"	} else {\n" + 
			"		return b.toString(); \n" + 
			"	}\n"
			"}\n" +
			"}\n")

			# Save the output as a D file
			out_file = open('view_' + controller + '_' + member + '.d', 'w')
			for fragment in output:
				out_file.write(fragment)
			out_file.close()

def _generate_layouts():
	for layout in os.listdir('app/views/layouts/'):
		if not layout.endswith('.html.ed'):
			continue
		layout = layout[0:-8]

		# Get the layout file as a string
		f = open('app/views/layouts/' + layout + '.html.ed', 'r')
		body = f.read()
		f.close()

		# Print the openining of the function
		output = []
		output.append(
		"private import rootintootin;" +
		"private import ui;" +
		"public class " + layout.capitalize() + "Layout { " +
		"public static string render(ControllerBase controller, string yield) { " +
		"AutoStringArray b = new AutoStringArray();")

		_process_template_body(body, output)

		# Print the closing of the function
		output.append(
		"\n	return b.toString(); \n" +
		"}\n" +
		"}\n")

		# Save the output as a D file
		out_file = open('view_layouts_' + layout + '.d', 'w')
		for fragment in output:
			out_file.write(fragment)
		out_file.close()

def _generate_application(version, routes, table_map, reference_map, include_unit_test):
	generator = Generator()
	generator.set_mode(mode)

	# Get the names of all the views
	view_names = []
	for controller_name, route_maps in routes.items():
		for entry in os.listdir('app/views/' + controller_name):
			if entry.endswith('.html.ed'):
				view_names.append('view_' + controller_name + '_' + entry.split('.html.ed')[0])

	# Open the output file
	out_file = open('application.d', 'w')

	# Write the imports
	out_file.write(
		"\n" +
		"private import tango.io.Stdout;\n" +
		"private import tango.io.device.File;\n" +
		"private import tango.text.json.Json;\n\n" +
		"private import dlang_helper;\n" +
		"private import web_helper;\n" +
		"private import regex;\n" +
		"private import file_system;\n" +
		"private import rootintootin;\n" +
		"private import rootintootin_server;\n" +
		"private import rootintootin_process;\n\n"
	)

	for controller_name, route_maps in routes.items():
		out_file.write("private import " + generator.singularize(controller_name) + "_controller;\n")
	out_file.write("\n")

	for view_name in view_names:
		out_file.write("private import " + view_name + ";\n")
	out_file.write("\n")

	# Write the runner class
	out_file.write(
	"public class Runner : RunnerBase {\n")

	# Write the render view function
	for controller, route_maps in routes.items():
		out_file.write(
		"	private string generate_view(" + generator.singularize(controller).capitalize() + "Controller controller, string controller_name, string view_name) {\n")

		out_file.write(
		"		if(controller_name == \"" + generator.pluralize(controller) + "\") {\n")

		for action, route_map in route_maps.items():
			for uri, method in route_map.items():
				if method == "GET":
					out_file.write(
					"			if(view_name == \"" + action.capitalize() + "\" || view_name == \"" + action.lower() + "\") {\n" +
					"				return " + controller.capitalize() + action.capitalize() + "View.render(controller);\n" +
					"			}\n"
					)

		out_file.write("		}\n")
		out_file.write("		return \"Unknown view '\" ~ view_name ~ \"'\";\n")
		out_file.write("	}\n")


	# Write the run action function
	out_file.write(
	"	public string run_action(Request request, string controller_name, string action_name, string id, out string[] events_to_trigger) {\n")
	for controller, route_maps in routes.items():
		out_file.write(
		"		if(controller_name == \"" + generator.pluralize(controller) + "\") {\n" +
		"			" + generator.singularize(controller).capitalize() + "Controller controller = new " + generator.singularize(controller).capitalize() + "Controller();\n" + 
		"			controller.action_name = action_name;\n" + 
		"			controller.controller_name = controller_name;\n" + 
		"			controller.request = request;\n" + 
		"			try {\n" +
		"				switch(action_name) {\n"
		)

		for action, route_map in route_maps.items():
			real_action = action
			if action == "new":
				real_action = "New"
			elif action == "delete":
				real_action = "Delete"
			out_file.write(
				"					case \"" + action + "\": controller." + real_action + "(); break;\n")

		out_file.write(
			"					default: throw new RenderNoActionException();\n" + 
			"				}\n")
		out_file.write(
			"			} catch(RenderViewException err) {\n" + 
			"				return this.generate_view(controller, controller_name, err._name);\n" + 
			"			} finally {\n" + 
			"				events_to_trigger = controller._events_to_trigger;\n" + 
			"			}\n")
		out_file.write("		}\n")

	links = []
	for controller_name, route_maps in routes.items():
		links.append("\"" + controller_name + "\"")

	out_file.write(
	"		throw new RenderNoControllerException([" + str.join(', ', links) + "]);\n"
	)

	out_file.write("	}\n")
	out_file.write("}\n")

	port = str(int(config[mode]['server']['port']))
	max_waiting_clients = config[mode]['server']['max_waiting_clients']
	header_max_size = config[mode]['server']['header_max_size']
	db_host = config[mode]['database']['host']
	db_user = config[mode]['database']['user']
	db_password = config[mode]['database']['password']
	db_name = config[mode]['database']['name']

	if include_unit_test:
		out_file.write(
			"int main(){\n" + 
			"	print_test_status();\n" + 
			"	return 0;\n" + 
			"}\n\n"
		)
		return

	# Write the main function header
	out_file.write(
	"\n\nint main(string[] args) {\n")

	# Write the routes
	out_file.write(
	"	// Create the routes\n" + 
	"	string[Regex][string][string] routes;\n")
	for controller_name, route_maps in routes.iteritems():
		for action_name, route_map in route_maps.iteritems():
			for uri, method in route_map.iteritems():
				out_file.write("	routes[\"" + controller_name + "\"][\"" + action_name + "\"][new Regex(r\"" + uri + "\")] = \"" + method + "\";\n")

	# Write the server start in main
	out_file.write("""
	// Read the config from the config file
	auto file = new File("config/config.json", File.ReadExisting);
	auto content = new char[cast(size_t)file.length];
	file.read(content);
	file.close();
	auto values = (new Json!(char)).parse(content).toObject();

	string[string][string][string] config;
	foreach(n1, v1; values.attributes()) {
		foreach(n2, v2; v1.toObject().attributes()) {
			foreach(n3, v3; v2.toObject().attributes()) {
				config[n1][n2][n3] = v3.toString();
			}
		}
	}

""")

	out_file.write(" \
	// Create and start the app \n\
	string mode = \"" + mode + "\";\n\
	bool is_fcgi = contains(getcwd(), \"fastcgi\");\n\
	bool is_production = mode == \"production\";\n")

	out_file.write("""
	RunnerBase runner = new Runner();
	auto app = new RootinTootinAppProcess(
				is_fcgi, 
				"Rootin_Tootin_0.6.0", 
				runner, routes, 
				config[mode]["database"]["host"], 
				config[mode]["database"]["user"], 
				config[mode]["database"]["password"], 
				config[mode]["database"]["name"], 
				is_production);
	app.start();

	return 0;
}
""")

def _process_template_body(body, output):
	while len(body) > 0:
		# Get the location on the open and close brackets
		open_index = body.find("<%")
		close_index = body.find("%>")

		# raise if open but no close
		# raise if close before open

		# If there were no brackets, just print the last text as a string
		if open_index == -1 and close_index == -1:
			output.append(" b~= \"" + body.replace("\"", "\\\"") + "\";")
			break

		# Get the text before, after, and in between the brackets
		before = body[: open_index]
		middle = body[open_index+2 : close_index]
		after = body[close_index+2 :]

		# If there was text before the opening, print it as a string
		if len(before) > 0:
			output.append(" b~= \"" + before.replace("\"", "\\\"") + "\";")

		# Print the code between the brackets
		if len(middle) > 0:
			if middle[0] == "=":
				output.append(" b~= h(" + middle[1:] + ");")
			elif middle[0] == "#":
				output.append(" b~= " + middle[1:] + ";")
			else:
				output.append(" " + middle)

		# Set the remaining text as the body, so it can be processed next
		body = after

def copy_files_to_scratch(is_public_symlinked = True):
	# Copy all the framework files into a scratch dir
	if not os.path.exists(rootintootin_dir):
		os.mkdir(rootintootin_dir)

	# Copy the project files into the scratch dir
	distutils.dir_util.copy_tree(os.sys.path[0]+'/../src/', scratch)

	# Remove all the old app files
	if os.path.exists(scratch+'app/'):
		shutil.rmtree(scratch+'app/')
	if os.path.exists(scratch+'config/'):
		shutil.rmtree(scratch+'config/')
	if os.path.exists(scratch+'db/'):
		shutil.rmtree(scratch+'db/')
	if os.path.exists(scratch+'public/'):
		if os.path.islink(scratch+'public'):
			os.remove(scratch+'public')
		else:
			shutil.rmtree(scratch+'public/')
	if os.path.exists(scratch+'uploads/'):
		shutil.rmtree(scratch+'uploads/')

	# Copy all the app files into a scratch dir
	if os.path.exists(pwd+'/app/'):
		shutil.copytree(pwd+'/app/', scratch+'app/')
	if os.path.exists(pwd+'/config/'):
		shutil.copytree(pwd+'/config/', scratch+'config/')
	if os.path.exists(pwd+'/db/'):
		shutil.copytree(pwd+'/db/', scratch+'db/')
	if os.path.exists(pwd+'/public/'):
		if is_public_symlinked:
			os.symlink(pwd+'/public', scratch+'public')
		else:
			shutil.copytree(pwd+'/public/', scratch+'public/')
	os.mkdir(scratch+'uploads/')

def move_to_scratch():
	os.chdir(scratch)

def load_configurations():
	# Load the config files
	with open('config/routes.json', 'r') as f:
		globals()['routes'] = json.loads(f.read())['routes']

	with open('config/nouns.json', 'r') as f:
		globals()['nouns'] = json.loads(f.read())['nouns']

	with open('config/config.json', 'r') as f:
		globals()['config'] = json.loads(f.read())

	# Make sure the static libraries exist
	if config[mode]['server']['is_linked_statically']:
		libs = []
		if not os.path.exists("/usr/lib/libfcgi.a"):
			libs.append("Lib FastCGI")
		if not os.path.exists("/usr/lib/" + arch + "-linux-gnu/libpcre.a") and \
			not os.path.exists("/usr/lib/libpcre.a"):
			libs.append("Lib PCRE")
		if os_name in ['ubuntu', 'debian']:
			if not os.path.exists("/usr/lib/libmysqlclient.a"):
				libs.append("Lib MySQL")
		elif os_name == "fedora":
			if bits == '32':
				if not os.path.exists("/usr/lib/mysql/libmysqlclient.a"):
					libs.append("Lib MySQL")
			elif bits == '64':
				if not os.path.exists("/usr/lib64/mysql/libmysqlclient.a"):
					libs.append("Lib MySQL")

		if libs:
			print "The following static libraries are missing: " + str.join(', ', libs) + ". "
			print "Please install them, or change your config file to link dynamically: config/config.json > " + mode + " > server > is_linked_statically > false"
			exit()

def generate_application_files(include_unit_test = False):
	# Get the Rootin Tootin version
	f = open(scratch+'version')
	version = f.read().strip()
	f.close()

	# Do code generation
	table_map, reference_map = _generate_models()
	_generate_controllers()
	_generate_layouts()
	_generate_views(routes)
	_generate_application(version, routes, table_map, reference_map, include_unit_test)

def build_framework(include_unit_test = False):
	sys.stdout.write("Rebuilding framework ...".ljust(78, ' '))
	sys.stdout.flush()

	# FIXME: This needs to remove any .o, .a, .c, and .d files that are
	# not in the project, but in the scratch dir.

	# Compile the libs into object files
	is_library_changed = False
	result = ''
	if is_file_newer("db.c", "db.o"):
		if config[mode]['server']['is_linked_statically']:
			result += commands.getoutput("gcc -g -c -Wall -Werror db.c -o db.o -Wl,-static -lmysqlclient")
		else:
			result += commands.getoutput("gcc -g -c -Wall -Werror db.c -o db.o -lmysqlclient")
		is_library_changed = True

	if is_file_newer("file_system.c", "file_system.o"):
		result += commands.getoutput("gcc -g -c -Wall -Werror file_system.c -o file_system.o")
		is_library_changed = True

	if is_file_newer("regex.c", "regex.o"):
		if config[mode]['server']['is_linked_statically']:
			result += commands.getoutput("gcc -g -c -Wall -Werror regex.c -o regex.o -Wl,-static -lpcre")
		else:
			result += commands.getoutput("gcc -g -c -Wall -Werror regex.c -o regex.o -lpcre")
		is_library_changed = True

	if is_file_newer("shared_memory.c", "shared_memory.o"):
		result += commands.getoutput("gcc -g -c -Wall -Werror shared_memory.c -o shared_memory.o")
		is_library_changed = True

	if is_file_newer("socket.c", "socket.o"):
		result += commands.getoutput("gcc -g -c -Wall -Werror socket.c -o socket.o")
		is_library_changed = True

	if is_file_newer("fcgi.c", "fcgi.o"):
		l = ''
		if os_name == 'suse':
			l = ' -I/usr/include/fastcgi/'

		if config[mode]['server']['is_linked_statically']:
			result += commands.getoutput("gcc -g -c -Wall -Werror fcgi.c -o fcgi.o -Wl,-static -lfcgi" + l)
		else:
			result += commands.getoutput("gcc -g -c -Wall -Werror fcgi.c -o fcgi.o -lfcgi" + l)
		is_library_changed = True

	if is_library_changed:
		# Combine the libs into a static library
		result += commands.getoutput("ar rcs clibs.a db.o file_system.o regex.o shared_memory.o socket.o fcgi.o")

	if is_file_newer("web_helper.d", "web_helper.o") or \
		is_file_newer("rootintootin.d", "rootintootin.o") or \
		is_file_newer("ui.d", "ui.o") or \
		is_file_newer("rootintootin_server.d", "rootintootin_server.o") or \
		is_file_newer("http_server.d", "http_server.o") or \
		is_file_newer("tcp_server.d", "tcp_server.o") or \
		is_file_newer("rootintootin_process.d", "rootintootin_process.o") or \
		is_file_newer("app_builder.d", "app_builder.o") or \
		is_file_newer("db.d", "db.o") or \
		is_file_newer("file_system.d", "file_system.o") or \
		is_file_newer("regex.d", "regex.o") or \
		is_file_newer("shared_memory.d", "shared_memory.o") or \
		is_file_newer("socket.d", "socket.o") or \
		is_file_newer("fcgi.d", "fcgi.o"):
		# Build the framework
		command = "ldc" + [' ', ' -unittest '][include_unit_test] + "-g -w -c web_helper.d rootintootin.d " + \
				"ui.d rootintootin_server.d http_server.d tcp_server.d " + \
				"rootintootin_process.d app_builder.d " + \
				" db.d file_system.d regex.d shared_memory.d socket.d fcgi.d " + tango
		result += commands.getoutput(command)

		# Combine the framework into a static library
		command = "ar rcs rootintootin.a web_helper.o " + \
				"rootintootin.o ui.o rootintootin_server.o http_server.o " + \
				"tcp_server.o rootintootin_process.o app_builder.o " + \
				"db.o file_system.o regex.o shared_memory.o socket.o fcgi.o"
		result += commands.getoutput(command)

	compile_error = None
	if os.path.exists("rootintootin.a"):
		compile_error = None
		sys.stdout.write(":)\n")
		sys.stdout.flush()
	else:
		compile_error = result
		sys.stdout.write(":(\n")
		print "Framework build failed!"
		print compile_error
		exit()

def build_server():
	sys.stdout.write("Rebuilding server ...".ljust(78, ' '))
	sys.stdout.flush()

	# Compile the server and link it with the static library
	result = ''
	command = "ldc -g -w -of server server.d -L rootintootin.a "

	if config[mode]['server']['is_linked_statically']:
		command += "-L clibs.a -L /usr/lib/libfcgi.a -L " + mysql + ".a -L " + pcre + " " + tango + " -L-lz"
	else:
		command += "-L clibs.a -L" + mysql + ".so -L=\"-lpcre\" -L=\"-lfcgi\" " + tango
	result += commands.getoutput(command)

	compile_error = None
	if os.path.exists("server"):
		compile_error = None
		sys.stdout.write(":)\n")
		sys.stdout.flush()
	else:
		compile_error = result
		sys.stdout.write(":(\n")
		print "Server build failed!"
		print compile_error
		exit()

def build_application(include_unit_test = False):
	sys.stdout.write("Rebuilding application ...".ljust(78, ' '))
	sys.stdout.flush()

	generator = Generator()
	generator.set_mode(mode)

	# Get the names of all the models
	model_names = []
	for entry in os.listdir("app/models/"):
		if entry.endswith('.d'):
			model_names.append(entry.split('.d')[0])

	# Get the names of all the views
	view_names = []
	for controller_name, route_maps in routes.items():
		name = "app/views/" + controller_name
		for entry in os.listdir(name):
			if entry.endswith(".html.ed"):
				view_names.append(controller_name + "_" + entry.split(".html.ed")[0])

	# Get all the app's files for a rebuild
	files = [];
	for model_name in model_names:
		is_newer = is_file_newer("app/models/" + model_name + ".d", model_name + ".o")
		files.append(model_name + ['.o', '.d'][is_newer])
		files.append(model_name + "_base" + ['.o', '.d'][is_newer])

	for controller_name, route_maps in routes.items():
		controller = generator.singularize(controller_name)
		is_newer = is_file_newer("app/controllers/" + controller + "_controller.d", controller + "_controller.o")
		files.append(controller + "_controller" + ['.o', '.d'][is_newer])

	for view_name in view_names:
		controller = view_name.split("_")[0]
		action = view_name.split("_")[1]
		is_newer = is_file_newer("app/views/" + controller + "/" + action + ".html.ed", "view_" + controller + "_" + action + ".o")
		files.append("view_" + controller + "_" + action + ['.o', '.d'][is_newer])

	is_newer = is_file_newer("app/views/layouts/default.html.ed", "view_layouts_default.o")
	files.append("view_layouts_default" + ['.o', '.d'][is_newer])

	# Save the configuration changes that will be needed by the running program
	_port = int(config[mode]["server"]["port"])
	_max_waiting_clients = int(config[mode]["server"]["max_waiting_clients"])

	# Build the app
	command = \
		"ldc" + [' ', ' -unittest '][include_unit_test] + "-g -w -of application_new application.d " + \
		str.join(' ', files)

	if config[mode]['server']['is_linked_statically']:
		command += " -L rootintootin.a -L clibs.a -L=\"/usr/lib/libfcgi.a\" -L=\"" + mysql + ".a\" -L=\"" + pcre + "\" " + tango + " -L-lz"
	else:
		command += " -L rootintootin.a -L clibs.a -L" + mysql + ".so -L=\"-lpcre\" -L=\"-lfcgi\" " + tango
	compile_error = commands.getoutput(command)

	# Make sure the application was built
	if os.path.isfile("application_new"):
		sys.stdout.write(":)\n")
		sys.stdout.flush()
		# Replace the old app with the new one
		if os.path.isfile("application"):
			os.remove("application")
		os.rename("application_new", "application")
	else:
		sys.stdout.write(":(\n")
		sys.stdout.flush()
		sys.stderr.write(compile_error + "\n")
		sys.stderr.flush()

def run_server():
	# Run the server in its own process
	process = None
	if mode == "development":
		process = subprocess.Popen([scratch + "server", mode, pwd])
	elif mode == "production":
		process = subprocess.Popen([scratch + "server", mode])

	try:
		process.wait()
	except KeyboardInterrupt:
		pass

def run_application_tests():
	# Run the application in its own process
	process = subprocess.Popen([scratch + "application"])

	try:
		process.wait()
	except KeyboardInterrupt:
		pass

def copy_files_to_server(name, new_name=''):
	sys.stdout.write(("Copying " + name + " to remote server ...").ljust(78, ' '))
	sys.stdout.flush()

	command = "scp -r " + user + "@" + ip + ":" + scratch + name + "/ " + directory + new_name
	expected_from_list = [user + "@" + ip + "'s password:", 
							"Permission denied, please try again.", 
							"No route to host", 
							pexpect.EOF]
	child = pexpect.spawn(command)

	error_message = None
	while True:
		result = child.expect(expected_from_list)

		if result == 0:
			child.sendline(password)
		elif result == 1:
			error_message = "Invalid user name or password."
			child.sendcontrol('c')
		elif result == 2:
			error_message = "Could not connect to server."
			child.sendcontrol('c')
		elif result == len(expected_from_list)-1:
			break

	child.close()
	if error_message:
		sys.stdout.write(":(\n")
		sys.stdout.flush()
		print error_message + " Exiting ..."
		exit()
	else:
		sys.stdout.write(":)\n")
		sys.stdout.flush()

def rename_remote_file(name, new_name):
	sys.stdout.write(("Renaming remote file " + name + " to " + new_name + " ...").ljust(78, ' '))
	sys.stdout.flush()

	command = "ssh " + user + "@" + ip + " mv " + directory + name + " " + directory + new_name
	child = pexpect.spawn(command, timeout=5)

	expected_from_list = [user + "@" + ip + "'s password:", 
							"Permission denied, please try again.", 
							pexpect.EOF]

	had_error = False
	while True:
		result = child.expect(expected_from_list)

		if result == 0:
			child.sendline(password)
		elif result == 1:
			had_error = True
			child.sendcontrol('c')
		elif result == len(expected_from_list)-1:
			break

	child.close()
	if had_error:
		sys.stdout.write(":(\n")
		sys.stdout.flush()
		print "Invalid user name or password. Exiting ..."
		exit()
	else:
		sys.stdout.write(":)\n")
		sys.stdout.flush()

def restart_remote_server():
	sys.stdout.write("Restarting remote server ...".ljust(78, ' '))
	sys.stdout.flush()

	command = "ssh " + user + "@" + ip
	child = pexpect.spawn(command, timeout=10)

	expected_from_list = [user + "@" + ip + "'s password:", 
							"Permission denied, please try again.", 
							"Last login:", 
							"\[sudo\] password for " + user + ":", 
							"Sorry, try again.", 
							"\[ OK \]", 
							pexpect.EOF]

	had_error = False
	while True:
		result = child.expect(expected_from_list)

		if result == 0:
			child.sendline(password)
		elif result == 1:
			had_error = True
			child.sendcontrol('c')
		elif result == 2:
			child.sendline("sudo /etc/init.d/" + httpd + " force-reload")
		elif result == 3:
			child.sendline(password)
		elif result == 4:
			had_error = True
			child.sendcontrol('d')
		elif result == 5:
			break
		elif result == len(expected_from_list)-1:
			break

	child.close()
	if had_error:
		sys.stdout.write(":(\n")
		sys.stdout.flush()
		print "Invalid user name or password. Exiting ..."
		exit()
	else:
		sys.stdout.write(":)\n")
		sys.stdout.flush()

def remove_folder_on_server(name):
	sys.stdout.write(("Removing remote folder '" + (name or "") + "' ...").ljust(78, ' '))
	sys.stdout.flush()

	if name is None or len(name.strip()) == 0:
		sys.stdout.write(":(\n")
		sys.stdout.flush()
		print "The name was blank. Exiting ..."
		exit()

	command = "ssh " + user + "@" + ip
	child = pexpect.spawn(command, timeout=10)

	expected_from_list = [user + "@" + ip + "'s password:", 
							"Permission denied, please try again.", 
							"Last login:", 
							"\[sudo\] password for " + user + ":", 
							"Sorry, try again.", 
							pexpect.EOF]

	is_running = True
	had_error = False
	while is_running:
		result = child.expect(expected_from_list)

		if result == 0:
			child.sendline(password)
		elif result == 1:
			had_error = True
			is_running = False
			child.sendcontrol('c')
		elif result == 2:
			child.sendline("sudo rm -rf " + name + ";exit")
		elif result == 3:
			child.sendline(password)
		elif result == 4:
			had_error = True
			is_running = False
			child.sendcontrol('d')
		elif result == len(expected_from_list)-1:
			is_running = False

	child.close()
	if had_error:
		sys.stdout.write(":(\n")
		sys.stdout.flush()
		print "Invalid user name or password. Exiting ..."
		exit()
	else:
		sys.stdout.write(":)\n")
		sys.stdout.flush()

def create_folder_on_server(name):
	sys.stdout.write(("Creating remote folder " + name + " ...").ljust(78, ' '))
	sys.stdout.flush()

	command = "ssh " + user + "@" + ip
	child = pexpect.spawn(command, timeout=10)

	expected_from_list = [user + "@" + ip + "'s password:", 
							"Permission denied, please try again.", 
							"Last login:", 
							"\[sudo\] password for " + user + ":", 
							"Sorry, try again.", 
							pexpect.EOF]

	is_running = True
	had_error = False
	while is_running:
		result = child.expect(expected_from_list)

		if result == 0:
			child.sendline(password)
		elif result == 1:
			had_error = True
			child.sendcontrol('c')
		elif result == 2:
			child.sendline("sudo mkdir " + name + ";exit")
		elif result == 3:
			child.sendline(password)
		elif result == 4:
			had_error = True
			child.sendcontrol('d')
		elif result == len(expected_from_list)-1:
			is_running = False

	child.close()
	if had_error:
		sys.stdout.write(":(\n")
		sys.stdout.flush()
		print "Invalid user name or password. Exiting ..."
		exit()
	else:
		sys.stdout.write(":)\n")
		sys.stdout.flush()

def chown_folder_on_server(name, chown_user):
	sys.stdout.write(("Chowning remote folder " + name + " to " + chown_user + " ...").ljust(78, ' '))
	sys.stdout.flush()

	command = "ssh " + user + "@" + ip
	child = pexpect.spawn(command, timeout=10)

	expected_from_list = [user + "@" + ip + "'s password:", 
							"Permission denied, please try again.", 
							"Last login:", 
							"\[sudo\] password for " + user + ":", 
							"Sorry, try again.", 
							pexpect.EOF]

	is_running = True
	had_error = False
	while is_running:
		result = child.expect(expected_from_list)

		if result == 0:
			child.sendline(password)
		elif result == 1:
			had_error = True
			child.sendcontrol('c')
		elif result == 2:
			child.sendline("sudo chown -R " + chown_user + " " + name + ";exit")
		elif result == 3:
			child.sendline(password)
		elif result == 4:
			had_error = True
			child.sendcontrol('d')
		elif result == len(expected_from_list)-1:
			is_running = False

	child.close()
	if had_error:
		sys.stdout.write(":(\n")
		sys.stdout.flush()
		print "Invalid user name or password. Exiting ..."
		exit()
	else:
		sys.stdout.write(":)\n")
		sys.stdout.flush()

