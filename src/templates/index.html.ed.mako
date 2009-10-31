<%doc> \
    This is a template html.ed file. It uses mako \
    for templating. Additional formatting is added to \
    escape symbols that will conflict with mako. After \
    mako is run, these symbols are replaced with others: \
    @@ is replaced with % \
</%doc>\
<h1>Listing ${pluralize(model_name)}</h1>

<table>
	<tr>
% for field in pairs:
<% field_name, field_type = field.split(':') %>\
		<th>${field_name.capitalize()}</th>
% endfor
	</tr>

<@@ foreach(${model_name.capitalize()} ${model_name} ; controller._${pluralize(model_name)}) { @@>
	<tr>
% for field in pairs:
<% field_name, field_type = field.split(':') %>\
		<td><@@= ${model_name}.${field_name} @@></td>
% endfor
		<td><a href="/${pluralize(model_name)}/show/<@@=${model_name}.id@@>">Show</a></td>
		<td><a href="/${pluralize(model_name)}/edit/<@@=${model_name}.id@@>">Edit</a></td>
		<td><a href="/${pluralize(model_name)}/destroy/<@@=${model_name}.id@@>" onclick="post_href('delete'); return false;">Destroy</a></td>
	</tr>
<@@ } @@>
</table>

<br />
<a href="/${pluralize(model_name)}/new">New ${model_name}</a>
