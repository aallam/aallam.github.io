all: install serve

serve: 
	bundle exec jekyll serve --config _config.yml

install:
	bundle install
