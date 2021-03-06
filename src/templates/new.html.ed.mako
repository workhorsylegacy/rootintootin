<%doc> \
    This is a template html.ed file. It uses mako \
    for templating. Additional formatting is added to \
    escape symbols that will conflict with mako. After \
    mako is run, these symbols are replaced with others: \
    @@ is replaced with % \
</%doc>\
<@@# form_start("${pluralize(model_name)}", "new_${model_name}", "new_${model_name}", "post"); @@>
	<h1>New ${model_name.capitalize()}</h1>

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
% elif field_type in ['reference']:
	<p>
		<label for="${model_name}_${field_name}">${field_name.capitalize()}</label><br />
		<select id="${model_name}_${field_name}" name="${model_name}[${field_name}]">
			<@@ foreach(${field_name.capitalize()} ${field_name} ; controller._${pluralize(field_name)}) { @@>
				<option value="<@@=${field_name}.id@@>"><@@=${field_name}.id@@></option>
			<@@ } @@>
		</select>
	</p>
% endif
% endfor

	<input id="${model_name}_submit" name="commit" type="submit" value="Create" />
<@@# form_end(); @@>

<@@#link_to("Back", "/${pluralize(model_name)}")@@>

