<%doc> \
    This is a template html.ed file. It uses mako \
    for templating. Additional formatting is added to \
    escape symbols that will conflict with mako. After \
    mako is run, these symbols are replaced with others: \
    @@ is replaced with % \
</%doc>\
<form action="/${pluralize(model_name)}/create" class="new_${model_name}" id="new_${model_name}" method="post">
	<h1>New ${model_name.capitalize()}</h1>

	<@@= UI.errors_for(controller._${model_name}, "${model_name}") @@>
% for field in pairs:
<% field_name, field_type = field.split(':') %>
	<p>
		<label for="${model_name}_${field_name}">${field_name.capitalize()}</label><br />
		<input id="${model_name}_${field_name}" name="${model_name}[${field_name}]" type="text" value="<@@=controller._${model_name}.${field_name}@@>" />
	</p>
% endfor

	<input id="${model_name}_submit" name="commit" type="submit" value="Create" />
</form>

<a href="/${pluralize(model_name)}">Back</a>

