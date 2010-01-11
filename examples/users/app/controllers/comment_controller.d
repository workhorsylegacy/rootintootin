
private import rootintootin;
private import comment;
private import user;

public class CommentController : ControllerBase {
	public Comment[] _comments;
	public User[] _users;
	public Comment _comment;

	public void index() {
		_comments = Comment.find_all();
		respond_with(_comments, "index", 200, ["html", "json"]);
	}

	public void show() {
		_comment = Comment.find(to_ulong(_request._params["id"]));
		respond_with(_comment, "show", 200, ["html", "json"]);
	}

	public void New() {
		_comment = new Comment();
		_users = User.find_all();
		respond_with(_comment, "new", 200, ["html", "json"]);
	}

	public void create() {
		_comment = new Comment();
		_comment.value = _request._params["comment[value]"];
		// FIXME: Change this to user not parent
		_comment.parent = User.find(to_ulong(_request._params["comment[user]"]));

		if(_comment.save()) {
			flash_notice("The comment was created.");
			respond_with_redirect(_comment, "show", 200, ["html", "json"]);
		} else {
			respond_with(_comment, "new", 422, ["html", "json"]);
		}
	}

	public void edit() {
		_comment = Comment.find(to_ulong(_request._params["id"]));
		_users = User.find_all();
		respond_with(_comment, "edit", 200, ["html", "json"]);
	}

	public void update() {
		_comment = Comment.find(to_ulong(_request._params["id"]));
		_comment.value = _request._params["comment[value]"];
		// FIXME: Change this to user not parent
		_comment.parent = User.find(to_ulong(_request._params["comment[user]"]));

		if(_comment.save()) {
			flash_notice("The comment was updated.");
			respond_with_redirect(_comment, "show", 200, ["html", "json"]);
		} else {
			respond_with(_comment, "edit", 200, ["html", "json"]);
		}
	}

	public void destroy() {
		_comment = Comment.find(to_ulong(_request._params["id"]));
		if(_comment.destroy()) {
			flash_notice("The comment was destroyed.");
			respond_with_redirect("index", 200, ["html", "json"]);
		} else {
			flash_error(_comment.errors()[0]);
			respond_with(_comment, "index", 422, ["html", "json"]);
		}
	}
}


