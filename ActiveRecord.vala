
/*
	Create database with:
	sqlite3 thing.db
	create table users(id integer primary key, name varchar(255), password varchar(255));
	insert into users(name, password) values('matt', 'ass');
	ctrl + D #to edit

	to compile:
	clear; valac --pkg sqlite3 -o sqlitesample ActiveRecord.vala
	./ActiveRecord.vala
*/

using GLib;
using Sqlite;

public errordomain ModelErrors {
	SqlError
}

public class ModelBase : Object {
	private static Database _db = null;
	private static string _table_name = null;
	private static ModelBase _new_model = null; // FIXME: This is just needed because we need a way to return info from the callbacks. Thread unsafe fail.
	
	private HashTable<string, string> _fields = null;

	public HashTable<string, string> fields {
		get { return _fields; }
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
		_new_model = new ModelBase();
		_new_model._fields = new HashTable<string, string>(str_hash, str_equal);
		for (int i = 0; i < n_columns; i++) {
			_new_model._fields.insert(column_names[i], values[i]);
		}

		return 0;
	}
}

public class User : ModelBase {
	public static User find_by_id(int id) {
		return (User)ModelBase.find_by_id(id);
	}
}

public class ProgramStart : Object {
	public static int main(string[] args) {
		ModelBase.connect_to_database("thing.db");

		User model = User.find_by_id(1);
		stdout.printf(model.fields.lookup("name"));

		stdout.printf("Done!\n");

		return 0;
	}
}


