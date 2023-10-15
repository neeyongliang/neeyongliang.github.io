.PHONY: setup
setup:
	# docsearch related assets
	# cp node_modules/docsearch.js/dist/cdn/docsearch.min.css assets/css/docsearch.min.css
	cp node_modules/alpinejs/dist/cdn.min.js assets/javascript/alpine.js

.PHONY: server
server: setup
	hugo server --disableFastRender -F --ignoreCache -w --logLevel debug

.PHONY: build
build: setup
	# hugo --minify
	hugo
