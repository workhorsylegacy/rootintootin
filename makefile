
all:
	@echo "'sudo make install' - Installs Rootin Tootin for normal web development."
	@echo "'sudo make dev'     - Installs Rootin Tootin for development on the framework itself."
	@echo "'sudo make remove'  - Removes Rootin Tootin from the system."

remove:
	rm -f /usr/bin/rootintootin
	rm -f /usr/bin/rootintootin_run
	rm -f /usr/bin/rootintootin_gen
	rm -f /usr/bin/rootintootin_deploy
	rm -f -rf /usr/share/rootintootin/
	rm -f /usr/share/rootintootin

install: remove
	cp -R . /usr/share/rootintootin/
	ln -s /usr/share/rootintootin/bin/rootintootin /usr/bin/rootintootin
	ln -s /usr/share/rootintootin/bin/rootintootin_run /usr/bin/rootintootin_run
	ln -s /usr/share/rootintootin/bin/rootintootin_gen /usr/bin/rootintootin_gen
	ln -s /usr/share/rootintootin/bin/rootintootin_deploy /usr/bin/rootintootin_deploy

dev: remove
	ln -s `pwd` /usr/share/rootintootin
	ln -s /usr/share/rootintootin/bin/rootintootin /usr/bin/rootintootin
	ln -s /usr/share/rootintootin/bin/rootintootin_run /usr/bin/rootintootin_run
	ln -s /usr/share/rootintootin/bin/rootintootin_gen /usr/bin/rootintootin_gen
	ln -s /usr/share/rootintootin/bin/rootintootin_deploy /usr/bin/rootintootin_deploy

