process.env['NODE_ENV'] = 'test'
mongoose = require 'mongoose'
async = require 'async'
request = require('request').defaults(jar: true)

port = 7654

class Requester
  buildUrl: (path) ->
    "http://localhost:#{port}#{path}"

  get: (path, callback) ->
    request @buildUrl(path), callback

  post: (path, data, callback) ->
    request.post @buildUrl(path), form: data, callback

  put: (path, body, callback) ->
    request
      method: 'PUT'
      url: @buildUrl(path)
      json: body,
      callback

  delete: (path, callback) ->
    request.del @buildUrl(path), callback

module.exports =
  connectDb: (done) ->
    mongoose.connect 'mongodb://localhost/vitalcms_test'
    mongoose.connection.on "error", (err) -> console.log err
    mongoose.connection.once "open", done

  disconnectDb: (done) ->
    mongoose.connection.close done

  dropDb: (done) ->
    return done() unless mongoose.connection.readyState
    async.each Object.keys(mongoose.connection.collections),
    ((name, next) ->
      collection = mongoose.connection.collections[name]
      collection.drop next), done

  seedDb: (done) ->
    -> async.series seed, done

  prepareDb: (seed) ->
    (done) ->
      return done() unless mongoose.connection.readyState
      async.each Object.keys(mongoose.connection.collections),
      ((name, next) ->
        collection = mongoose.connection.collections[name]
        collection.drop next
      ), ->
        async.series seed, done

  withServer: (callback) ->
    jasmine.asyncSpecWait()

    app = require("../app/server.coffee")

    server = app.listen port

    stopServer = ->
      server.close()
      jasmine.asyncSpecDone()

    callback new Requester, stopServer
