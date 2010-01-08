<%doc> \
    This is a template html.ed file. It uses mako \
    for templating. Additional formatting is added to \
    escape symbols that will conflict with mako. After \
    mako is run, these symbols are replaced with others: \
    @@ is replaced with % \
</%doc>\
<form action="/${pluralize(model_name)}/update/<@@=controller._${model_name}.id@@>" class="edit_${model_name}" id="edit_${model_name}_<@@=controller._${model_name}.id@@>" method="post">
	<h1>Editing ${model_name.capitalize()}</h1>

	<@@# UI.errors_for(controller._${model_name}, "${model_name}") @@>
% for field in pairs:
<% field_name, field_type = field.split(':') %>
% if field_type=='binary':
	<p>
		<label for="${model_name}_${field_name}">${field_name.capitalize()}</label><br />
		<input id="${model_name}_${field_name}" name="${model_name}[${field_name}]" type="text" value="<@@=controller._${model_name}.${field_name}@@>" />
	</p>
% elif field_type=='boolean':
	<p>
		<label for="${model_name}_${field_name}">${field_name.capitalize()}</label><br />
		<input id="${model_name}_${field_name}" name="${model_name}[${field_name}]" type="checkbox" <@@=controller._${model_name}.${field_name} ? "checked" : ""@@> />
	</p>
% elif field_type=='string' or field_type=='date' or field_type=='datetime' or field_type=='time' or field_type=='timestamp':
	<p>
		<label for="${model_name}_${field_name}">${field_name.capitalize()}</label><br />
		<input id="${model_name}_${field_name}" name="${model_name}[${field_name}]" type="text" value="<@@=controller._${model_name}.${field_name}@@>" />
	</p>
% elif field_type=='text':
	<p>
		<label for="${model_name}_${field_name}">${field_name.capitalize()}</label><br />
		<textarea id="${model_name}_${field_name}" name="${model_name}[${field_name}]"><@@=controller._${model_name}.${field_name}@@></textarea>
	</p>
% elif field_type=='decimal' or field_type=='float' or field_type=='integer':
	<p>
		<label for="${model_name}_${field_name}">${field_name.capitalize()}</label><br />
		<input id="${model_name}_${field_name}" name="${model_name}[${field_name}]" type="text" value="<@@=controller._${model_name}.${field_name}@@>" />
	</p>
% endif
% endfor

	<input id="${model_name}_submit" name="commit" type="submit" value="Update" />
</form>

<a href="/${pluralize(model_name)}/show/<@@=controller._${model_name}.id@@>">Show</a> |
<a href="/${pluralize(model_name)}">Back</a>


