.PHONY: build install

build:
	flutter build apk --dart-define-from-file=.env

install:
	flutter install