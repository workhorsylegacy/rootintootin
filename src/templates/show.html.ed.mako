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

<a href="/${pluralize(model_name)}/edit/<@@=controller._${model_name}.id@@>">Edit</a> | 
<a href="/${pluralize(model_name)}">Back</a>

