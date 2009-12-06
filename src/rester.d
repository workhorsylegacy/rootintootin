


private import tango.text.convert.Integer;
private import tango.text.Util;
private import tango.stdc.stringz;
private import tango.text.Regex;

private import tango.io.Stdout;

private import tango.time.chrono.Gregorian;
private import tango.time.WallClock;
private import tango.core.Thread;

public import language_helper;
private import db;
private import helper;
private import http_server;

public class RunnerBase {
	public char[] run_action(Request request, char[] controller_name, char[] action_name, char[] id, out char[][] events_to_trigger) {
		return null;
	}
}

public class ManualRenderException : Exception {
	public ResponseType _response_type;
	public char[] _payload;

	public this(ResponseType response_type, char[] payload) {
		super("");
		_response_type = response_type;
		_payload = payload;
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

public template ModelBaseMixin(T, char[] model_name, char[] table_name) {
	static char[] _table_name = table_name;
	static char[] _model_name = model_name;

	// FIXME: This should be private
	public bool _was_pulled_from_database = true;

	public void after_this() {
	}

	// FIXME: This should be private
	public void ensure_was_pulled_from_database() {
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
		// Get the connection id from the current thread
		size_t connection_id = cast(size_t) to_int(tango.core.Thread.Thread.getThis().name);

		// Create the query and run it
		char[] query = "select " ~ field_names_as_comma_string ~ " from " ~ T._table_name;
		query ~= " where id=" ~ to_s(id) ~ ";";
		int row_len, col_len;
		char*** result = db.db_query_with_result(connection_id, query, row_len, col_len);

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
		// Get the connection id from the current thread
		size_t connection_id = cast(size_t) to_int(tango.core.Thread.Thread.getThis().name);

		// Create the query and run it
		T[] all = [];
		char[] query = "select " ~ field_names_as_comma_string ~ " from " ~ _table_name;
		if(conditions != null) query ~= " where " ~ conditions;
		if(order != null) query ~= " order by " ~ order;
		query ~= ";";
		int row_len, col_len;
		char*** result = db.db_query_with_result(connection_id, query, row_len, col_len);

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
		// Get the connection id from the current thread
		size_t connection_id = cast(size_t) to_int(tango.core.Thread.Thread.getThis().name);

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
			_id = db.db_insert_query_with_result_id(connection_id, query);
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
			db.db_update_query(connection_id, query);
		}

		return true;
	}

	bool destroy() {
		// Get the connection id from the current thread
		size_t connection_id = cast(size_t) to_int(tango.core.Thread.Thread.getThis().name);

		// Create the delete query
		char[] query = "";
		query ~= "delete from " ~ typeof(this)._table_name;
		query ~= " where id=" ~ to_s(this._id) ~ ";";

		// Run the query
		db.query_result result;
		db.db_delete_query(connection_id, query, result);

		if(result == db.query_result.success) {
			return true;
		} else if(result == db.query_result.foreign_key_constraint_failed) {
			this._errors ~= "Failed to delete because of foreign key constraints.";
			return false;
		}
	}
}

public class ControllerBase {
	protected Request _request = null;
	protected bool _use_layout = true;
	protected char[] _flash_notice = null;
	protected char[] _flash_error = null;
	public char[][] _events_to_trigger;

	public void flash_error(char[] value) { this._flash_error = value; }
	public void flash_notice(char[] value) { this._flash_notice = value; }
	public char[] flash_error() { return this._flash_error; }
	public char[] flash_notice() { return this._flash_notice; }
	public char[][] events_to_trigger() { return this._events_to_trigger; }
	public bool use_layout() { return _use_layout; }
	public void request(Request value) { this._request = value; }
	public Request request() { return this._request; }

	public void render_view(char[] name) {
		throw new ManualRenderException(ResponseType.render_view, name);
	}

	public void render_text(char[] text) {
		throw new ManualRenderException(ResponseType.render_text, text);
	}

	public void redirect_to(char[] url) {
		throw new ManualRenderException(ResponseType.redirect_to, url);
	}

	public void trigger_event(char[] event_name) {
		this._events_to_trigger ~= event_name;
	}
}

