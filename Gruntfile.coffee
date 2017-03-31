module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON "package.json"
    coffeelint:
      app: [
        "*.coffee"
        "devices/**/*.coffee"
        "actions/**/*.coffee"
      ]
      options:
        no_trailing_whitespace:
          level: "ignore"
        max_line_length:
          value: 100
        indentation:
          value: 2
          level: "error"
        no_unnecessary_fat_arrows:
          level: 'ignore'

  grunt.loadNpmTasks "grunt-coffeelint"


  # Default task(s).
  grunt.registerTask "default", ["coffeelint"]
  grunt.registerTask "test", ["coffeelint"]