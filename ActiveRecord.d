
/*
	Create database with:
	sqlite3 thing.db
	create table users(id integer primary key, name varchar(255), password varchar(255));
	insert into users(name, password) values('matt', 'ass');
	ctrl + D #to edit

	to compile:
	clear; gdc -o ActiveRecord ActiveRecord.d
	./ActiveRecord

	to benchmark:
	ab -c 100 -n 10000 http://127.0.0.1:2345/

*/

import std.stdio;
import std.socket;
import std.regexp;
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

	static T[] find_all() {
		T[] ts = [];
		return ts;
	}

	static T find_first() {
		return null;
	}
}

public class User : ModelBase {
	mixin ModelBaseMixin!(User, "user");

	public Field!(string) name = null;
	public Field!(bool) hide_email_address = null;

	public this() {
		name = new Field!(string)("name");
		hide_email_address = new Field!(bool)("hide_email_address");
	}
}

template ControllerBaseMixin(T) {
	Object[][string] _members;
	Object[string] _member;

	void set(T)(string key, T thing) {
		_member[key] = cast(Object) thing;
	}

	void set_array(T)(string key, T thing) {
		_members[key] = cast(Object[]) thing;
	}

	T get(T)(string key) {
		return cast(T) _member[key];
	}

	T get_array(T)(string key) {
		return cast(T) _members[key];
	}
}

public class UserController {
	mixin ControllerBaseMixin!(UserController);

	public void index() {
		User[] users = User.find_all();
		User user = new User();
		user.name = "bobrick";
		users ~= user;

		set_array!(User[])("users", users);
		set!(User)("user", user);


		users = get_array!(User[])("users");
		user = get!(User)("user");
	}
}

public string render(UserController controller, out int[int] line_translations) {
	// Generate the view as an array of strings
	string[] builder;
	builder ~= "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"\n";
	builder ~= "       \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";
	builder ~= "\n";
	builder ~= "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">\n";
	builder ~= "	<head>\n";
	builder ~= "		<meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\" />\n";
	builder ~= "		<title>Example D View</title>\n";
	builder ~= "	</head>\n";
	builder ~= "	<body>\n";
	builder ~= "		<table border=\"1\">\n";
				foreach(User user ; controller.get_array!(User[])("users")) {
	builder ~= "			<tr>\n";
	builder ~= "				<td>"; builder ~= user.name(); builder ~= "</td>\n";
	builder ~= "			</tr>\n";
				}
	builder ~= "		</table>\n";
	builder ~= "	</body>\n";
	builder ~= "</html>\n";

	// Set the line translations so we can match lines in the blah.html.d with lines in the blah.html.dll
	line_translations[20] = 10;
	line_translations[22] = 12;
	line_translations[24] = 14;

	return std.string.join(builder, "");
}

void main() {
	/*
     respStatus.Add(200, "200 Ok");
     respStatus.Add(201, "201 Created");
     respStatus.Add(202, "202 Accepted");
     respStatus.Add(204, "204 No Content");

     respStatus.Add(301, "301 Moved Permanently");
     respStatus.Add(302, "302 Redirection");
     respStatus.Add(304, "304 Not Modified");
     
     respStatus.Add(400, "400 Bad Request");
     respStatus.Add(401, "401 Unauthorized");
     respStatus.Add(403, "403 Forbidden");
     respStatus.Add(404, "404 Not Found");

     respStatus.Add(500, "500 Internal Server Error");
     respStatus.Add(501, "501 Not Implemented");
     respStatus.Add(502, "502 Bad Gateway");
     respStatus.Add(503, "503 Service Unavailable");

	*/
	const int MAX_CONNECTIONS = 100;
	TcpSocket listener = new TcpSocket();
	listener.blocking = false;
	listener.bind(new InternetAddress(2345));
	listener.listen(MAX_CONNECTIONS);
	SocketSet sset = new SocketSet(MAX_CONNECTIONS + 1);
	Socket[] reads;

	while(true) {
		sset.reset();
		sset.add(listener);
		foreach(Socket each; reads) {
			sset.add(each);
		}
		Socket.select(sset, null, null);

		int read = 0;
		for(int i=0; i<reads.length; i++) {
			if(sset.isSet(reads[i]) == false) {
				continue;
			}

			char[1024] buffer;
			read = reads[i].receive(buffer);

			if(Socket.ERROR == read) {
				printf("Connection error.\n");
			} else if(0 == read) {
				try {
					//if the connection closed due to an error, remoteAddress() could fail
					printf("Connection from %.*s closed.\n", reads[i].remoteAddress().toString());
				} catch {
				}
			} else {
				printf("Received %d bytes from %.*s: \n\"%.*s\"\n", read, reads[i].remoteAddress().toString(), buffer[0 .. read]);

				// Get the request
				string[] request = std.string.splitlines(buffer[0 .. read]);

				// Get the header
				string[] header = std.string.split(request[0]);
				string method = header[0];
				string uri = header[1];
				string http_version = header[2];

				// Get the host
				string host = null;
				foreach(string line ; request) {
					auto reg = std.regexp.search(line, ": ");
					if(reg && reg.pre == "Host") {
						host = reg.post;
						break;
					}
				}

				// get the user agent
				string user_agent = null;
				foreach(string line ; request) {
					auto reg = std.regexp.search(line, ": ");
					if(reg && reg.pre == "User-Agent") {
						user_agent = reg.post;
						break;
					}
				}

				// get the params
				string[string] params;
				if(std.regexp.search(uri, "[?]")) {
					foreach(string param ; std.string.split(std.string.split(uri, "?")[1], "&")) {
						string[] pair = std.string.split(param, "=");
						params[pair[0]] = pair[1];
					}
				}

				// get the controller and action
				string[] route = std.string.split(std.string.split(uri, "[?]")[0], "/");
				string controller = route.length > 1 ? route[1] : null;
				string action = route.length > 2 ? route[2] : "index";
				string id = route.length > 3 ? route[3] : null;

				// FIXME: Just render the /user/index action for now.
				UserController con = new UserController();
				con.index();
				int[int] line_translations;
				// FIXME: This should add the HTTP headers to the top of the page before sending
				reads[i].send(render(con, line_translations));
			}

			//remove from reads
			reads[i].close();
			if(i != reads.length - 1)
				reads[i] = reads[reads.length - 1];
			reads = reads[0 .. reads.length - 1];
			printf("\tTotal connections: %d\n", reads.length);
		}


		//connection request
		if(sset.isSet(listener)) {
			Socket sn;
			try {
				if(reads.length < MAX_CONNECTIONS) {
					sn = listener.accept();
					printf("Connection from %.*s established.\n", sn.remoteAddress().toString());
					assert(sn.isAlive);
					assert(listener.isAlive);
				
					reads ~= sn;
					printf("\tTotal connections: %d\n", reads.length);
				} else {
					sn = listener.accept();
					printf("Rejected connection from %.*s; too many connections.\n", sn.remoteAddress().toString());
					assert(sn.isAlive);
				
					sn.close();
					assert(!sn.isAlive);
					assert(listener.isAlive);
				}
			} catch(Exception e) {
				printf("Error accepting: %.*s\n", e.toString());
			
				if(sn)
					sn.close();
			}
		}
	}

	int[] a = [1, 2, 3, 4, 5];
	// NOTE: to convert a string to a char* use std.string.toStringz(s1)
	//ModelBase.connect_to_database("thing.db");
	
	User user = new User();
	writefln("%d", user.sizeof); 
	user.name = "first name";
	writefln("[%s]", user.find_by_id(7));
	writefln("[%s]", user.name());
	//TypeInfo t = typeid(int);

	writefln("Done!");

	return 0;
}


