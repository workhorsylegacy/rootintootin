

f = open('index.html.ed', 'r')
output = []

body = f.read()

open_bracket = -1
open_write = -1

while len(body) > 0:
	open_index = body.find("<%")
	close_index = body.find("%>")

	# raise if open but no close
	# raise if close before open

	if open_index == -1:
		break

	before = body[: open_index]
	middle = body[open_index+2 : close_index]
	after = body[close_index+2 :]

	if len(before) > 0:
		output += "builder ~= \"" + before + "\"; "
		print "builder ~= \"" + before + "\"; "

	if len(middle) > 0:
		if middle[0] == "=":
			output += middle
			print middle
		else:
			output +=  "builder ~= \"" + middle + "\"; "
			print  "builder ~= \"" + middle + "\"; "

	body = after

