VERSION_ANNOTATIONS := $(shell grep '^version:' packages/phorm_annotations/pubspec.yaml | awk '{print $$2}')
VERSION_GENERATOR := $(shell grep '^version:' packages/phorm_generator/pubspec.yaml | awk '{print $$2}')

tag:
	git tag v$(VERSION_ANNOTATIONS)
	git push origin v$(VERSION_ANNOTATIONS)
	git tag v$(VERSION_GENERATOR)
	git push origin v$(VERSION_GENERATOR)