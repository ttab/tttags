fs = require 'fs'
{spawn,exec} = require "child_process"

task 'dist', 'build javascripts and styles for distribution', (options) ->
	console.log 'Building...'
	exec 'coffee -o . -c src/*.coffee', (err, msg) ->
			throw err if err
			console.log msg
	exec 'lessc src/*.less tttags.css', (err, msg) ->
			throw err if err
			console.log msg
	
