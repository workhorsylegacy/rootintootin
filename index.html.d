

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
       "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
		<meta http-equiv="content-type" content="text/html;charset=UTF-8" />
		<title>Example D View</title>
		<link href="/stylesheets/scaffold.css" media="screen" rel="stylesheet" type="text/css" />
		<link href="/stylesheets/style.css" media="screen" rel="stylesheet" type="text/css" />
		<script src="/javascripts/prototype.js" type="text/javascript"></script>
		<script src="/javascripts/effects.js" type="text/javascript"></script>
		<script src="/javascripts/dragdrop.js" type="text/javascript"></script>
		<script src="/javascripts/controls.js" type="text/javascript"></script>
		<script src="/javascripts/application.js" type="text/javascript"></script>
	</head>
	<body>
		<table border="1">
			<% foreach(User user ; controller.get_array!(User[])("users")) { %>
			<tr>
				<td><%= user.name() %></td>
			</tr>
			<% } %>
		</table>
	</body>
</html>
