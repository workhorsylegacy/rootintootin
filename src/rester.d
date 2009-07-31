


import tango.text.convert.Integer;
import tango.text.Util;
import tango.stdc.stringz;
import tango.text.Regex;

import tango.io.Stdout;

import tango.time.chrono.Gregorian;
import tango.time.WallClock;

import language_helper;
import db;
import helper;

public enum ResponseType {
	normal,
	render_view, 
	render_text, 
	redirect_to
}

public class Request {
	private char[] _method = null;
	private char[] _uri = null;
	private char[] _http_version = null;
	private char[] _controller = null;
	private char[] _action = null;
	private char[][char[]] _params;
	private char[][char[]] _cookies;

	private ResponseType _response_type;
	private char[] _redirect_to_url = null;
	private char[] _render_view_name = null;
	private char[] _render_text_text = null;
	public char[][] events_to_trigger;

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

	public ResponseType response_type() { return _response_type; }
	public char[] redirect_to_url() { return _redirect_to_url; }
	public char[] render_view_name() { return _render_view_name; }
	public char[] render_text_text() { return _render_text_text; }

	public void response_type(ResponseType value) { _response_type = value; }
	public void redirect_to_url(char[] value) { _redirect_to_url = value; }
	public void render_view_name(char[] value) { _render_view_name = value; }
	public void render_text_text(char[] value) { _render_text_text = value; }
}

public class SqlError : Exception {
	public this(char[] message) {
		super(message);
	}
}

public template ModelArrayMixin(ParentClass, ModelClass) {
	ParentClass _parent = null;
	ModelClass[] _models;

	public this(ModelClass[] models) {
		_models = models;
	}

	public void opCatAssign(ModelClass model) {
		model.parent = _parent;
		_models ~= model;
	}

	public size_t length() {
		return _models.length;
	}
}

public class ModelBase {
	protected char[][] _errors;

	protected void reset_validation_errors() {
	}

	public bool is_valid() {
		this.reset_validation_errors();
		return this._errors.length == 0;
	}

	public char[][] errors() {
		return this._errors;
	}
}

public class RunnerBase {
	public char[] render_view(char[] controller_name, char[] view_name) {
		return null;
	}

	public char[] run_action(Request request) {
		return null;
	}
}

public template ModelBaseMixin(T, char[] model_name) {
	static char[] _table_name = model_name ~ "s";
	static char[] _model_name = model_name;

	private bool _was_pulled_from_database = true;

	public void after_this() {
	}

	private void ensure_was_pulled_from_database() {
		// Just return if is was already pulled
		if(_was_pulled_from_database == true) 
			return;

		if(_id < 1)
			throw new Exception(_model_name ~ "The id has not been set.");

		// Get the model from the database and copy all its fields to this model
		T model = T.find(_id);

		foreach(char[] field_name; model._unique_field_names) {
			this.set_field_by_name(field_name, model.get_field_by_name(field_name), false);
		}
		_was_pulled_from_database = true;
	}

	static char[] field_names_as_comma_string() {
		return tango.text.Util.join(_field_names, ", ");
	}

	static char[] unique_field_names_as_comma_string() {
		return tango.text.Util.join(_unique_field_names, ", ");
	}

	char[] unique_fields_as_comma_string() {
		char[][] fields;
		foreach(char[] field_name; _unique_field_names) {
			fields ~= "'" ~ this.get_field_by_name(field_name) ~ "'";
		}

		return tango.text.Util.join(fields, ", ");
	}

	// Returns a single model that matches the id, or null.
	static T find(ulong id) {
		// Create the query and run it
		char[] query = "select " ~ field_names_as_comma_string ~ " from " ~ T._table_name;
		query ~= " where id=" ~ to_s(id) ~ ";";
		int row_len, col_len;
		char*** result = db.db_query_with_result(query, row_len, col_len);

		// Just return null if there was none found
		if(row_len == 0) {
			db.free_db_query_with_result(result, row_len, col_len);
			return null;
		}

		// Copy all the fields into the model
		T model = new T();
		model._was_pulled_from_database = false;
		for(int i=0; i<col_len; i++) {
			model.set_field_by_name(_field_names[i], tango.stdc.stringz.fromStringz(result[0][i]), false);
		}
		model._was_pulled_from_database = true;
		model.after_this();

		db.free_db_query_with_result(result, row_len, col_len);

		return model;
	}

	// Returns a single model that matches the id, or throws if not found.
	static T find_by_id(ulong id) {
		T model = find(id);
		if(model is null) {
			throw new Exception("No '" ~ _model_name ~ "' with the id '" ~ to_s(id) ~ "' was found.");
		} else {
			return model;
		}
	}

	// Returns all the models of this type.
	static T[] find_all(char[] conditions = null, char[] order = null) {
		T[] all = [];

		// Create the query and run it
		char[] query = "select " ~ field_names_as_comma_string ~ " from " ~ _table_name;
		if(conditions != null) query ~= " where " ~ conditions;
		if(order != null) query ~= " order by " ~ order;
		query ~= ";";
		int row_len, col_len;
		char*** result = db.db_query_with_result(query, row_len, col_len);

		// Copy all the fields into each model
		T model = null;
		for(int i=0; i<row_len; i++) {
			model = new T();
			model._was_pulled_from_database = false;
			for(int j=0; j<col_len; j++) {
				model.set_field_by_name(_field_names[j], tango.stdc.stringz.fromStringz(result[i][j]), false);
			}
			model._was_pulled_from_database = true;
			model.after_this();
			all ~= model;
		}

		db.free_db_query_with_result(result, row_len, col_len);

		return all;
	}

	static T find_first() {
		return null;
	}

	bool save() {
		// Return false if the validation failed
		if(this.is_valid() == false)
			return false;

		char[] query = "";

		// If there is no id, use an insert query
		if(this._id < 1) {
			query ~= "insert into " ~ typeof(this)._table_name ~ "(" ~ unique_field_names_as_comma_string ~ ")";
			query ~= " values(";
			query ~= this.unique_fields_as_comma_string();
		 	query ~= ");";

			// Run the query, and save the id
			_id = db.db_insert_query_with_result_id(query);
		} else {
		// If there is an id, use an update query
			query ~= "update " ~ typeof(this)._table_name ~ " set ";
			uint counter = 0;
			foreach(char[] field_name ; typeof(this)._unique_field_names) {
				counter++;
				query ~= field_name ~ "='" ~ this.get_field_by_name(field_name) ~ "'";
				if(counter < typeof(this)._unique_field_names.length) {
					query ~= ", ";
				}
			}
			query ~= " where id=" ~ to_s(this._id) ~ ";";

			// Run the query
			db.db_update_query(query);
		}

		return true;
	}

	bool destroy() {
		// Create the delete query
		char[] query = "";
		query ~= "delete from " ~ typeof(this)._table_name;
		query ~= " where id=" ~ to_s(this._id) ~ ";";

		// Run the query
		db.db_update_query(query);

		return true;
	}
}

public template ControllerBaseMixin(T) {
	private Request _request = null;

	public this(Request request) {
		_request = request;
	}

	public void render_view(char[] name) {
		this._request.response_type = ResponseType.render_view;
		this._request.render_view_name = name;
	}

	public void render_text(char[] text) {
		this._request.response_type = ResponseType.render_text;
		this._request.render_text_text = text;
	}

	public void redirect_to(char[] url) {
		this._request.response_type = ResponseType.redirect_to;
		this._request.redirect_to_url = url;
	}

	public void trigger_event(char[] event_name) {
		this._request.events_to_trigger ~= event_name;
	}
}

