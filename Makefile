all: build/style.css

build:
	mkdir -p $@

build/style.css: frontend/style.scss | build
	sass $^ $@
