

private import ${model_name}_base;

public class ${model_name.capitalize()} : ${model_name.capitalize()}Base {
	public void validate() {
		_errors = [];
<%presence_of = [] %>\
% for field_name, validations in validates.iteritems():
% for validation in validations:
% if validation == "presence_of":
<%presence_of.append("\"" + field_name + "\"") %>\
% endif
% endfor
% endfor
% if len(presence_of) > 0:
		validates_presence_of([${str.join(', ', presence_of)}]);
% endif
	}
}


