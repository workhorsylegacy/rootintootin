<%doc> \
    This is a template html.ed file. It uses mako \
    for templating. Additional formatting is added to \
    escape symbols that will conflict with mako. After \
    mako is run, these symbols are replaced with others: \
    @@ is replaced with % \
</%doc>\
<@@# form_start("${pluralize(model_name)}/" ~ to_s(controller._${model_name}.id) ~ "?method=PUT", "edit_${model_name}_" ~ to_s(controller._${model_name}.id), "edit_${model_name}", "post"); @@>
	<h1>Editing ${model_name.capitalize()}</h1>

	<@@# errors_for(controller._${model_name}, "${model_name}") @@>
% for field in pairs:
<% field_name, field_type = field.split(':') %>
% if field_type in ['binary']:
	<p>
		<label for="${model_name}_${field_name}">${field_name.capitalize()}</label><br />
		<input id="${model_name}_${field_name}" name="${model_name}[${field_name}]" type="text" value="<@@=controller._${model_name}.${field_name}@@>" />
	</p>
% elif field_type in ['boolean']:
	<p>
		<label for="${model_name}_${field_name}">${field_name.capitalize()}</label><br />
		<input id="${model_name}_${field_name}" name="${model_name}[${field_name}]" type="checkbox" <@@=controller._${model_name}.${field_name} ? "checked" : ""@@> />
	</p>
% elif field_type in ['string', 'date', 'datetime', 'time', 'timestamp', 'unique_date', 'unique_datetime', 'unique_string', 'unique_time', 'unique_timestamp']:
	<p>
		<label for="${model_name}_${field_name}">${field_name.capitalize()}</label><br />
		<input id="${model_name}_${field_name}" name="${model_name}[${field_name}]" type="text" value="<@@=controller._${model_name}.${field_name}@@>" />
	</p>
% elif field_type in ['text']:
	<p>
		<label for="${model_name}_${field_name}">${field_name.capitalize()}</label><br />
		<textarea id="${model_name}_${field_name}" name="${model_name}[${field_name}]"><@@=controller._${model_name}.${field_name}@@></textarea>
	</p>
% elif field_type in ['float', 'integer', 'unique_float', 'unique_integer'] or field_type.startswith('decimal') or field_type.startswith('unique_decimal'):
	<p>
		<label for="${model_name}_${field_name}">${field_name.capitalize()}</label><br />
		<input id="${model_name}_${field_name}" name="${model_name}[${field_name}]" type="text" value="<@@=controller._${model_name}.${field_name}@@>" />
	</p>
% endif
% endfor

	<input id="${model_name}_submit" name="commit" type="submit" value="Update" />
<@@# form_end(); @@>

<@@#link_to("Show", "/${pluralize(model_name)}/" ~ to_s(controller._${model_name}.id))@@> | 
<@@#link_to("Back", "/${pluralize(model_name)}")@@>


