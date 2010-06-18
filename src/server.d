/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.io.Stdout;
private import tango.io.device.File;
private import tango.text.json.Json;

private import language_helper;
private import rootintootin;
private import rootintootin_server;


int main() {
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
	IOLoop.use_epoll = true;
	ushort port = to_ushort(config["server_configuration"]["port"]);
	int max_waiting_clients = to_int(config["server_configuration"]["max_waiting_clients"]);
	auto server = new RootinTootinServer(
				port, max_waiting_clients, "./application");

	server.start();

	return 0;
}

