COFFEEC = coffee -b -c
JSSRC = $(shell find src -type f -name '*.coffee')
JS = $(JSSRC:src/%.coffee=lib/%.js)

all: js

js:: $(JS)

lib/%.js: src/%.coffee
	@mkdir -p $(@D)
	$(COFFEEC) -o $(@D) $<

watch: all
	@watchmedo shell-command -i '*.js' -R -c make

clean:
	rm -rf $(JS)
