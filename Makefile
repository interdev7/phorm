VERSION_annotations := $(shell grep '^version:' packages/phorm_annotations/pubspec.yaml | awk '{print $$2}')
VERSION_generator   := $(shell grep '^version:' packages/phorm_generator/pubspec.yaml | awk '{print $$2}')
VERSION_phorm       := $(shell grep '^version:' packages/phorm/pubspec.yaml | awk '{print $$2}')
VERSION_sqlite      := $(shell grep '^version:' packages/phorm_sqlite/pubspec.yaml | awk '{print $$2}')

.PHONY: tag

PKG := $(word 2,$(MAKECMDGOALS))

tag:
	@if [ -z "$(PKG)" ]; then echo "Error: Specify the package, for example: make tag annotations"; exit 1; fi
	$(eval TAG_NAME := $(PKG)-v$(VERSION_$(PKG)))
	@if [ -z "$(VERSION_$(PKG))" ]; then echo "Error: Package '$(PKG)' not found or has no version"; exit 1; fi
	
	@echo "Checking tag $(TAG_NAME)..."
	@if git rev-parse "$(TAG_NAME)" >/dev/null 2>&1; then \
		echo "Error: Tag '$(TAG_NAME)' already exists locally!"; \
		exit 1; \
	fi
	@if git ls-remote --tags origin "$(TAG_NAME)" | grep -q "$(TAG_NAME)"; then \
		echo "Error: Tag '$(TAG_NAME)' already exists in remote repository!"; \
		exit 1; \
	fi
	
	git tag $(TAG_NAME)
	git push origin $(TAG_NAME)

%:
	@:
