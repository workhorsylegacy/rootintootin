

private import ${model_name}_base;

public class ${model_name.capitalize()} : ${model_name.capitalize()}Base {
	public void validate() {
		_errors = [];
% for field_name, validations in validates.iteritems():
% for validation in validations:
% if validation == "presence_of":
		// presence_of
		if(_${field_name} == null || _${field_name}.length == 0)
			_errors ~= "The ${field_name} cannot be blank.";
% endif
% endfor
% endfor
	}
}


