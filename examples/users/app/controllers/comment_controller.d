
private import rootintootin;
private import comment;
private import user;

public class CommentController : ControllerBase {
	public Comment[] _comments;
	public User[] _users;
	public Comment _comment;

	public void index() {
		_comments = Comment.find_all();
	}

	public void show() {
		_comment = Comment.find(to_ulong(_request._params["id"]));
	}

	public void New() {
		_comment = new Comment();
		_users = User.find_all();
	}

	public void create() {
		_comment = new Comment();
		_comment.value = _request._params["comment[value]"];
		// FIXME: Change this to user not parent
		_comment.parent = User.find(to_ulong(_request._params["comment[user]"]));

		if(_comment.save()) {
			flash_notice("The comment was created.");
			redirect_to("/comments/show/" ~ to_s(_comment.id));
		} else {
			render_view("new");
		}
	}

	public void edit() {
		_comment = Comment.find(to_ulong(_request._params["id"]));
		_users = User.find_all();
	}

	public void update() {
		_comment = Comment.find(to_ulong(_request._params["id"]));
		_comment.value = _request._params["comment[value]"];
		// FIXME: Change this to user not parent
		_comment.parent = User.find(to_ulong(_request._params["comment[user]"]));

		if(_comment.save()) {
			flash_notice("The comment was updated.");
			redirect_to("/comments/show/" ~ to_s(_comment.id));
		} else {
			render_view("edit");
		}
	}

	public void destroy() {
		_comment = Comment.find(to_ulong(_request._params["id"]));
		if(_comment.destroy()) {
			flash_notice("The comment was destroyed.");
			redirect_to("/comments/index");
		} else {
			flash_error(_comment.errors()[0]);
			render_view("index");
		}
	}
}


