
import os
import pexpect
import MySQLdb


def combine_code_files(routes, table_map):
	# Open the output file
	out_file = open('run.d', 'w')

	# Write the imports
	out_file.write(
		"\n" +
		"import tango.text.convert.Integer;\n" +
		"import tango.text.Util;\n" +
		"import tango.io.Stdout;\n" +
		"import tango.text.Regex;\n" +
		"import tango.time.chrono.Gregorian;\n" +
		"import tango.time.WallClock;\n" +

		"\n" +
		"import native_rest_cannon;\n" +
		"import native_rest_cannon_server;\n\n"
	);

	# Write the generated model base classes into the file
	for model in os.listdir('app/models/'):
		if not model.endswith('.d'):
			continue

		model_name = str.split(model, '.')[0]
		model_map = table_map[model_name + 's']

		out_file.write("\n\n")
		out_file.write(model_generated_properties_class(model_name, model_map))
		out_file.write("\n\n")

	# Write the models into the file
	for model in os.listdir('app/models/'):
		if not model.endswith('.d'):
			continue

		model_name = str.split(model, '.')[0]
		model_map = table_map[model_name + 's']

		f = open('app/models/' + model, 'r')
		out_file.write("\n\n")
		out_file.write(f.read())
		out_file.write("\n\n")
		f.close()

	# Write the controllers into the file
	for controller, actions in routes.items():
		f = open('app/controllers/' + controller + '_controller.d', 'r')
		out_file.write("\n\n")
		out_file.write(f.read())
		out_file.write("\n\n")
		f.close()

	# Write the layouts into the file
	for layout in os.listdir('app/views/layouts/'):
		if not layout.endswith('.d'):
			continue
		layout = layout[0:-2]

		f = open('app/views/layouts/' + layout + '.d', 'r')
		out_file.write("\n\n")
		out_file.write(f.read())
		out_file.write("\n\n")
		f.close()

	# Write the views into the file
	for controller, actions in routes.items():
		for member, http_method in actions['member'].items():
			if not os.path.exists('app/views/' + controller + '/' + member + '.d'):
				continue

			f = open('app/views/' + controller + '/' + member + '.d', 'r')
			out_file.write("\n\n")
			out_file.write(f.read())
			out_file.write("\n\n")
			f.close()

	
	# Write the run action function
	out_file.write(
	"public void run_action(Request request, void function(char[]) render_text) {\n" +
	"	int[int] line_translations;\n" +
	"	UserController controller = new UserController(request);\n")
	
	for controller, actions in routes.items():
		for action in actions['member']:
			if action == "new":
				action = "New"
			out_file.write(
			"\n	if(request.action == \"" + action + "\") {\n" +
			"		controller." + action + "();\n" +
			"		render_text(" + action.capitalize() + "View.render(controller, line_translations));\n" +
			"	}\n")

	out_file.write("}\n")

	# Write the main function
	out_file.write(
	"\n\nint main() {\n" +
	"	Server.start(&run_action);\n" +
	"\n" +
	"	return 0;\n" +
	"}\n")


def sql_type_to_d_type(sql_type):
	type_map = { 'tinyint(1)' : 'bool',
				 'varchar(255)' : 'char[]',
				 'datetime' : 'char[]',
				 'int(11)' : 'int',
				 'text' : 'char[]' }

	return type_map[sql_type]

def convert_string_to_d_type(d_type, d_string_variable_name):
	cast_map = { 'int' : 'tango.text.convert.Integer.toInt(#)',
				'long' : 'tango.text.convert.Integer.toLong(#)',
				'float' : 'tango.text.convert.Float.toFloat(#)',
				'bool' : '(# == "true" ? true : false)',
				'char' : '#',
				'char[]' : 'tango.text.Util.repeat(#, 1)' }

	return cast_map[d_type].replace('#', d_string_variable_name)

def model_generated_properties_class(model_name, model_map):
	# Add class opening
	properties = "public class " + model_name.capitalize() + "ModelGeneratedProperties : ModelBase {\n"

	# Add a list of all field names
	properties += "private static char[][] _field_names = ["
	for field, values in model_map.items():
		properties += "\"" + field + "\", ";
	properties += "];\n\n";

	# Add all the fields
	for field, values in model_map.items():
		properties += "	private " + sql_type_to_d_type(values['type']) + " _" + field + ";\n"

	# Add the field properties
	for field, values in model_map.items():
		# Add getter
		properties += \
						"	// " + values['type'] + "\n" + \
						"	public " + sql_type_to_d_type(values['type']) + " " + field + "() {\n" + \
						"		return _" + field + ";\n" + \
						"	}\n"
		# Add setter, but not for id
		if field != 'id':
			properties += \
						"	public void " + field + "(" + sql_type_to_d_type(values['type']) + " value) {\n" + \
						"		_" + field + " = value;\n" + \
						"	}\n"

	# Add the set_field_by_name method
	properties += \
				"public void set_field_by_name(char[] field_name, char[] value) {\n" + \
				"	switch(field_name) {\n"

	for field, values in model_map.items():
		value_with_cast = convert_string_to_d_type(sql_type_to_d_type(values['type']), 'value')
		properties += \
				"		case \"" + field + "\":\n" + \
				"			_" + field + " = " + value_with_cast + ";\n" + \
				"			break;\n"

	properties += \
				"	}\n" + \
				"}\n"

	# Add class closing
	properties += "}"

	return properties


def generate_models():
	# Connect to the database
	# FIXME: This should be gotten from the config file
	db = MySQLdb.connect(host="localhost", user="root", passwd="letmein", db="me_love_movies_development")

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

	return table_map

def generate_views(routes):
	for controller, actions in routes.items():
		for member, http_method in actions['member'].items():
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
			"public class " + member.capitalize() + "View { \n" +
			"public static char[] render(" + controller.capitalize() + "Controller controller, out int[int] line_translations) { \n" +
			"	// Generate the view as an array of strings\n" +
			"	char[][] builder;")

			process_template_body(body, output)

			# Print the closing of the function
			output.append(
			"\n	return DefaultLayout.render(tango.text.Util.join(builder, \"\")); \n" +
			"}\n" +
			"}\n")

			# Save the output as a D file
			out_file = open('app/views/' + controller + '/' + member + '.d', 'w')
			for fragment in output:
				out_file.write(fragment)
			out_file.close()



def generate_layouts():
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
		"public class " + layout.capitalize() + "Layout { \n" +
		"public static char[] render(char[] yield) { \n" +
		"	// Generate the layout as an array of strings\n" +
		"	char[][] builder;")

		process_template_body(body, output)

		# Print the closing of the function
		output.append(
		"\n	return tango.text.Util.join(builder, \"\"); \n" +
		"}\n" +
		"}\n")

		# Save the output as a D file
		out_file = open('app/views/layouts/' + layout + '.d', 'w')
		for fragment in output:
			out_file.write(fragment)
		out_file.close()

def process_template_body(body, output):
	while len(body) > 0:
		# Get the location on the open and close brackets
		open_index = body.find("<%")
		close_index = body.find("%>")

		# raise if open but no close
		# raise if close before open

		# If there were no brackets, just print the last text as a string
		if open_index == -1 and close_index == -1:
			output.append("\n	builder ~= \"" + body.replace("\"", "\\\"") + "\"; ")
			break

		# Get the text before, after, and in between the brackets
		before = body[: open_index]
		middle = body[open_index+2 : close_index]
		after = body[close_index+2 :]

		# If there was text before the opening, print it as a string
		if len(before) > 0:
			output.append("\n	builder ~= \"" + before.replace("\"", "\\\"") + "\"; ")

		# Print the code between the brackets
		if len(middle) > 0:
			if middle[0] == "=":
				output.append("\n	builder ~= " + middle[1:] + ";")
			else:
				output.append("\n	" + middle)

		# Set the remaining text as the body, so it can be processed next
		body = after

# Get the routes
execfile("config/routes.py")

# Do code generation
generate_layouts()
generate_views(routes)
table_map = generate_models()
combine_code_files(routes, table_map)

# Compile the application into an executable
print pexpect.run("gcc -c db.c -o db.o")
print pexpect.run("ar rcs db.a db.o")
command = "gdc -fversion=Posix -o run native_rest_cannon.d native_rest_cannon_server.d run.d db.d /usr/lib/tango-gdc/libgtango.a db.a -lz -lmysqlclient -L /usr/lib/mysql/"
result = pexpect.run(command)
print result





