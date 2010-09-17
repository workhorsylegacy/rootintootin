
all:
	@echo "'sudo make install' - Installs Rootin Tootin for normal web development."
	@echo "'sudo make dev'     - Installs Rootin Tootin for development on the framework itself."
	@echo "'sudo make remove'  - Removes Rootin Tootin from the system."

remove:
	rm -rf -f /usr/share/doc/rootintootin/
	rm -f /usr/bin/rootintootin
	rm -f /usr/bin/rootintootin_run
	rm -f /usr/bin/rootintootin_gen
	rm -f /usr/bin/rootintootin_deploy
	rm -f -rf /usr/share/rootintootin/
	rm -f /usr/share/rootintootin

install: remove
	cp -R . /usr/share/rootintootin/
	#robodoc --src src/ --doc istall_doc/ --multidoc --index --html --tabsize 4 --documenttitle "WIP Rootin Tootin 0.7 API"
	mkdir /usr/share/doc/rootintootin/
	#mv istall_doc/ /usr/share/doc/rootintootin/html/
	cp README /usr/share/doc/rootintootin/README
	cp LICENSE /usr/share/doc/rootintootin/LICENSE
	cp COPYRIGHT /usr/share/doc/rootintootin/COPYRIGHT
	cp ChangeLog /usr/share/doc/rootintootin/ChangeLog
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

