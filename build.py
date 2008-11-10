
import os
import pexpect


def combine_code_files(routes):
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

	# Write the models into the file
	for model in os.listdir('app/models/'):
		if not model.endswith('.d'):
			continue

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
combine_code_files(routes)

# Compile the application into an executable
print pexpect.run("gcc -c db.c -o db.o")
print pexpect.run("ar rcs db.a db.o")
command = "gdc -fversion=Posix -o run native_rest_cannon.d native_rest_cannon_server.d run.d db.d /usr/lib/tango-gdc/libgtango.a db.a -lz -lmysqlclient -L /usr/lib/mysql/"
result = pexpect.run(command)
print result





