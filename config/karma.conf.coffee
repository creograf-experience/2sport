module.exports = (config) ->
  config.set
    basePath: '..'
    frameworks: ['jasmine']
    files: [
      'public/js/dist/vendor-test.js'
      'app/client/**/*.coffee'
      'spec-client/*-spec.coffee'
    ]
    exclude: [
      'app/client/public/**/*.coffee'
    ]
    preprocessors:
      '**/*.coffee': ['coffee']
    reporters: ['progress']
    port: 9876
    colors: true
    logLevel: config.LOG_INFO
    autoWatch: false
    browsers: ['PhantomJS']
    singleRun: true
