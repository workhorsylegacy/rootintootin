

.PHONY: all test dev install remove

all:
	@echo "'sudo make install'  - Install into system"
	@echo "'sudo make remove'   - Remove from system"
	@echo "'make test'          - Run test suite"
	@echo "'make dev'           - Install into the system with links to current dir"

test:
	python makefile.py 'test'

dev: makefile.py
	python makefile.py 'dev'

install: makefile.py
	python makefile.py 'install'

remove: makefile.py
	python makefile.py 'remove'

