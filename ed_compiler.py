
import pexpect

def compile_views():
	views = ["index"]
	controller = "UserController"
	controller_file = "test_app"

	for view in views:
		# Get the template file as a string
		f = open(view + '.html.ed', 'r')
		body = f.read()
		f.close()

		# Print the openining of the function
		output = []
		output.append(
		"import std.string;\n" +
		"import rail_cannon;\n" +
		"import " + controller_file + ";\n" +
		"public class " + view.capitalize() + "View { \n" +
		"public static string render(" + controller + " controller, out int[int] line_translations) { \n" +
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
		"}")

		# Save the output as a D file
		out_file = open(view + '.d', 'w')
		for fragment in output:
			out_file.write(fragment)
		out_file.close()


compile_views()

# Compile the view
command = "gdc -o test_app test_app.d rail_cannon.d rail_cannon_server.d index.d"
result = pexpect.run(command)
print result





