
private import rootintootin;
private import file;

public class FileController : ControllerBase {
	public File[] _files;
	public File _file;

	public void index() {
		_files = File.find_all();
		respond_with(_files, "index", 200, ["html", "json"]);
	}

	public void show() {
		_file = File.find(to_ulong(_request._params["id"]));
		respond_with(_file, "show", 200, ["html", "json"]);
	}

	public void New() {
		_file = new File();
		respond_with(_file, "new", 200, ["html", "json"]);
	}

	public void create() {
		_file = new File();
		_file.name = _request._params["file[name]"];

		if(_file.save()) {
			flash_notice("The file was created.");
			respond_with_redirect(_file, "show", 200, ["html", "json"]);
		} else {
			respond_with(_file, "new", 422, ["html", "json"]);
		}
	}

	public void edit() {
		_file = File.find(to_ulong(_request._params["id"]));
		respond_with(_file, "edit", 200, ["html", "json"]);
	}

	public void update() {
		_file = File.find(to_ulong(_request._params["id"]));
		_file.name = _request._params["file[name]"];

		if(_file.save()) {
			flash_notice("The file was updated.");
			respond_with_redirect(_file, "show", 200, ["html", "json"]);
		} else {
			respond_with(_file, "edit", 200, ["html", "json"]);
		}
	}

	public void destroy() {
		_file = File.find(to_ulong(_request._params["id"]));
		if(_file.destroy()) {
			flash_notice("The file was destroyed.");
			respond_with_redirect("index", 200, ["html", "json"]);
		} else {
			flash_error(_file.errors()[0]);
			respond_with(_file, "index", 422, ["html", "json"]);
		}
	}
}


