<%doc> \
    This is a template html.ed file. It uses mako \
    for templating. Additional formatting is added to \
    escape symbols that will conflict with mako. After \
    mako is run, these symbols are replaced with others: \
    @@ is replaced with % \
</%doc>\
<form action="/${pluralize(model_name)}/update/<@@=controller._${model_name}.id@@>" class="edit_${model_name}" id="edit_${model_name}_<@@=controller._${model_name}.id@@>" method="post">
	<h1>Editing ${model_name.capitalize()}</h1>

	<@@= UI.errors_for(controller._${model_name}, "${model_name}") @@>
% for field in pairs:
<% field_name, field_type = field.split(':') %>
	<p>
		<label for="${model_name}_${field_name}">${field_name.capitalize()}</label><br />
		<input id="${model_name}_${field_name}" name="${model_name}[${field_name}]" type="text" value="<@@=controller._${model_name}.${field_name}@@>" />
	</p>
% endfor

	<input id="${model_name}_submit" name="commit" type="submit" value="Update" />
</form>

<a href="/${pluralize(model_name)}/show/<@@=controller._${model_name}.id@@>">Show</a> |
<a href="/${pluralize(model_name)}">Back</a>


