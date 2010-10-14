<%doc> \
    This is a template html.ed file. It uses mako \
    for templating. Additional formatting is added to \
    escape symbols that will conflict with mako. After \
    mako is run, these symbols are replaced with others: \
    @@ is replaced with % \
</%doc>\
% for field in pairs:
<% field_name, field_type = field.split(':') %>
% if field_type == "reference":
<p><b>${field_name.capitalize()}:</b> <@@=controller._${model_name}._${field_name}.id@@></p>
% else:
<p><b>${field_name.capitalize()}:</b> <@@=controller._${model_name}.${field_name}@@></p>
% endif
% endfor

<@@#link_to("Edit", "/${pluralize(model_name)}/" ~ to_s(controller._${model_name}.id) ~ ";edit")@@> | 
<@@#link_to("Back", "/${pluralize(model_name)}")@@>
