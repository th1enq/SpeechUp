.PHONY: build install run clean

run:
	flutter run --dart-define-from-file=.env

build:
	flutter build apk --dart-define-from-file=.env

install:
	flutter install

clean:
	flutter clean