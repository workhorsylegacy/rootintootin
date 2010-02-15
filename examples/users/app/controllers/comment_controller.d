
private import rootintootin;
private import comment;
private import user;

public class CommentController : ControllerBase {
	public Comment[] _comments;
	public User[] _users;
	public Comment _comment;

	public void index() {
		_comments = Comment.find_all();
		respond_with("comments", _comments, "index", 200, ["html", "json", "xml"]);
	}

	public void show() {
		_comment = Comment.find(to_ulong(_request._params["id"].value));
		respond_with(_comment, "show", 200, ["html", "json", "xml"]);
	}

	public void New() {
		_comment = new Comment();
		_users = User.find_all();
		respond_with(_comment, "new", 200, ["html", "json", "xml"]);
	}

	public void create() {
		_comment = new Comment();
		_comment.value = _request._params["comment"]["value"].value;
		// FIXME: Change this to user not parent
		_comment.parent = User.find(to_ulong(_request._params["comment"]["user"].value));

		if(_comment.save()) {
			flash_notice("The comment was created.");
			respond_with_redirect(_comment, "/comments/" ~ to_s(_comment.id), 200, ["html", "json", "xml"]);
		} else {
			_users = User.find_all();
			respond_with(_comment, "new", 422, ["html", "json", "xml"]);
		}
	}

	public void edit() {
		_comment = Comment.find(to_ulong(_request._params["id"].value));
		_users = User.find_all();
		respond_with(_comment, "edit", 200, ["html", "json", "xml"]);
	}

	public void update() {
		_comment = Comment.find(to_ulong(_request._params["id"].value));
		_comment.value = _request._params["comment"]["value"].value;
		// FIXME: Change this to user not parent
		_comment.parent = User.find(to_ulong(_request._params["comment"]["user"].value));

		if(_comment.save()) {
			flash_notice("The comment was updated.");
			respond_with_redirect(_comment, "/comments/" ~ to_s(_comment.id), 200, ["html", "json", "xml"]);
		} else {
			_users = User.find_all();
			respond_with(_comment, "edit", 200, ["html", "json", "xml"]);
		}
	}

	public void destroy() {
		_comment = Comment.find(to_ulong(_request._params["id"].value));
		if(_comment.destroy()) {
			flash_notice("The comment was destroyed.");
			respond_with_redirect("/comments", 200, ["html", "json", "xml"]);
		} else {
			flash_error(_comment.errors()[0]);
			_comments = Comment.find_all();
			respond_with("comments", _comments, "index", 422, ["html", "json", "xml"]);
		}
	}
}


