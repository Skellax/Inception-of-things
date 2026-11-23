
all: install start

install:
	@sudo -A ./scripts/install.sh

start:
	@sudo -A ./scripts/start.sh

clean:
	@sudo -A ./scripts/clean.sh
	@sudo -A ./scripts/uninstall.sh

uninstall:
	@sudo -A ./scripts/uninstall.sh


help:
	@echo "Usage:"
	@echo "  make all       # Install and start"
	@echo "  make install   # Install dependencies"
	@echo "  make start     # Start services"
	@echo "  make clean     # Clean and uninstall"
	@echo "  make uninstall # Uninstall tools"
	@echo "  make help      # Show this help message"

.PHONY: all install start clean help uninstall

