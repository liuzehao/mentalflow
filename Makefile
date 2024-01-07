# Makefile for managing Hugo site

# Define the default target
.DEFAULT_GOAL := help

# Variables
POST_TITLE := "draft"

# Targets and rules
new:
	ps aux | grep -v Visual | grep -v color | grep -v 'grep' | grep -v Xmind| grep -v 'eiis' | grep Electron.app || (echo "Executing eiis" && eiis)
	hugo new content/posts/$(POST_TITLE).md

# Help target
help:
	@echo "Available targets:"
	@echo "  new           - Create a new draft post"
	@echo "  help          - Show this help message"

dev:
	hugo server -e production