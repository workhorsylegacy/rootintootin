
import os
import pexpect

execfile("config/routes.py")

def combine_code_files(routes):
	# Open the output file
	out_file = open('run.d', 'w')

	# Write the imports
	out_file.write(
		"\n" +
		"import std.string;\n" +
		"import std.stdio;\n" +
		"import std.socket;\n" +
		"import std.regexp;\n" +
		"\n" +
		"import rail_cannon;\n" +
		"import rail_cannon_server;\n\n"
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
	"public void run_action(Request request, void function(string) render_text) {\n" +
	"	int[int] line_translations;\n" +
	"	UserController controller = new UserController();\n")
	
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
			"public static string render(" + controller.capitalize() + "Controller controller, out int[int] line_translations) { \n" +
			"	// Generate the view as an array of strings\n" +
			"	string[] builder;")

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
						output.append("\n	builder ~= " + middle[1:].replace("\"", "\\\"") + "; ")
					else:
						output.append("\n	" + middle)

				# Set the remaining text as the body, so it can be processed next
				body = after

			# Print the closing of the function
			output.append(
			"\n	return std.string.join(builder, \"\"); \n" +
			"}\n" +
			"}\n")

			# Save the output as a D file
			out_file = open('app/views/' + controller + '/' + member + '.d', 'w')
			for fragment in output:
				out_file.write(fragment)
			out_file.close()


generate_views(routes)
combine_code_files(routes)

# Compile the application into an executable
command = "gdc -o run rail_cannon.d rail_cannon_server.d run.d"
result = pexpect.run(command)
print result





