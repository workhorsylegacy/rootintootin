/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


/****h* rootintootin/rootintootin.d
 *  NAME
 *    rootintootin.d
 *  FUNCTION
 *    This file contains the core functionality that is used by
 *    the server and applications.
 ******
 */

public import language_helper;
public import db;
private import helper;
private import http_server;

// FIXME: Rename this to ResourceRunnerBase
// FIXME: Remove the id argument because it is duplicating the id in the params.
// FIXME: Remove the events_to_trigger argument.
/****c* rootintootin/RunnerBase
 *  NAME
 *    RunnerBase
 *  FUNCTION
 *    A base class for the generated application class.
 ******
 */
public class RunnerBase {
	/****m* rootintootin/RunnerBase.this
	 *  FUNCTION
	 *    A constructor.
	 *  INPUTS
	 *    request             - the request that was routed to this runner.
	 *    controller_name     - the name of the controller to route to.
	 *    action_name         - the name of the action to route to.
	 *    id                  - the id of the resource to route to. Use null for no id.
	 *    events_to_trigger   - a list of events to trigger for long poll.
	 *  NOTES
	 *    id will be removed because it is duplicating the id in the 
	 *    request.params, and not even used.
	 *    events_to_trigger will be removed soon.
	 * SOURCE
	 */
	public string run_action(Request request, string controller_name, string action_name, string id, out string[] events_to_trigger) {
		return null;
	}
	/*******/
}

/****c* rootintootin/RenderTextException
 *  NAME
 *    RenderTextException
 *  FUNCTION
 *    This exception is thrown when an action wants to render text directly.
 ******
 */
public class RenderTextException : Exception { 
	public string _text;
	public ushort _status;

	/****m* rootintootin/RenderTextException.this
	 *  FUNCTION
	 *    A constructor.
	 *  INPUTS
	 *    text                - the text to render.
	 *    status              - the http status.
	 * SOURCE
	 */
	public this(string text, ushort status) {
		super("");
		_text = text;
		_status = status;
	}
	/*******/
}

/****c* rootintootin/RenderViewException
 *  NAME
 *    RenderViewException
 *  FUNCTION
 *    This exception is thrown when an action wants to render a view.
 ******
 */
public class RenderViewException : Exception { 
	public string _name;
	public ushort _status;

	public this(string name, ushort status) {
		super("");
		_name = name;
		_status = status;
	}
}

/****c* rootintootin/RenderRedirectException
 *  NAME
 *    RenderRedirectException
 *  FUNCTION
 *    This exception is thrown when an action wants redirect to another url.
 ******
 */
public class RenderRedirectException : Exception { 
	public string _url;

	public this(string url) {
		super("");
		_url = url;
	}
}

/****c* rootintootin/RenderNoActionException
 *  NAME
 *    RenderNoActionException
 *  FUNCTION
 *    This exception is thrown when there is no action to route to.
 ******
 */
public class RenderNoActionException : Exception { 
	public this() {
		super("");
	}
}

/****c* rootintootin/RenderNoControllerException
 *  NAME
 *    RenderNoControllerException
 *  FUNCTION
 *    This exception is thrown when there is no controller to route to.
 ******
 */
public class RenderNoControllerException : Exception { 
	public string[] _controllers;

	public this(string[] controllers) {
		super("");
		_controllers = controllers;
	}
}

/****c* rootintootin/ModelException
 *  NAME
 *    ModelException
 *  FUNCTION
 *    This exception is thrown when there is an error relating to models.
 ******
 */
public class ModelException : Exception {
	public this(string message) {
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


/****c* rootintootin/ModelBase
 *  NAME
 *    ModelBase
 *  FUNCTION
 *    This class is the base of all the model classes.
 ******
 */
public class ModelBase {
	protected ulong _id;
	protected string[] _errors;

	public ulong id() {
		return _id;
	}

	public void validate() {
	}

	public bool is_valid() {
		this.validate();
		return this._errors.length == 0;
	}

	public string[] errors() {
		return this._errors;
	}

	public string to_json() {
		return null;
	}

	public string to_xml() {
		return null;
	}

	public static string to_json(ModelBase[] models) {
		string[] retval;
		foreach(ModelBase model ; models) {
			retval ~= model.to_json();
		}
		return "[" ~ join(retval, ", ") ~ "]";
	}

	public static string to_xml(ModelBase[] models, string table_name) {
		string[] retval;
		foreach(ModelBase model ; models) {
			retval ~= model.to_xml();
		}

		string name = table_name;

		return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" ~ 
				"<" ~ name ~ " type=\"array\">" ~ 
				join(retval, "") ~ 
				"</" ~ name ~ ">";
	}
}

public template ModelBaseMixin(T, string model_name, string table_name) {
	static string _table_name = table_name;
	static string _model_name = model_name;

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

		foreach(string field_name; model._unique_field_names) {
			this.set_field_by_name(field_name, model.get_field_by_name(field_name), false);
		}
		_was_pulled_from_database = true;
	}

	static string field_names_as_comma_string() {
		return join(_field_names, ", ");
	}

	static string unique_field_names_as_comma_string() {
		return join(_unique_field_names, ", ");
	}

	string unique_fields_as_comma_string() {
		string[] fields;
		foreach(string field_name; _unique_field_names) {
			fields ~= "'" ~ this.get_field_by_name(field_name) ~ "'";
		}

		return join(fields, ", ");
	}

	// Returns a single model that matches the id, or null.
	static T find_by_id(ulong id) {
		// Create the query and run it
		string query = "select " ~ field_names_as_comma_string ~ " from " ~ T._table_name;
		query ~= " where id=" ~ to_s(id) ~ ";";
		int row_len, col_len;
		char*** result = Db.query_with_result(query, row_len, col_len);

		// Just return null if there was none found
		if(row_len == 0) {
			Db.free_query_with_result(result, row_len, col_len);
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

		Db.free_query_with_result(result, row_len, col_len);

		return model;
	}

	// Returns a single model that matches the id, or throws if not found.
	static T find(ulong id) {
		T model = find_by_id(id);
		if(model is null) {
			throw new ModelException("No '" ~ _model_name ~ "' with the id '" ~ to_s(id) ~ "' was found.");
		} else {
			return model;
		}
	}

	// Returns all the models of this type.
	static T[] find_all(string conditions = null, string order = null) {
		// Create the query and run it
		T[] all = [];
		string query = "select " ~ field_names_as_comma_string ~ " from " ~ _table_name;
		if(conditions != null) query ~= " where " ~ conditions;
		if(order != null) query ~= " order by " ~ order;
		query ~= ";";
		int row_len, col_len;
		char*** result = Db.query_with_result(query, row_len, col_len);

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

		Db.free_query_with_result(result, row_len, col_len);

		return all;
	}

	static T find_first() {
		return null;
	}

	bool is_saved() {
		return _id > 0;
	}

	bool save() {
		// Return false if the validation failed
		if(this.is_valid() == false)
			return false;

		string query = "";
		db.QueryResult result;

		// If there is no id, use an insert query
		if(!this.is_saved) {
			query ~= "insert into " ~ typeof(this)._table_name ~ "(" ~ unique_field_names_as_comma_string ~ ")";
			query ~= " values(";
			query ~= this.unique_fields_as_comma_string();
		 	query ~= ");";

			// Run the query, and save the id
			_id = Db.insert_query_with_result_id(query, result);
		} else {
		// If there is an id, use an update query
			query ~= "update " ~ typeof(this)._table_name ~ " set ";
			uint counter = 0;
			foreach(string field_name ; typeof(this)._unique_field_names) {
				counter++;
				query ~= field_name ~ "='" ~ this.get_field_by_name(field_name) ~ "'";
				if(counter < typeof(this)._unique_field_names.length) {
					query ~= ", ";
				}
			}
			query ~= " where id=" ~ to_s(this._id) ~ ";";

			// Run the query
			Db.update_query(query, result);
		}

		if(result == db.QueryResult.success) {
			return true;
		} else if(result == db.QueryResult.not_unique_error) {
			char[] message = Db.get_error_message();
			char[] field = before(after(message, "for key 'uc_"), "'");
			this._errors ~= "The " ~ field ~ " is already used.";
			return false;
		}

		return false;
	}

	bool destroy() {
		// Create the delete query
		string query = "";
		query ~= "delete from " ~ typeof(this)._table_name;
		query ~= " where id=" ~ to_s(this._id) ~ ";";

		// Run the query
		db.QueryResult result;
		Db.delete_query(query, result);

		if(result == db.QueryResult.success) {
			return true;
		} else if(result == db.QueryResult.foreign_key_constraint_error) {
			this._errors ~= "Failed to delete because of foreign key constraints.";
			return false;
		}

		return false;
	}

	void validates_presence_of(string[] field_names) {
		foreach(string field_name; field_names) {
			validates_presence_of(field_name);
		}
	}

	void validates_presence_of(string field_name) {
		char[] field = this.get_field_by_name(field_name);

		if(field == null || trim(field).length == 0) {
			_errors ~= "The " ~ field_name ~ " cannot be blank.";
		}
	}
}

public class ControllerBase {
	protected Request _request = null;
	protected bool _use_layout = true;
	public string[] _events_to_trigger;
	public string action_name;
	public string controller_name;

	public string[] events_to_trigger() { return this._events_to_trigger; }
	public bool use_layout() { return _use_layout; }
	public void request(Request value) { this._request = value; }
	public Request request() { return this._request; }
	public void flash_error(string value) { this.set_flash(value, "flash_error"); }
	public string flash_error() { return this.get_flash("flash_error"); }
	public void flash_notice(string value) { this.set_flash(value, "flash_notice"); }
	public string flash_notice() { return this.get_flash("flash_notice"); }

	private void set_flash(string value, string name) {
		if(!_request) return;
		_request._sessions[name] = value;
	}

	private string get_flash(string name) {
		if(_request && name in _request._sessions) {
			string value = _request._sessions[name];
			_request._sessions.remove(name);
			return value;
		} else {
			return "";
		}
	}

	public void respond_with(ModelBase model, string view_name, ushort status, string[] formats) {
		switch(_request.format) {
			case("html"): render_view(view_name, status); break;
			case("json"): render_text(model.to_json(), status); break;
			case("xml"): render_text(model.to_xml(), status); break;
			default: render_text("Unknown format. Try html, json, xml, et cetera.", 404); break;
		}
	}

	// FIXME: table_name is needed here to know how to pluralize the model name: <blahs type="array"><blah /></blah>
	// This should be gotten from ModelBase somehow.
	public void respond_with(string table_name, ModelBase[] models, string view_name, ushort status, string[] formats) {
		switch(_request.format) {
			case("html"): render_view(view_name, status); break;
			case("json"): render_text(ModelBase.to_json(models), status); break;
			case("xml"): render_text(ModelBase.to_xml(models, table_name), status); break;
			default: render_text("Unknown format. Try html, json, xml, et cetera.", 404); break;
		}
	}

	public void respond_with_redirect(ModelBase model, string url, ushort status, string[] formats) {
		string real_url = base_get_real_url(this, url);
		switch(_request.format) {
			case("html"): redirect_to(real_url); break;
			case("json"): render_text(model.to_json(), status); break;
			case("xml"): render_text(model.to_xml(), status); break;
			default: render_text("Unknown format. Try html, json, xml, et cetera.", 404); break;
		}
	}

	public void respond_with_redirect(string url, ushort status, string[] formats) {
		string real_url = base_get_real_url(this, url);
		switch(_request.format) {
			case("html"): redirect_to(real_url); break;
			case("json"): render_text("", status); break;
			case("xml"): render_text("", status); break;
			default: render_text("Unknown format. Try html, json, xml, et cetera.", 404); break;
		}
	}

	public void render_view(string name, ushort status) {
		throw new RenderViewException(name, status);
	}

	public void render_text(string text, ushort status) {
		throw new RenderTextException(text, status);
	}

	public void redirect_to(string url) {
		throw new RenderRedirectException(url);
	}

	public void trigger_event(string event_name) {
		this._events_to_trigger ~= event_name;
	}
}

public static string base_get_real_url(ControllerBase controller, string url) {
	// Get the format from the controller
	string format = "";
	if(controller.request.was_format_specified)
		format = "." ~ controller.request.format;

	// Get the url with the real format
	string url_before = before(url, "?");
	string url_after = after(url, "?");
	if(url_after.length > 0)
		url_after = "?" ~ url_after;
	return url_before ~ format ~ url_after;
}


