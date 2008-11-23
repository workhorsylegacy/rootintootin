


//import tango.io.digest.Digest;

import tango.text.convert.Integer;
import tango.text.Util;
import tango.stdc.stringz;
import tango.text.Regex;

import tango.io.Stdout;

import tango.time.chrono.Gregorian;
import tango.time.WallClock;

import db;

public class Request {
	private char[] _method;
	private char[] _uri;
	private char[] _http_version;
	private char[] _controller;
	private char[] _action;
	private char[][char[]] _params;
	private char[][char[]] _cookies;

	public this(char[] method, char[] uri, char[] http_version, char[] controller, char[] action, char[][char[]] params, char[][char[]] cookies) {
		_method = method;
		_uri = uri;
		_http_version = http_version;
		_controller = controller;
		if(action == "new") {
			_action = "New";
		} else {
			_action = action;
		}
		_params = params;
		_cookies = cookies;
	}

	public char[] method() { return _method; }
	public char[] uri() { return _uri; }
	public char[] http_version() { return _http_version; }
	public char[] controller() { return _controller; }
	public char[] action() { return _action; }
	public char[][char[]] params() { return _params; }
	public char[][char[]] cookies() { return _cookies; }
}

public class SqlError : Exception {
	public this(char[] message) {
		super(message);
	}
}

public class ModelBase {

}

public template ModelBaseMixin(T, char[] model_name) {
	static char[] _table_name = model_name ~ "s";
	static char[] _model_name = model_name;

	static char[] field_names_as_comma_string() {
		return tango.text.Util.join(_field_names, ", ");
	}

	// Returns a single model that matches the id, or null.
	static T find(int id) {
		char[] query = "select * from " ~ typeof(T)._table_name ~ " where id=" ~ tango.text.convert.Integer.toString(id) ~ ";";
		int row_len, col_len;
		char*** result = db.d_db_query(query, row_len, col_len);

		// Just return null if there was none found
		if(row_len == 0) return null;

		T model = new T();
		for(int i=0; i<col_len; i++) {
			model.set_field_by_name(_field_names[i], tango.stdc.stringz.fromStringz(result[0][i]));
		}

		db.d_free_db_query(result, row_len, col_len);

		return model;
	}

	// Returns a single model that matches the id, or throws if not found.
	static T find_by_id(int id) {
		T model = find(id);
		if(model == null) {
			throw new Exception("No {} with the id '{}' was found.", _model_name, id);
		} else {
			return model;
		}
	}

	// Returns all the models of this type.
	static T[] find_all(char[] conditions = null, char[] order = null) {
		T[] all = [];

		char[] query = "select " ~ field_names_as_comma_string ~ " from " ~ _table_name;
		if(conditions != null) query ~= " where " ~ conditions;
		if(order != null) query ~= " order by " ~ order;
		query ~= ";";
		Stdout(query).flush;

		int row_len, col_len;
		char*** result = db.d_db_query(query, row_len, col_len);

		T model = null;
		for(int i=0; i<row_len; i++) {
			model = new T();
			for(int j=0; j<col_len; j++) {
				model.set_field_by_name(_field_names[j], tango.stdc.stringz.fromStringz(result[i][j]));
			}
			all ~= model;
		}

		db.d_free_db_query(result, row_len, col_len);

		return all;
	}

	static T find_first() {
		return null;
	}
}

public class ControllerBase {

}

public template ControllerBaseMixin(T) {
	private Request _request = null;

	public this(Request request) {
		_request = request;
	}
}

