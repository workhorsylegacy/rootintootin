
import rester;
import file;

public class FileController : ControllerBase {
	public File[] _files;
	public File _file;

	public void index() {
		_files = File.find_all();
	}

	public void show() {
		_file = File.find(to_ulong(_request.params["id"]));
	}

	public void New() {
		_file = new File();
	}

	public void create() {
		_file = new File();
		_file.name = _request.params["file[name]"];

		if(_file.save()) {
			redirect_to("/files/show/" ~ to_s(_file.id));
		} else {
			render_view("new");
		}
	}

	public void edit() {
		_file = File.find(to_ulong(_request.params["id"]));
	}

	public void update() {
		_file = File.find(to_ulong(_request.params["id"]));
		_file.name = _request.params["file[name]"];

		if(_file.save()) {
			redirect_to("/files/show/" ~ to_s(_file.id));
		} else {
			render_view("edit");
		}
	}

	public void destroy() {
		_file = File.find(to_ulong(_request.params["id"]));
		_file.destroy();

		redirect_to("/files/index");
	}
}


