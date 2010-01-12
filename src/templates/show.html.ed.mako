<%doc> \
    This is a template html.ed file. It uses mako \
    for templating. Additional formatting is added to \
    escape symbols that will conflict with mako. After \
    mako is run, these symbols are replaced with others: \
    @@ is replaced with % \
</%doc>\
% for field in pairs:
<% field_name, field_type = field.split(':') %>
<p><b>${field_name.capitalize()}:</b> <@@=controller._${model_name}.${field_name}@@></p>
% endfor

<@@#link_to("Show", "/${pluralize(model_name)}/edit/" ~ to_s(controller._${model_name}.id))@@> | 
<@@#link_to("Back", "/${pluralize(model_name)}")@@>
