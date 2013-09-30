/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/

/****h* server/server.d
 *  NAME
 *    server.d
 *  FUNCTION
 *    Contains the development Rootin Tootin server. It watches the project
 *    files and automatically rebuilds them and runs them as the application.
 ******
 */

private import tango.io.device.File;
private import tango.text.json.Json;

private import dlang_helper;
private import file_system;
private import rootintootin;
private import rootintootin_process;
private import app_builder;


int main(string[] args) {
	// Make sure the args are correct
	if(args.length < 2)
		throw new Exception("Usage: server [development|production] 'application path'");
	string mode = args[1];
	string app_path = args.length==3 ? args[2] : "";
	bool is_production = (mode == "production");

	// Read the server config file
	auto file = new File("config/config.json", File.ReadExisting);
	auto content = new char[cast(size_t)file.length];
	file.read(content);
	file.close();
	auto values = (new Json!(char)).parse(content).toObject();

	string[string][string][string] config;
	foreach(n1, v1; values.attributes()) {
		foreach(n2, v2; v1.toObject().attributes()) {
			foreach(n3, v3; v2.toObject().attributes()) {
				config[n1][n2][n3] = v3.toString();
			}
		}
	}

	// Create and start the sever
	ushort port = to_ushort(config[mode]["server"]["port"]);
	int max_waiting_clients = to_int(config[mode]["server"]["max_waiting_clients"]);
	auto server = new RootinTootinServerProcess(
				port, max_waiting_clients, 
				app_path, "./application", 
				false, is_production);

	server.start();

	return 0;
}

