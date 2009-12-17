

private import rootintootin;
private import ${model_name};

public class ${controller_name.capitalize()}Controller : ControllerBase {
	public ${controller_name.capitalize()}[] _${controller_names};
	public ${controller_name.capitalize()} _${controller_name};

	public void index() {
		_${pluralize(controller_name)} = ${controller_name.capitalize()}.find_all();
	}

	public void show() {
		_${controller_name} = ${controller_name.capitalize()}.find(to_ulong(_request._params["id"]));
	}

	public void New() {
		_${controller_name} = new ${controller_name.capitalize()}();
	}

	public void create() {
		_${controller_name} = new ${controller_name.capitalize()}();
% for field in pairs:
<%field_name, field_type = field.split(':') %>\
		_${controller_name}.${field_name} = to_${field_type}(_request._params["${controller_name}[${field_name}]"]);
% endfor

		if(_${controller_name}.save()) {
			flash_notice("The ${controller_name} was saved.");
			redirect_to("/${pluralize(controller_name)}/show/" ~ to_s(_${controller_name}.id));
		} else {
			render_view("new");
		}
	}

	public void edit() {
		_${controller_name} = ${controller_name.capitalize()}.find(to_ulong(_request._params["id"]));
	}

	public void update() {
		_${controller_name} = ${controller_name.capitalize()}.find(to_ulong(_request._params["id"]));
% for field in pairs:
<%field_name, field_type = field.split(':') %>\
		_${controller_name}.${field_name} = to_${field_type}(_request._params["${controller_name}[${field_name}]"]);
% endfor

		if(_${controller_name}.save()) {
			flash_notice("The ${controller_name} was updated.");
			redirect_to("/${pluralize(controller_name)}/show/" ~ to_s(_${controller_name}.id));
		} else {
			render_view("edit");
		}
	}

	public void destroy() {
		_${controller_name} = ${controller_name.capitalize()}.find(to_ulong(_request._params["id"]));

		if(_${controller_name}.destroy()) {
			redirect_to("/${pluralize(controller_name)}/index");
		} else {
			flash_error(_${controller_name}.errors()[0]);
			render_view("index");
		}
	}
}

