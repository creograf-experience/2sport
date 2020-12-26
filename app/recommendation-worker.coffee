_ = require 'lodash'
mongoose = require('mongoose')
recommend = require('./services/recommend')

runJob = ->
  recommend()
  .then (users) ->
    console.log "spammed #{_.compact(users).length} users"
  .catch(console.error)

interval = 36e5

mongoose.connect 'mongodb://localhost/2sport', (err) ->
  throw err if err

  setInterval runJob, interval
  runJob()
