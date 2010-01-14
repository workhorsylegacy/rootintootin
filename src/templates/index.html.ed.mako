<%doc> \
    This is a template html.ed file. It uses mako \
    for templating. Additional formatting is added to \
    escape symbols that will conflict with mako. After \
    mako is run, these symbols are replaced with others: \
    @@ is replaced with % \
</%doc>\
<h1>Listing ${pluralize(model_name)}</h1>

<@@ if(controller._${pluralize(model_name)}.length > 0) { @@>
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
		<td><@@#link_to("Show", "/${pluralize(model_name)}/" ~ to_s(${model_name}.id))@@></td>
		<td><@@#link_to("Edit", "/${pluralize(model_name)}/" ~ to_s(${model_name}.id) ~ ";edit")@@></td>
		<td><@@#link_to("Destroy", "/${pluralize(model_name)}/" ~ to_s(${model_name}.id) ~ "?method=DELETE", "onclick=\"post_href('delete'); return false;\"")@@></td>
	</tr>
<@@ } @@>
</table>
<@@ } else { @@>
<p>There are no ${pluralize(model_name)}.</p>
<@@ } @@>


<br />
<@@#link_to("New ${model_name}", "/${pluralize(model_name)}/new")@@>

