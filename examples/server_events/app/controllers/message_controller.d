
private import rootintootin;
private import message;

public class MessageController : ControllerBase {
	public Message[] _messages;
	public Message _message;

	public void index() {
		_messages = Message.find_all();
		respond_with(_messages, "index", 200, ["html", "json"]);
	}

	public void show() {
		_message = Message.find(to_ulong(_request._params["id"]));
		respond_with(_message, "show", 200, ["html", "json"]);
	}

	public void New() {
		_message = new Message();
		respond_with(_message, "new", 200, ["html", "json"]);
	}

	public void create() {
		_message = new Message();
		_message.text = _request._params["message[text]"];

		if(_message.save()) {
			trigger_event("on_create");
			flash_notice("The message was saved.");
			respond_with_redirect(_message, "/messages/" ~ to_s(_message.id), 200, ["html", "json"]);
		} else {
			respond_with(_message, "new", 422, ["html", "json"]);
		}
	}

	public void edit() {
		_message = Message.find(to_ulong(_request._params["id"]));
		respond_with(_message, "edit", 200, ["html", "json"]);
	}

	public void update() {
		_message = Message.find(to_ulong(_request._params["id"]));
		_message.text = _request._params["message[text]"];

		if(_message.save()) {
			flash_notice("The message was updated.");
			respond_with_redirect(_message, "/messages/" ~ to_s(_message.id), 200, ["html", "json"]);
		} else {
			respond_with(_message, "edit", 200, ["html", "json"]);
		}
	}

	public void destroy() {
		_message = Message.find(to_ulong(_request._params["id"]));
		if(_message.destroy()) {
			flash_notice("The message was destroyed.");
			respond_with_redirect("/messages", 200, ["html", "json"]);
		} else {
			flash_error(_message.errors()[0]);
			respond_with(_message, "index", 422, ["html", "json"]);
		}
	}

	public void on_create() {
		_use_layout = false;
		_messages = Message.find_all();
	}
}


