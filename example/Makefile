all: build/Iceland.xml build/Iceland.topojson

build:
	mkdir -p $@

.PHONY: clean
clean:
	rm -rf build

JSON=python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout)'

build/Iceland.mml: Iceland.yaml | build
	cat $^ | $(JSON) > $@

build/land.mss: land.mss
	cp $^ $@

build/Iceland.xml: build/Iceland.mml build/land.mss | build
	$(shell npm bin)/carto $< > $@
	rm -f $^

URI=https://gist.github.com/zjonsson/4686541/raw/flakar.json
build/Iceland.topojson:
	curl -L -o $@ $(URI)
