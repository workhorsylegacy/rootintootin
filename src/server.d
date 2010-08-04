/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.io.Stdout;
private import tango.io.Console;
private import tango.sys.Process;
private import tango.io.device.File;
private import tango.text.json.Json;
private import tango.stdc.stringz;

private import language_helper;
private import file_system;
private import rootintootin;
private import rootintootin_process;
private import app_builder;


int main(string[] args) {
	// Make sure the first arg is the application path
	if(args.length < 2)
		throw new Exception("The first argument should be the application path.");
	string app_path = args[1];

	// Read the server config file
	auto file = new File("config/config.json", File.ReadExisting);
	auto content = new char[cast(size_t)file.length];
	file.read(content);
	file.close();
	auto values = (new Json!(char)).parse(content).toObject();

	string[string][string] config;
	foreach(n1, v1; values.attributes()) {
		foreach(n2, v2; v1.toObject().attributes()) {
			config[n2] = null;
			foreach(n3, v3; v2.toObject().attributes()) {
				config[n2][n3] = v3.toString();
			}
		}
	}

	// Create and start the sever
	ushort port = to_ushort(config["server_configuration"]["port"]);
	int max_waiting_clients = to_int(config["server_configuration"]["max_waiting_clients"]);
	auto server = new RootinTootinServerProcess(
				port, max_waiting_clients, 
				app_path, "./application", false);

	server.start();

	return 0;
}

