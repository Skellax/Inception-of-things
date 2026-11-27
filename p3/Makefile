
all: install start

install:
	@sudo -A bash ./scripts/install.sh

start:
	@sudo -A bash ./scripts/start.sh

clean:
<<<<<<< HEAD
	@sudo -A ./scripts/clean.sh
=======
	@sudo -A bash ./scripts/clean.sh
	@sudo -A bash ./scripts/uninstall.sh
>>>>>>> origin/fabio

uninstall:
	@sudo -A bash ./scripts/uninstall.sh


help:
	@echo "Usage:"
	@echo "  make all       # Install and start"
	@echo "  make install   # Install dependencies"
	@echo "  make start     # Start services"
	@echo "  make clean     # Clean and uninstall"
	@echo "  make uninstall # Uninstall tools"
	@echo "  make help      # Show this help message"

.PHONY: all install start clean help uninstall

