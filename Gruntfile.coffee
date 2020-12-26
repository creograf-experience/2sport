module.exports = (grunt) ->
  grunt.file.defaultEncoding = 'utf8'
  require('time-grunt')(grunt)
  require('jit-grunt')(grunt,
    jasmine_node: 'grunt-jasmine-node-new'
    nggettext_extract: 'grunt-angular-gettext'
    nggettext_compile: 'grunt-angular-gettext')

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    concurrent:
      build:
        tasks: ['coffee', 'jade', 'bower']
      buildProd:
        tasks: ['coffee', 'jade', 'bower']
      dev:
        tasks: ['nodemon', 'watch', 'browserify:watch']
        options:
          logConcurrentOutput: true

    shell:
      seed:
        command: 'coffee db/seed.coffee'

    browserify:
      build:
        src: 'app/client/public/index.js'
        dest: 'public/js/dist/public.js'
        options:
          transform: [['babelify', {presets: ['es2015']}]]
          detectGlobals: true
      watch:
        src: 'app/client/public/index.js'
        dest: 'public/js/dist/public.js'
        options:
          transform: [['babelify', {presets: ['es2015']}]]
          watch: true
          keepAlive: true
          livereload: false
          detectGlobals: true

    bower_concat:
      cms:
        dest: 'public/js/dist/vendor-cms.js'
        exclude: ['jquery-ui', 'page', 'angular-mocks']
        dependencies:
          'angular': ['jquery', 'jquery-ui-sortable']
          'angular-route': 'angular'
          'angular-resource': 'angular'
          'angular-bootstrap': 'angular'
          'angular-ui-tinymce': ['angular', 'tinymce']
        callback: (mainFiles, component) ->
          mainFiles.map (filepath) ->
            min = filepath.replace(/\.js$/, '.min.js')
            return filepath unless grunt.file.exists(min)

            hasMap = false
            minNoMap = grunt.file.read(min).split('\n')
            .filter((line, i) ->
              hasMap = true
              !line.match /^\/\/\# sourceMappingURL.*?map$/
            ).join('\n')
            grunt.file.write min, minNoMap if hasMap
            return min

    coffee:
      compile:
        options:
          join: true
        files:
          'public/js/dist/cms.js':
            [
              'app/client/services.coffee'
              'app/client/directives.coffee'
              'app/client/filters.coffee'
              'app/client/controllers/application.coffee'
              'app/client/controllers/*.coffee'
              'app/client/app.coffee'
            ]

    jade:
      cms:
        options:
          doctype: 'html'
        files: [
          cwd: 'views/cms'
          expand: true
          src: '**/*.jade'
          dest: 'public/angular-templates'
          ext: '.html'
        ]

    ngAnnotate:
      options:
        singleQuotes: true
      app:
        files:
          'public/js/dist/cms.js': ['public/js/dist/cms.js']
          'public/js/dist/public.js': ['public/js/dist/public.js']

    uglify:
      vendor:
        options:
          mangle: true
          compress: true
        files:
          'bower_components/angular-ui-tinymce/src/tinymce.min.js':
            'bower_components/angular-ui-tinymce/src/tinymce.js'
          'bower_components/page/page.min.js': 'bower_components/page/page.js'
      js:
        options:
          mangle: true
          compress: true
        files:
          'public/js/dist/cms.min.js': 'public/js/dist/cms.js'

    nodemon:
      dev:
        script: 'app/server.coffee'
        options:
          env:
            'PRERENDER_SERVICE_URL': 'http://127.0.0.1:1337'
            'NODE_ENV': 'development'
          callback: (nodemon) ->
            nodemon.on 'log', (event) ->
              console.log(event.colour)
          cwd: __dirname
          ignore: ['app/client/']
          ext: 'js,coffee'
          watch: ['app']
          delay: 1000
      prod:
        script: 'app/server.coffee'
        options:
          env:
            'NODE_ENV': 'production'
          callback: (nodemon) ->
            nodemon.on 'log', (event) ->
              console.log(event.colour)
          cwd: __dirname
          ignore: ['app/client/**']
          ext: 'js,coffee'
          watch: ['app']
          delay: 1000

    jasmine_node:
      options:
        forceExit: true
        coffee: true
        includeStackTrace: true
      all: ['spec/']

    watch:
      bower:
        files: './bower_components/*'
        tasks: ['bower']
      coffee:
        files: [
          'app/client/**/*.coffee'
          '!app/client/public/**/*.coffee']
        tasks: ['newer:coffee']
      jade:
        files: 'views/cms/**/*.jade'
        tasks: ['newer:jade']
      docs:
        files: 'docs/*.md'
        tasks: ['aglio']
      test:
        files: [
          'app/**/*.coffee'
          '!app/client/**/*.coffee'
          'spec/*'
        ]
        tasks: ['test']

    aglio:
      docs:
        files:
          "public/docs/index.html": ["docs/*.md"]

    notify:
      test:
        options:
          title: 'Tests are green!'
          message: 'Roses are red, violets are blue...'

    notify_hooks:
      options:
        enabled: true
        duration: 10

  grunt.registerTask 'copyBootstrap', ->
    srcPrefix = 'bower_components/bootstrap/dist/'
    destPrefix = 'public/'
    files =
      'css/bootstrap.min.css': 'css/bootstrap.min.css'
      'fonts/glyphicons-halflings-regular.ttf':
        'fonts/glyphicons-halflings-regular.ttf'
      'fonts/glyphicons-halflings-regular.woff':
        'fonts/glyphicons-halflings-regular.woff'
      'fonts/glyphicons-halflings-regular.woff2':
        'fonts/glyphicons-halflings-regular.woff2'

    Object.keys(files).forEach (dest) ->
      src = srcPrefix + files[dest]
      if grunt.file.exists src
        console.log src
        grunt.file.copy(src, destPrefix + dest)

  grunt.registerTask 'test', ['jasmine_node', 'notify:test']
  grunt.registerTask 'db:seed', 'shell:seed'
  grunt.registerTask 'bower', ['copyBootstrap', 'bower_concat']
  grunt.registerTask 'bower:production', ['copyBootstrap', 'bower_concat:cms']
  grunt.registerTask 'build:dev', ['jade', 'coffee', 'bower', 'browserify:build']
  grunt.registerTask 'default', ['concurrent:dev']
  grunt.registerTask 'server:bench', ['nodemon:prod']
  grunt.registerTask 'build:test', ['jade', 'coffee', 'bower:production', 'ngAnnotate', 'uglify:js']
  grunt.registerTask 'build:production', ['jade', 'coffee', 'bower:production', 'browserify:build', 'ngAnnotate', 'uglify:js']
