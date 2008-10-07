

f = open('index.html.ed', 'r')
output = []

# Process each line
line_number = 0
for line in f:
	column = 0
	column_end = len(line)
	dangling = None

	# Provess each section in a line
	while column < column_end:
		line = line[column :]

		# Get the locations of the special symbols
		special_symbols = {
			'comment'       : line.find("//"),
			'comment_open'  : line.find("/*"),
			'comment_close' : line.find("*/"),
			'open_bracket'  : line.find("<%"),
			'close_bracket' : line.find("%>"),
			'open_write'    : line.find("<%=")
		}

		# Determine which special symbol came first
		smallest_index = -1
		smallest_name = None
		for name, index in special_symbols.items():
			if index > -1 and index < smallest_index:
				smallest_index = index
				smallest_name = name

		if smallest_name == "comment":
			# Commented from a multi-line comment that uses the whole line
			if dangling == None and comment_open != -1:
				pass
			# Already commented from a multi-line comment that uses the whole line
			elif dangling == "/*" and comment_close == -1:
				output += "builder ~= \"" + line + "\""

		if open_bracket > close_bracket:
			raise "open bracket cannot be after close bracket. ln#" + line_number

		before = line[0 : open_bracket]
		body = line[open_bracket+2 : close_bracket]
		after = line[: close_bracket+2]

	line_number += 1

