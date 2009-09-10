

public class MessageController : ControllerBase {
	public Message[] _messages;
	public Message _message;

	public void index() {
		_messages = Message.find_all();
	}

	public void show() {
		_message = Message.find(to_ulong(_request.params["id"]));
	}

	public void New() {
		_message = new Message();
	}

	public void create() {
		_message = new Message();
		_message.text = _request.params["message[text]"];

		if(_message.save()) {
			redirect_to("/messages/show/" ~ to_s(_message.id));
			trigger_event("on_create");
		} else {
			render_view("new");
		}
	}

	public void edit() {
		_message = Message.find(to_ulong(_request.params["id"]));
	}

	public void update() {
		_message = Message.find(to_ulong(_request.params["id"]));
		_message.text = _request.params["message[text]"];

		if(_message.save()) {
			redirect_to("/messages/show/" ~ to_s(_message.id));
		} else {
			render_view("edit");
		}
	}

	public void destroy() {
		_message = Message.find(to_ulong(_request.params["id"]));
		_message.destroy();

		redirect_to("/messages/index");
	}

	public void on_create() {
		_use_layout = false;
		_messages = Message.find_all();
	}
}


