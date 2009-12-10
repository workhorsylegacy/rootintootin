
all:
	@echo "'sudo make install' - Installs it into the system."
	@echo "'sudo make remove' - Removes it from the system."
	@echo "'sudo make install_dev' - Links it to the system for development."

remove:
	rm -f /usr/bin/rootintootin
	rm -f /usr/bin/rootintootin_build
	rm -f /usr/bin/rootintootin_gen
	rm -f -rf /usr/share/rootintootin/
	rm -f /usr/share/rootintootin

install: remove
	cp -R . /usr/share/rootintootin/
	ln -s /usr/share/rootintootin/bin/rootintootin /usr/bin/rootintootin
	ln -s /usr/share/rootintootin/bin/rootintootin_build /usr/bin/rootintootin_build
	ln -s /usr/share/rootintootin/bin/rootintootin_gen /usr/bin/rootintootin_gen

install_dev: remove
	ln -s `pwd` /usr/share/rootintootin
	ln -s /usr/share/rootintootin/bin/rootintootin /usr/bin/rootintootin
	ln -s /usr/share/rootintootin/bin/rootintootin_build /usr/bin/rootintootin_build
	ln -s /usr/share/rootintootin/bin/rootintootin_gen /usr/bin/rootintootin_gen

