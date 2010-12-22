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
private import web_helper;
private import http_server;


/****f* rootintootin/where
 *  FUNCTION
 *    Returns a clause that holds the 'where' part of the SQL query.
 *  INPUTS
 *    query     - the conditional part of the SQL query.
 *    values    - the values to put into the query.
 *  EXAMPLE
 *    Clause clause = where("name = ? and age = ?", "tim", 57);
 * SOURCE
 */
Clause where(T ...)(string query, T values) {
	string[] retval;

	// Make sure the query is not null or blank
	if(trim(query) == "") {
		throw new Exception("The query cannot be blank.");
	}

	// Make sure the number of params and arguments match
	size_t question_count = count(query, "?");
	if(question_count != values.length) {
		throw new Exception("There were " ~ to_s(question_count) ~ " parameter(s) expected, but " ~ to_s(values.length) ~ " parameter(s) provided.");
	}

	size_t i = 0;
	string[] parts = split(query, "?");
	foreach(value; values) {
		retval ~= parts[i++];
		// FIXME: Sanitize this as it is untrusted.
		retval ~= "'" ~ to_s(value) ~ "'";
	}
	retval ~= parts[i++];
	return new Clause("WHERE " ~ join(retval, ""));
}

unittest {
	describe("rootintootin#where", 
		it("Should create an SQL where clause", function() {
			string clause = where("name = ? and age = ?", "tim", 56)._value;
			assert(clause == "WHERE name = 'tim' and age = '56'");
		}),
		it("Should throw if there are too few arguments", function() {
			bool has_thrown = false;
			try {
				string clause = where("name = ? and age = ?", "tim")._value;
			} catch(Exception err) {
				has_thrown = true;
				assert(err.msg == "There were 2 parameter(s) expected, but 1 parameter(s) provided.");
			}
			assert(has_thrown);
		}),
		it("Should throw if there are too many arguments", function() {
			bool has_thrown = false;
			try {
				string clause = where("name = ? and age = ?", "tim", "bob", "frank")._value;
			} catch(Exception err) {
				has_thrown = true;
				assert(err.msg == "There were 2 parameter(s) expected, but 3 parameter(s) provided.");
			}
			assert(has_thrown);
		}),
		it("Should throw if the query is blank", function() {
			bool has_thrown = false;
			try {
				string clause = where(" ")._value;
			} catch(Exception err) {
				has_thrown = true;
				assert(err.msg == "The query cannot be blank.");
			}
			assert(has_thrown);
		})
	);
}
/*******/

/****f* rootintootin/order_by
 *  FUNCTION
 *    Returns a clause that holds the 'order by' part of the SQL query.
 *  INPUTS
 *    field_name     - the name of the field to sort by.
 * SOURCE
 */
Clause order_by(string field_name) {
	// Make sure the field is not null or blank
	if(field_name is null || trim(field_name) == "") {
		throw new Exception("The field name cannot be blank or null.");
	}

	return new Clause("ORDER BY " ~ field_name);
}

unittest {
	describe("rootintootin#order_by", 
		it("Should create an SQL order by clause", function() {
			string clause = order_by("name")._value;
			assert(clause == "ORDER BY name");
		}),
		it("Should throw if the field is null", function() {
			bool has_thrown = false;
			try {
				string clause = order_by(null)._value;
			} catch(Exception err) {
				has_thrown = true;
				assert(err.msg == "The field name cannot be blank or null.");
			}
			assert(has_thrown);
		}),
		it("Should throw if the field is blank", function() {
			bool has_thrown = false;
			try {
				string clause = order_by(" ")._value;
			} catch(Exception err) {
				has_thrown = true;
				assert(err.msg == "The field name cannot be blank or null.");
			}
			assert(has_thrown);
		})
	);
}
/*******/

/****f* rootintootin/group_by
 *  FUNCTION
 *    Returns a clause that holds the 'group by' part of the SQL query.
 *  INPUTS
 *    field_name     - the name of the field to group by.
 * SOURCE
 */
Clause group_by(string field_name) {
	// Make sure the field is not null or blank
	if(field_name is null || trim(field_name) == "") {
		throw new Exception("The field name cannot be blank or null.");
	}

	return new Clause("GROUP BY " ~ field_name);
}

unittest {
	describe("rootintootin#group_by", 
		it("Should create an SQL group by clause", function() {
			string clause = group_by("name")._value;
			assert(clause == "GROUP BY name");
		}),
		it("Should throw if the field is null", function() {
			bool has_thrown = false;
			try {
				string clause = group_by(null)._value;
			} catch(Exception err) {
				has_thrown = true;
				assert(err.msg == "The field name cannot be blank or null.");
			}
			assert(has_thrown);
		}),
		it("Should throw if the field is blank", function() {
			bool has_thrown = false;
			try {
				string clause = group_by(" ")._value;
			} catch(Exception err) {
				has_thrown = true;
				assert(err.msg == "The field name cannot be blank or null.");
			}
			assert(has_thrown);
		})
	);
}
/*******/

/****f* rootintootin/limit
 *  FUNCTION
 *    Returns a clause that holds the 'limit' part of the SQL query.
 *  INPUTS
 *    value     - the max number of rows to return.
 * SOURCE
 */
Clause limit(ulong value) {
	// Make sure the value is not zero
	if(value == 0) {
		throw new Exception("The value must be greater than zero.");
	}

	return new Clause("LIMIT " ~ to_s(value));
}

unittest {
	describe("rootintootin#limit", 
		it("Should create an SQL limit clause", function() {
			string clause = limit(2)._value;
			assert(clause == "LIMIT 2");
		}),
		it("Should throw if the value is 0", function() {
			bool has_thrown = false;
			try {
				string clause = limit(0)._value;
			} catch(Exception err) {
				has_thrown = true;
				assert(err.msg == "The value must be greater than zero.");
			}
			assert(has_thrown);
		})
	);
}
/*******/

/****c* rootintootin/Clause
 *  NAME
 *    Clause
 *  FUNCTION
 *    A class used to create SQL clauses for a query.
 ******
 */
public class Clause {
	public string _value;

	/****m* rootintootin/Clause.this
	 *  FUNCTION
	 *    A constructor.
	 *  INPUTS
	 *    value       - the string that makes up this part of the SQL clause.
	 * SOURCE
	 */
	public this(string value) {
		if(contains(value, ";"))
			throw new Exception("Sql clauses cannot contain ';'.");

		if(contains(value, "--"))
			throw new Exception("Sql clauses cannot contain '--'.");

		if(contains(value, "union"))
			throw new Exception("Sql clauses cannot contain 'union'.");

		_value = value;
	}

	unittest {
		describe("rootintootin#Clause", 
			it("Should not allow the sql injection '--'", function() {
				bool has_thrown = false;
				try {
					new Clause("--");
				} catch(Exception err) {
					has_thrown = true;
					assert(err.msg == "Sql clauses cannot contain '--'.");
				}
				assert(has_thrown);
			}),
			it("Should not allow the sql injection ';'", function() {
				bool has_thrown = false;
				try {
					new Clause(";");
				} catch(Exception err) {
					has_thrown = true;
					assert(err.msg == "Sql clauses cannot contain ';'.");
				}
				assert(has_thrown);
			}),
			it("Should not allow the sql injection 'union'", function() {
				bool has_thrown = false;
				try {
					new Clause("union");
				} catch(Exception err) {
					has_thrown = true;
					assert(err.msg == "Sql clauses cannot contain 'union'.");
				}
				assert(has_thrown);
			})
		);
	}
	/*******/
}

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

	/****m* rootintootin/RenderViewException.this
	 *  FUNCTION
	 *    A constructor.
	 *  INPUTS
	 *    name                - the name of the view to render.
	 *    status              - the http status.
	 * SOURCE
	 */
	public this(string name, ushort status) {
		super("");
		_name = name;
		_status = status;
	}
	/*******/
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

	/****m* rootintootin/RenderRedirectException.this
	 *  FUNCTION
	 *    A constructor.
	 *  INPUTS
	 *    url                - the url to redirect to.
	 * SOURCE
	 */
	public this(string url) {
		super("");
		_url = url;
	}
	/*******/
}

/****c* rootintootin/RenderNoActionException
 *  NAME
 *    RenderNoActionException
 *  FUNCTION
 *    This exception is thrown when there is no action to route to.
 ******
 */
public class RenderNoActionException : Exception { 
	/****m* rootintootin/RenderNoActionException.this
	 *  FUNCTION
	 *    A constructor.
	 * SOURCE
	 */
	public this() {
		super("");
	}
	/*******/
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

	/****m* rootintootin/RenderNoControllerException.this
	 *  FUNCTION
	 *    A constructor.
	 *  INPUTS
	 *    controllers    - An array that holds the names of all the known controllers.
	 * SOURCE
	 */
	public this(string[] controllers) {
		super("");
		_controllers = controllers;
	}
	/*******/
}

/****c* rootintootin/ModelException
 *  NAME
 *    ModelException
 *  FUNCTION
 *    This exception is thrown when there is an error relating to models.
 ******
 */
public class ModelException : Exception {
	/****m* rootintootin/ModelException.this
	 *  FUNCTION
	 *    A constructor.
	 *  INPUTS
	 *    message    - The message to throw.
	 * SOURCE
	 */
	public this(string message) {
		super(message);
	}
	/*******/
}

/****c* rootintootin/ModelArrayMixin
 *  NAME
 *    ModelArrayMixin
 *  FUNCTION
 *    This template mixin is used to create classes that hold arrays of models
 *     of a specific type. Because we can't know the type before hand, and we 
 *    don't want to use the generic ModelBase type, we create a template. 
 *    Typically this is all generated for you.
 *  EXAMPLE
 *  // The strongly typed Pets class is used instead of Pet[].
 *  public class Pets {
 *      mixin ModelArrayMixin!(PersonBase, PetBase);
 *  }
 *  
 *  // The pet model class in your application
 *  public class Pet : PetBase {
 *  }
 *
 *  // The person model class in your application
 *  public class Person : PersonBase {
 *      public Pets pets;
 *
 *      public this() {
 *          this.pets = new Pets([]);
 *      }
 *  }
 *
 *  // The generated base model that was created from the database schema.
 *  public class PetBase : ModelBase {
 *      mixin ModelBaseMixin!(Pet, "pet", "pets");
 *      protected static string[] _field_names;
 *      protected static string[] _unique_field_names;
 *
 *      public string name;
 *      public string email;
 *      protected PersonBase _person = null;
 *
 *      public void parent(PersonBase value) {
 *          _person = value;
 *      }
 *      public PersonBase parent() {
 *          return _person;
 *      }
 *
 *      public void set_field_by_name(string field_name, string value, bool must_check_database_first = true) {
 *      }
 *      public string get_field_by_name(string field_name) {
 *          return null;
 *      }
 *  }
 *
 *  // The generated base model that was created from the database schema.
 *  public class PersonBase : ModelBase {
 *      mixin ModelBaseMixin!(Person, "person", "people");
 *      protected static string[] _field_names;
 *      protected static string[] _unique_field_names;
 *
 *      public void set_field_by_name(string field_name, string value, bool must_check_database_first = true) {
 *      }
 *      public string get_field_by_name(string field_name) {
 *          return null;
 *      }
 *  }
 *
 *  // Now we can create pets and add them to persons.
 *  auto person = new Person();
 *  person.pets ~= new Pet();
 ******
 */
public template ModelArrayMixin(ParentClass, ModelClass) {
	ParentClass _parent = null;
	ModelClass[] _models;

	/****m* rootintootin/ModelArrayMixin.this
	 *  FUNCTION
	 *    A constructor.
	 *  INPUTS
	 *    models    - An array of models to initialize the object.
	 * SOURCE
	 */
	public this(ModelClass[] models) {
		_models = models;
	}
	/*******/

	/****m* rootintootin/ModelArrayMixin.opCatAssign
	 *  FUNCTION
	 *    Adds a model to the list of models.
	 *  INPUTS
	 *    model    - A model object to add.
	 * SOURCE
	 */
	public void opCatAssign(ModelClass model) {
		model.parent = _parent;
		_models ~= model;
	}
	/*******/

	/****m* rootintootin/ModelArrayMixin.length
	 *  FUNCTION
	 *    Returns the length of the list of models.
	 * SOURCE
	 */
	public size_t length() {
		return _models.length;
	}
	/*******/
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

	/****m* rootintootin/ModelBase.id
	 *  FUNCTION
	 *    Returns the model's database id. Will be zero if it has not
	 *    been saved. See ModelBaseMixin.is_saved.
	 * SOURCE
	 */
	public ulong id() {
		return _id;
	}
	/*******/

	/****m* rootintootin/ModelBase.validate
	 *  FUNCTION
	 *    This method is called in ModelBase.is_valid. By default
	 *    it does nothing. But you can override it in your models to
	 *    do validation. 
	 *
	 *    To set an error here, add a string to the _errors instance variable.
	 *  EXAMPLE
	 *    // Use one of the validate functions to do validation.
	 *    public class User : UserBase {
	 *        public void validate() {
	 *            _errors = [];
	 *            validates_presence_of(["name", "email"]);
	 *        }
	 *    }
	 * 
	 *    // Or do the validation your own way.
	 *    public class User : UserBase {
	 *        public void validate() {
	 *            string field = this.get_field_by_name("name");
	 *            if(field == "Tim")
	 *                _errors = ["I don't think so Tim."];
	 *        }
	 *    }
	 * SOURCE
	 */
	public void validate() {
	}
	/*******/

	/****m* rootintootin/ModelBase.is_valid
	 *  FUNCTION
	 *    This methhod is called in ModelBase.is_valid. By default
	 *    it does nothing. But you can override it i your models to
	 *    do custom validation.
	 * SOURCE
	 */
	public bool is_valid() {
		this.validate();
		return this._errors.length == 0;
	}
	/*******/

	/****m* rootintootin/ModelBase.errors
	 *  FUNCTION
	 *    Returns the list of errors that were set in the 
	 *    ModelBase.validate method.
	 * SOURCE
	 */
	public string[] errors() {
		return this._errors;
	}
	/*******/

	/****m* rootintootin/ModelBase.to_json
	 *  FUNCTION
	 *    Returns the model converted to json.
	 *    This method should be overridden by the inheriting class.
	 * SOURCE
	 */
	public string to_json() {
		return null;
	}
	/*******/

	/****m* rootintootin/ModelBase.to_xml
	 *  FUNCTION
	 *    Returns the model converted to xml.
	 *    This method should be overridden by the inheriting class.
	 * SOURCE
	 */
	public string to_xml() {
		return null;
	}
	/*******/

	/****m* rootintootin/ModelBase.to_json 2
	 *  FUNCTION
	 *    Returns an array of models converted to json.
	 *  INPUTS
	 *    models    - An array of models.
	 * SOURCE
	 */
	public static string to_json(ModelBase[] models) {
		string[] retval;
		foreach(ModelBase model ; models) {
			retval ~= model.to_json();
		}
		return "[" ~ join(retval, ", ") ~ "]";
	}
	/*******/

	/****m* rootintootin/ModelBase.to_xml 2
	 *  FUNCTION
	 *    Returns an array of models converted to xml.
	 *  INPUTS
	 *    models    - An array of models.
	 * SOURCE
	 */
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
	/*******/
}

/****c* rootintootin/ModelBaseMixin
 *  NAME
 *    ModelBaseMixin
 *  FUNCTION
 *    A template mixin that adds common functionality to models.
 ******
 */
public template ModelBaseMixin(T, string model_name, string table_name) {
	static string _table_name = table_name;
	static string _model_name = model_name;

	// FIXME: This should be private
	public bool _was_pulled_from_database = true;

	public void after_this() {
	}

	/****m* rootintootin/ModelBaseMixin.ensure_was_pulled_from_database
	 *  FUNCTION
	 *    This method should be called in the start of each field property 
	 *    method. It ensures that the object has gotten its initial values 
	 *    from the database if it should have. Or it throws a ModelException.
	 * SOURCE
	 */
	private void ensure_was_pulled_from_database() {
		// Just return if is was already pulled
		if(_was_pulled_from_database == true)
			return;

		if(_id < 1)
			throw new ModelException(_model_name ~ "The id has not been set.");

		// Get the model from the database and copy all its fields to this model
		T model = T.find(_id);

		foreach(string field_name; model._unique_field_names) {
			this.set_field_by_name(field_name, model.get_field_by_name(field_name), false);
		}
		_was_pulled_from_database = true;
	}
	/*******/

	/****m* rootintootin/ModelBaseMixin.field_names_as_comma_string
	 *  FUNCTION
	 *    Returns all the model's field names in a comma separated string.
	 * SOURCE
	 */
	static string field_names_as_comma_string() {
		return join(_field_names, ", ");
	}
	/*******/

	/****m* rootintootin/ModelBaseMixin.unique_field_names_as_comma_string
	 *  FUNCTION
	 *    Returns all the model's unique field names in a comma separated 
	 *    string.
	 * SOURCE
	 */
	static string unique_field_names_as_comma_string() {
		return join(_unique_field_names, ", ");
	}
	/*******/

	/****m* rootintootin/ModelBaseMixin.unique_fields_as_comma_string
	 *  FUNCTION
	 *    Returns all the model's unique fields in a comma separated 
	 *    string.
	 * SOURCE
	 */
	string unique_fields_as_comma_string() {
		string[] fields;
		foreach(string field_name; _unique_field_names) {
			fields ~= "'" ~ this.get_field_by_name(field_name) ~ "'";
		}

		return join(fields, ", ");
	}
	/*******/

	/****m* rootintootin/ModelBaseMixin.find_by_id
	 *  FUNCTION
	 *    Returns a single model that matches the id, or null if not found.
	 *  INPUTS
	 *    id          - The database id of the object to find.
	 * SOURCE
	 */
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
	/*******/

	/****m* rootintootin/ModelBaseMixin.find
	 *  FUNCTION
	 *    Returns a single model that matches the id, or throws if not found.
	 *  INPUTS
	 *    id    - The database id of the object to find.
	 * SOURCE
	 */
	static T find(ulong id) {
		T model = find_by_id(id);
		if(model is null) {
			throw new ModelException("No '" ~ _model_name ~ "' with the id '" ~ to_s(id) ~ "' was found.");
		} else {
			return model;
		}
	}
	/*******/

	/****m* rootintootin/ModelBaseMixin.find_all
	 *  FUNCTION
	 *    Returns all the models.
	 *  INPUTS
	 *    clauses  - The clauses to use to create the SQL select query.
	 *               Such as where, order by, and limit.
	 *  NOTES
	 *    For more info on variadic arguments see:
	 *    http://digitalmars.com/d/1.0/function.html#variadic
	 * SOURCE
	 */
	static T[] find_all(Clause[] clauses ...) {
		string[] retval;
		foreach(clause; clauses)
			retval ~= clause._value;

		// Create the query and run it
		T[] all = [];
		string query = "select " ~ field_names_as_comma_string ~ " from " ~ _table_name;
		if(retval.length)
			query ~= " " ~ join(retval, " ");
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

	unittest {
		describe("ModelBaseMixin.find_all", 
			it("Should find everything with no parameters", function() {
				assert(false);
			}),
			it("Should find one model with the id", function() {
				assert(false);
			})
		);
	}
	/*******/

	/****m* rootintootin/ModelBaseMixin.find_first
	 *  FUNCTION
	 *    Returns the first model found, or null if not found.
	 * SOURCE
	 */
	static T find_first(Clause[] clauses ...) {
		T[] models = find_all(clauses ~ limit(1));
		if(models.length > 0) {
			return models[0];
		} else {
			return null;
		}
	}
	/*******/

	/****m* rootintootin/ModelBaseMixin.is_saved
	 *  FUNCTION
	 *    Returns true if the id is greater than zero.
	 * SOURCE
	 */
	bool is_saved() {
		return _id > 0;
	}
	/*******/

	/****m* rootintootin/ModelBaseMixin.save
	 *  FUNCTION
	 *    Saves the model to the database. It will automatically determine if 
	 *    it needs to use an insert or update query. It checks the model to see
	 *    if it is valid. It also will add a unique field error if a uniqueness
	 *    constraint is broken.
	 *
	 *    Returns true on success, or false on failure.
	 * SOURCE
	 */
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
	/*******/

	/****m* rootintootin/ModelBaseMixin.destroy
	 *  FUNCTION
	 *    Deletes the model in the database. It also will add a 
	 *    foreign key error if a constraint is broken.
	 *
	 *    Returns true on success, or false on failure.
	 * SOURCE
	 */
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
	/*******/

	/****m* rootintootin/ModelBaseMixin.validates_presence_of
	 *  FUNCTION
	 *    If the field is null or white space, a message is added to 
	 *    the _errors array.
	 *    EG: "The name cannot be blank."
	 *  INPUTS
	 *    field_name   - The name of the field to validates.
	 * SOURCE
	 */
	void validates_presence_of(string field_name) {
		char[] field = this.get_field_by_name(field_name);

		if(field == null || trim(field).length == 0) {
			_errors ~= "The " ~ field_name ~ " cannot be blank.";
		}
	}
	/*******/

	/****m* rootintootin/ModelBaseMixin.validates_presence_of 2
	 *  FUNCTION
	 *    Does validates_presence_of for an array of fields.
	 *  INPUTS
	 *    field_names   - The names of the fields to validates.
	 * SOURCE
	 */
	void validates_presence_of(string[] field_names) {
		foreach(string field_name; field_names) {
			validates_presence_of(field_name);
		}
	}
	/*******/
}

/****c* rootintootin/ControllerBase
 *  NAME
 *    ControllerBase
 *  FUNCTION
 *    The base class for controllers.
 ******
 */
public class ControllerBase {
	protected Request _request = null;
	protected bool _use_layout = true;
	public string[] _events_to_trigger;
	public string action_name;
	public string controller_name;

	public string[] events_to_trigger() { return this._events_to_trigger; }

	/****m* rootintootin/ControllerBase.use_layout
	 *  FUNCTION
	 *    Returns true if it will use the default layout when rendering.
	 * SOURCE
	 */
	public bool use_layout() { return _use_layout; }
	/*******/

	/****m* rootintootin/ControllerBase.request( Request )
	 *  FUNCTION
	 *    Sets the current request.
	 * SOURCE
	 */
	public void request(Request value) { this._request = value; }
	/*******/

	/****m* rootintootin/ControllerBase.request
	 *  FUNCTION
	 *    Gets the current request.
	 * SOURCE
	 */
	public Request request() { return this._request; }
	/*******/

	/****m* rootintootin/ControllerBase.flash_error( string )
	 *  FUNCTION
	 *    Sets the current flash error message.
	 * SOURCE
	 */
	public void flash_error(string value) { this.set_flash(value, "flash_error"); }
	/*******/

	/****m* rootintootin/ControllerBase.flash_error
	 *  FUNCTION
	 *    Gets the current flash error message.
	 * SOURCE
	 */
	public string flash_error() { return this.get_flash("flash_error"); }
	/*******/

	/****m* rootintootin/ControllerBase.flash_notice(string)
	 *  FUNCTION
	 *    Sets the current flash notice message.
	 * SOURCE
	 */
	public void flash_notice(string value) { this.set_flash(value, "flash_notice"); }
	/*******/

	/****m* rootintootin/ControllerBase.flash_notice
	 *  FUNCTION
	 *    Gets the current flash notice message.
	 * SOURCE
	 */
	public string flash_notice() { return this.get_flash("flash_notice"); }
	/*******/

	/****m* rootintootin/ControllerBase.set_flash
	 *  FUNCTION
	 *    Sets the flash into the session.
	 *    Just returns if the request is null.
	 * SOURCE
	 */
	private void set_flash(string value, string name) {
		if(!_request) return;
		_request._sessions[name] = value;
	}
	/*******/

	/****m* rootintootin/ControllerBase.get_flash
	 *  FUNCTION
	 *    Gets the flash from the session.
	 *    Just returns "" if the request is null.
	 * SOURCE
	 */
	private string get_flash(string name) {
		if(_request && name in _request._sessions) {
			string value = _request._sessions[name];
			_request._sessions.remove(name);
			return value;
		} else {
			return "";
		}
	}
	/*******/

	/****m* rootintootin/ControllerBase.respond_with
	 *  FUNCTION
	 *    Sends the response to the client based on the state of the model.
	 *    This method is for one model.
	 *    Will automatically use the same format as the request.
	 *  INPUTS
	 *    model       - The model to generate the response from.
	 *    view_name   - The name of the view to render.
	 *    status      - The response HTTP status code.
	 *    formats     - An array of formats to render in.
	 * EXAMPLE
	 *    respond_with(_user, "edit", 200, ["html", "json", "xml"]);
	 * SOURCE
	 */
	public void respond_with(ModelBase model, string view_name, ushort status, string[] formats) {
		switch(_request.format) {
			case("html"): render_view(view_name, status); break;
			case("json"): render_text(model.to_json(), status); break;
			case("xml"): render_text(model.to_xml(), status); break;
			default: render_text("Unknown format. Try html, json, xml, et cetera.", 404); break;
		}
	}
	/*******/

	// FIXME: table_name is needed here to know how to pluralize the model name: <blahs type="array"><blah /></blahs>
	// This should be gotten from ModelBase somehow.
	/****m* rootintootin/ControllerBase.respond_with 2
	 *  FUNCTION
	 *    Sends the response to the client based on the state of the models.
	 *    This method is for a group of models.
	 *    Will automatically use the same format as the request.
	 *  INPUTS
	 *    table_name  - The database table name.
	 *    models      - The models to generate the response from.
	 *    view_name   - The name of the view to render.
	 *    status      - The response HTTP status code.
	 *    formats     - An array of formats to render in.
	 * EXAMPLE
	 *    respond_with("users", _users, "index", 200, ["html", "json", "xml"]);
	 * SOURCE
	 */
	public void respond_with(string table_name, ModelBase[] models, string view_name, ushort status, string[] formats) {
		switch(_request.format) {
			case("html"): render_view(view_name, status); break;
			case("json"): render_text(ModelBase.to_json(models), status); break;
			case("xml"): render_text(ModelBase.to_xml(models, table_name), status); break;
			default: render_text("Unknown format. Try html, json, xml, et cetera.", 404); break;
		}
	}
	/*******/

	/****m* rootintootin/ControllerBase.respond_with_redirect
	 *  FUNCTION
	 *    Sends a redirect response to the client for the model.
	 *    Will automatically use the same format as the request.
	 *  INPUTS
	 *    models      - The models to generate the response from.
	 *    url         - The name of the view to render.
	 *    status      - The response HTTP status code.
	 *    formats     - An array of formats to render in.
	 * EXAMPLE
	 *    respond_with_redirect(_user, "/users/" ~ to_s(_user.id), 200, ["html"]);
	 * SOURCE
	 */
	public void respond_with_redirect(ModelBase model, string url, ushort status, string[] formats) {
		string real_url = base_get_real_url(this, url);
		switch(_request.format) {
			case("html"): redirect_to(real_url); break;
			case("json"): render_text(model.to_json(), status); break;
			case("xml"): render_text(model.to_xml(), status); break;
			default: render_text("Unknown format. Try html, json, xml, et cetera.", 404); break;
		}
	}
	/*******/

	/****m* rootintootin/ControllerBase.respond_with_redirect 2
	 *  FUNCTION
	 *    Sends a redirect response to the client.
	 *    Will automatically use the same format as the request.
	 *  INPUTS
	 *    url         - The name of the view to render.
	 *    status      - The response HTTP status code.
	 *    formats     - An array of formats to render in.
	 * EXAMPLE
	 *    respond_with_redirect("/users", 200, ["html", "json", "xml"]);
	 * SOURCE
	 */
	public void respond_with_redirect(string url, ushort status, string[] formats) {
		string real_url = base_get_real_url(this, url);
		switch(_request.format) {
			case("html"): redirect_to(real_url); break;
			case("json"): render_text("", status); break;
			case("xml"): render_text("", status); break;
			default: render_text("Unknown format. Try html, json, xml, et cetera.", 404); break;
		}
	}
	/*******/

	/****m* rootintootin/ControllerBase.render_view
	 *  FUNCTION
	 *    Sends a view response to the client.
	 *  INPUTS
	 *    name        - The name of the view to render.
	 *    status      - The response HTTP status code.
	 * EXAMPLE
	 *    render_view("show", 200);
	 * SOURCE
	 */
	public void render_view(string name, ushort status) {
		throw new RenderViewException(name, status);
	}
	/*******/

	/****m* rootintootin/ControllerBase.render_text
	 *  FUNCTION
	 *    Sends a text response to the client.
	 *  INPUTS
	 *    text        - The text to render.
	 *    status      - The response HTTP status code.
	 * EXAMPLE
	 *    render_text("blah", 200);
	 * SOURCE
	 */
	public void render_text(string text, ushort status) {
		throw new RenderTextException(text, status);
	}
	/*******/

	/****m* rootintootin/ControllerBase.redirect_to
	 *  FUNCTION
	 *    Sends a redirect response to the client.
	 *  INPUTS
	 *    url        - The url to redirect to.
	 * EXAMPLE
	 *    redirect_to("users.html");
	 * SOURCE
	 */
	public void redirect_to(string url) {
		throw new RenderRedirectException(url);
	}
	/*******/

	public void trigger_event(string event_name) {
		this._events_to_trigger ~= event_name;
	}
}

/****f* rootintootin/base_get_real_url
 *  FUNCTION
 *    Returns the url
 *  INPUTS
 *    controller - The controller processing the request.
 *    url        - The url to redirect to.
 * EXAMPLE
 *    ControllerBase controller = new UserController();
 *    string real_url = base_get_real_url(controller, "/users");
 * SOURCE
 */
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
/*******/


