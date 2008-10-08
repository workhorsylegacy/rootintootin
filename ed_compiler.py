

f = open('index.html.ed', 'r')
output = []

body = f.read()
f.close()

output.append(
"public string render(UserController controller, out int[int] line_translations) { \n" +
"	// Generate the view as an array of strings\n" +
"	string[] builder;")

while len(body) > 0:
	open_index = body.find("<%")
	close_index = body.find("%>")

	# raise if open but no close
	# raise if close before open

	#if open_index == -1:
	#	break

	before = body[: open_index]
	middle = body[open_index+2 : close_index]
	after = body[close_index+2 :]

	if open_index == -1 and close_index == -1:
		output.append("\n	builder ~= \"" + body.replace("\"", "\\\"") + "\"; ")
		break

	if len(before) > 0:
		output.append("\n	builder ~= \"" + before.replace("\"", "\\\"") + "\"; ")

	if len(middle) > 0:
		if middle[0] == "=":
			output.append("\n	builder ~= " + middle[1:].replace("\"", "\\\"") + "; ")
		else:
			output.append("\n	" + middle)

	body = after

output.append(
"\n	return std.string.join(builder, \"\"); \n" +
"}")

out_file = open("index.poop.d", 'w')

for fragment in output:
	out_file.write(fragment)

out_file.close()




