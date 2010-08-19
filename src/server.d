/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.io.device.File;
private import tango.text.json.Json;

private import language_helper;
private import file_system;
private import rootintootin;
private import rootintootin_process;
private import app_builder;


int main(string[] args) {
	// Make sure the args are correct
	if(args.length < 3)
		throw new Exception("Usage: server 'application path' [development|production]");
	string app_path = args[1];
	string mode = args[2];
	bool is_production = (mode == "production");

	// Read the server config file
	auto file = new File("config/config.json", File.ReadExisting);
	auto content = new char[cast(size_t)file.length];
	file.read(content);
	file.close();
	auto values = (new Json!(char)).parse(content).toObject();

	string[string][string] config;
	foreach(n1, v1; values.attributes()) {
		if((is_production && n1 == "production") || 
			(!is_production && n1 == "development")) {
			foreach(n2, v2; v1.toObject().attributes()) {
				config[n2] = null;
				foreach(n3, v3; v2.toObject().attributes()) {
					config[n2][n3] = v3.toString();
				}
			}
		}
	}

	// Create and start the sever
	ushort port = to_ushort(config["server"]["port"]);
	int max_waiting_clients = to_int(config["server"]["max_waiting_clients"]);
	auto server = new RootinTootinServerProcess(
				port, max_waiting_clients, 
				app_path, "./application", 
				false, is_production);

	server.start();

	return 0;
}

