
/*
	Create database with:
	sqlite3 thing.db
	create table users(id integer primary key, name varchar(255), password varchar(255));
	insert into users(name, password) values('matt', 'ass');
	ctrl + D #to edit

	to compile:
	clear; gdc -o ActiveRecord ActiveRecord.d
	./ActiveRecord
*/

import std.stdio;
//import mysql;
//import mysql_wrapper;


public class SqlError : Exception {
	public this(string message) {
		super(message);
	}
} 

public class ModelBase {
	//private static sqlite3* _db = null;
	private static ModelBase _new_model = null; // FIXME: This is just needed because we need a way to return info from the callbacks. Thread unsafe fail.

	public static void connect_to_database(string name) {
	//	int rc = sqlite3_open("thing.db", &_db);
	//	if (rc != SQLITE_OK) {
	//		throw new SqlError("Can't open database: %d, %s\n", rc, _db.errmsg());
	//	}
	}

	/*
	public static ModelBase find_by_id(int id) {
		// Get the sql for that row
		string query = "select * from %s where id=%d;".printf("users", id);
		int rc = _db.exec(query, (Sqlite.Callback)find_one_callback, null);
		if (rc != Sqlite.OK) { 
			string message = "SQL error: %d, %s\n".printf(rc, _db.errmsg());
			throw new ModelErrors.SqlError(message);
		}

		
		ModelBase model = _new_model;
		_new_model = null;

		return model;
	}
	*/

	//[NoArrayLength ()]
	private static int find_one_callback(void* data, 
								int n_columns, 
								string[] values,
								string[] column_names) {

		// Copy the row columns into the new model
		/*
		_new_model = new ModelBase();
		_new_model._fields = new HashTable<string, string>(str_hash, str_equal);
		for (int i = 0; i < n_columns; i++) {
			_new_model._fields.insert(column_names[i], values[i]);
		}
		*/

		for(int i=0; i<n_columns; i++) {
			//SetFieldDelegate setter = _new_model._set_field_map.lookup(column_names[i]);
			//if(setter != null)
			//	setter(values[i]);
		}

		return 0;
	}
}

public class Field(T) {
	private T _value;
	private string _name;

	public this(string name) {
		_name = name;
	}

	public void opAssign(T value) {
		_value = value;
	}
	public T opCall() {
		return _value;
	}
}

template ModelBaseMixin(T, string table_name) {
	static string _table_name = table_name;

	static int find_by_id(int id) {
		string query = "select * from " ~ typeof(T)._table_name ~ " where id=" ~ std.string.toString(id);
		return 7;
	}
}

public class User : ModelBase {
	mixin ModelBaseMixin!(User, "user");

	private Field!(string) name = null;
	private Field!(bool) hide_email_address = null;

	public this() {
		name = new Field!(string)("name");
		hide_email_address = new Field!(bool)("hide_email_address");
	}
}

void main() {
	// NOTE: to convert a string to a char* use std.string.toStringz(s1)
	//ModelBase.connect_to_database("thing.db");
	
	User user = new User();
	user.name = "first name";
	writefln("[%s]", user.find_by_id(7));
	writefln("[%s]", user.name());
	//TypeInfo t = typeid(int);

	writefln("Done!");

	return 0;
}


