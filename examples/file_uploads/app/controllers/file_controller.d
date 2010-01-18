
private import rootintootin;
private import file;

public class FileController : ControllerBase {
	public File[] _files;
	public File _file;

	public void index() {
		_files = File.find_all();
		respond_with("files", _files, "index", 200, ["html", "json", "xml"]);
	}

	public void show() {
		_file = File.find(to_ulong(_request._params["id"].value));
		respond_with(_file, "show", 200, ["html", "json", "xml"]);
	}

	public void New() {
		_file = new File();
		respond_with(_file, "new", 200, ["html", "json", "xml"]);
	}

	public void create() {
		_file = new File();
		_file.name = _request._params["file"]["name"].value;

		if(_file.save()) {
			flash_notice("The file was created.");
			respond_with_redirect(_file, "/files/" ~ to_s(_file.id), 200, ["html", "json", "xml"]);
		} else {
			respond_with(_file, "new", 422, ["html", "json", "xml"]);
		}
	}

	public void edit() {
		_file = File.find(to_ulong(_request._params["id"].value));
		respond_with(_file, "edit", 200, ["html", "json", "xml"]);
	}

	public void update() {
		_file = File.find(to_ulong(_request._params["id"].value));
		_file.name = _request._params["file"]["name"].value;

		if(_file.save()) {
			flash_notice("The file was updated.");
			respond_with_redirect(_file, "/files/" ~ to_s(_file.id), 200, ["html", "json", "xml"]);
		} else {
			respond_with(_file, "edit", 200, ["html", "json", "xml"]);
		}
	}

	public void destroy() {
		_file = File.find(to_ulong(_request._params["id"].value));
		if(_file.destroy()) {
			flash_notice("The file was destroyed.");
			respond_with_redirect("/files", 200, ["html", "json", "xml"]);
		} else {
			flash_error(_file.errors()[0]);
			_files = File.find_all();
			respond_with("files", _files, "index", 422, ["html", "json", "xml"]);
		}
	}
}


