

private import rootintootin;
private import ${model_name};

public class ${controller_name.capitalize()}Controller : ControllerBase {
	public ${controller_name.capitalize()}[] _${controller_names};
	public ${controller_name.capitalize()} _${controller_name};

	public void index() {
		_${pluralize(controller_name)} = ${controller_name.capitalize()}.find_all();
		respond_with("${pluralize(controller_name)}", _${pluralize(controller_name)}, "index", 200, ["html", "json", "xml"]);
	}

	public void show() {
		_${controller_name} = ${controller_name.capitalize()}.find(to_ulong(_request._params["id"].value));
		respond_with(_${controller_name}, "show", 200, ["html", "json", "xml"]);
	}

	public void New() {
		_${controller_name} = new ${controller_name.capitalize()}();
		respond_with(_${controller_name}, "new", 200, ["html", "json", "xml"]);
	}

	public void create() {
		_${controller_name} = new ${controller_name.capitalize()}();
% for field in pairs:
<%field_name, field_type = field.split(':') %>\
		_${controller_name}.${field_name} = to_${migration_type_to_html_type(field_type)}(_request._params["${controller_name}"]["${field_name}"].value);
% endfor

		if(_${controller_name}.save()) {
			flash_notice("The ${controller_name} was saved.");
			respond_with_redirect(_${controller_name}, "/${pluralize(controller_name)}/" ~ to_s(_${controller_name}.id), 200, ["html", "json", "xml"]);
		} else {
			respond_with(_${controller_name}, "edit", 200, ["html", "json", "xml"]);
		}
	}

	public void edit() {
		_${controller_name} = ${controller_name.capitalize()}.find(to_ulong(_request._params["id"].value));
		respond_with(_${controller_name}, "edit", 200, ["html", "json", "xml"]);
	}

	public void update() {
		_${controller_name} = ${controller_name.capitalize()}.find(to_ulong(_request._params["id"].value));
% for field in pairs:
<%field_name, field_type = field.split(':') %>\
		_${controller_name}.${field_name} = to_${migration_type_to_d_type(field_type)}(_request._params["${controller_name}"]["${field_name}"].value);
% endfor

		if(_${controller_name}.save()) {
			flash_notice("The ${controller_name} was updated.");
			respond_with_redirect(_${controller_name}, "/${pluralize(controller_name)}/" ~ to_s(_${controller_name}.id), 200, ["html", "json", "xml"]);
		} else {
			respond_with(_${controller_name}, "edit", 200, ["html", "json", "xml"]);
		}
	}

	public void destroy() {
		_${controller_name} = ${controller_name.capitalize()}.find(to_ulong(_request._params["id"].value));

		if(_${controller_name}.destroy()) {
			flash_notice("The ${controller_name} was destroyed.");
			respond_with_redirect("/${pluralize(controller_name)}", 200, ["html", "json", "xml"]);
		} else {
			flash_error(_${controller_name}.errors()[0]);
			respond_with(_${controller_name}, "index", 422, ["html", "json", "xml"]);
		}
	}
}

