
/*
	Create database with:
	sqlite3 thing.db
	create table users(id integer primary key, name varchar(255), password varchar(255));
	insert into users(name, password) values('matt', 'ass');
	ctrl + D #to edit

	to compile:
	clear; valac --pkg gee-1.0 --pkg sqlite3 -o ActiveRecord ActiveRecord.vala
	./ActiveRecord
*/

using GLib;
using Gee;
using Sqlite;

public errordomain ModelErrors {
	SqlError
}

public delegate string GetFieldDelegate();
public delegate void SetFieldDelegate(string value);

public class ModelBase : Object {
	private static Database _db = null;
	private static string _table_name = null;
	private static ModelBase _new_model = null; // FIXME: This is just needed because we need a way to return info from the callbacks. Thread unsafe fail.

	//protected HashTable<string, GetFieldDelegate> _get_field_map = null;
	//protected HashTable<string, SetFieldDelegate> _set_field_map = null;

	protected HashMap<string, GetFieldDelegate> _get_field_map = null;
	protected HashMap<string, SetFieldDelegate> _set_field_map = null;

	public void map_fields(string name, SetFieldDelegate setter, GetFieldDelegate getter) {
		if(_set_field_map == null)
			_set_field_map = new HashMap<string, SetFieldDelegate>(str_hash, str_equal);
		if(_get_field_map == null) 
			_get_field_map = new HashMap<string, GetFieldDelegate>(str_hash, str_equal);

		_set_field_map[name] = setter;
		_get_field_map[name] = getter;
	}

	public static void connect_to_database(string name) {
		int rc = Database.open(name, out _db);
		if (rc != Sqlite.OK) {
			throw new ModelErrors.SqlError("Can't open database: %d, %s\n", rc, _db.errmsg());
		}
	}

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

	[NoArrayLength ()]
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

public class User : ModelBase {
	private string _name;

	construct {
		map_fields("name", set_name, get_name);
	}

	public void set_name(string value) {
		_name = value;
		stdout.printf("setting name to [%s]\n", _name);
	}

	public string get_name() {
		return _name;
	}

	//public string name {
	//	get { return _name; }
	//	set { _name = value; }
	//}

	public static User find_by_id(int id) {
		return (User)ModelBase.find_by_id(id);
	}
}

public class ProgramStart : Object {
	public static int main(string[] args) {
		ModelBase.connect_to_database("thing.db");

		User user = new User();
		user.set_name("first name");
		stdout.printf("[%s]\n", user.get_name());

		SetFieldDelegate setter = user._set_field_map["name"];
		//SetFieldDelegate setter = user.set_name;
		setter("Second name");
		stdout.printf("[%s]\n", user.get_name());

		//User model = User.find_by_id(1);
		//stdout.printf("[%s]\n", model.get_name());

		//model._set_field_map.lookup("name")("Swiffer");
		//stdout.printf("[%s]\n", model.get_name());

		stdout.printf("Done!\n");

		return 0;
	}
}

