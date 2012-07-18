test:
	./node_modules/.bin/mocha --compilers coffee:coffee-script --require should

.PHONY: test