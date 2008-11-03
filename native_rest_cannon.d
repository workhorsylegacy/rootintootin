
/*
	Create database with:
	sqlite3 thing.db
	create table users(id integer primary key, name varchar(255), password varchar(255));
	insert into users(name, password) values('matt', 'ass');
	ctrl + D #to edit

	to compile:
	gdc -o rail_cannon rail_cannon.d
	gdc -o rail_cannon_server rail_cannon_server.d

	gdc -c -fPIC rail_cannon.d -o rail_cannon.o
	gdc -c -fPIC rail_cannon_server.d -o rail_cannon_server.o
	gdc -c -fPIC index.d -o index.o
	./rail_cannon

	to benchmark:
	ab -c 100 -n 10000 http://127.0.0.1:2345/

*/

//import tango.io.digest.Digest;
import tango.text.convert.Integer;
import tango.text.Util;
import tango.io.Stdout;
import tango.text.Regex;
import tango.time.chrono.Gregorian;
import tango.time.WallClock;

//import mysql;
//import mysql_wrapper;


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
	//private static sqlite3* _db = null;
	private static ModelBase _new_model = null; // FIXME: This is just needed because we need a way to return info from the callbacks. Thread unsafe fail.

	public static void connect_to_database(char[] name) {
	//	int rc = sqlite3_open("thing.db", &_db);
	//	if (rc != SQLITE_OK) {
	//		throw new SqlError("Can't open database: %d, %s\n", rc, _db.errmsg());
	//	}
	}

	/*
	public static ModelBase find_by_id(int id) {
		// Get the sql for that row
		char[] query = "select * from %s where id=%d;".printf("users", id);
		int rc = _db.exec(query, (Sqlite.Callback)find_one_callback, null);
		if (rc != Sqlite.OK) { 
			char[] message = "SQL error: %d, %s\n".printf(rc, _db.errmsg());
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
								char[][] values,
								char[][] column_names) {

		// Copy the row columns into the new model
		/*
		_new_model = new ModelBase();
		_new_model._fields = new HashTable<char[], char[]>(str_hash, str_equal);
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
	private char[] _name;

	public this(char[] name) {
		_name = name;
	}

	public void opAssign(T value) {
		_value = value;
	}

	public T opCall() {
		return _value;
	}
}

public template ModelBaseMixin(T, char[] table_name) {
	static char[] _table_name = table_name;

	static int find_by_id(int id) {
		char[] query = "select * from " ~ typeof(T)._table_name ~ " where id=" ~ tango.text.convert.Integer.toString(id);
		return 7;
	}

	static T[] find_all() {
		T[] ts = [];
		return ts;
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
	/*
	Object[][char[]] _members;
	Object[char[]] _member;

	void set(T)(char[] key, T thing) {
		_member[key] = cast(Object) thing;
	}

	void set_array(T)(char[] key, T thing) {
		_members[key] = cast(Object[]) thing;
	}

	T get(T)(char[] key) {
		return cast(T) _member[key];
	}

	T get_array(T)(char[] key) {
		return cast(T) _members[key];
	}
	*/
}

