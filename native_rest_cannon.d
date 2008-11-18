
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

public class ModelBase {

}

public template ModelBaseMixin(T, char[] table_name) {
	static char[] _table_name = table_name;

	static int find_by_id(int id) {
		char[] query = "select * from " ~ typeof(T)._table_name ~ " where id=" ~ tango.text.convert.Integer.toString(id);
		return 7;
	}

	static char[] field_names_as_comma_string() {
		return tango.text.Util.join(_field_names, ", ");
	}

	static T[] find_all() {
		T[] all = [];

		char[] query = "select " ~ field_names_as_comma_string ~ " from users order by id;";
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




/*
//	NOTE: LOOK AT THIS OTHER WAY OF DOING IT
//	Here is anothe way to do it. 
//	Notice how they can iterate over the fields with tupleof. 
//	We can use that when we save the values back into the db.


class IntField : IField {
    int value;
    void opAssign(int v) {
        this.value = v;
    }
    int opCall() {
        return this.value;
    }
    char[] toString() {
        return .toString(this.value);
    }
}

interface IModel {
}

class Model(T) : IModel {
    IField[] fields;
    this() {
        T self = cast(T)this;
        foreach (i, f; self.tupleof) {
            static if (is(typeof(f) : IField)) {
                self.tupleof[i] = new typeof(f);
                this.fields ~= self.tupleof[i];
            }
        }
    }
}

class MyModel : Model!(MyModel) {
    IntField x, y, z;
    this() { super(); }
} 

*/
