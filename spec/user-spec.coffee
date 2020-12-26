require '../app/models'
mongoose = require 'mongoose'
moment = require 'moment'
_ = require 'lodash'
helper = require './spec-helper'

describe 'User', ->
  User = mongoose.model 'User'
  Workout = mongoose.model 'Workout'

  users = require './fixtures/users'
  workouts = require './fixtures/workouts'

  seed = [
    (next) -> Workout.collection.ensureIndex(currentLocation: '2dsphere', next)
    (next) -> User.collection.insert(_.values(users), next)
    (next) -> Workout.collection.insert(workouts, next)
  ]

  beforeEach helper.prepareDb(seed)

  it 'sets up db connection', helper.connectDb

  describe 'updateStats', ->
  	it 'sets stats.type to mean values of workouts from last month', (done) ->
      User.updateStats users.vasya._id, (err, n) ->
        User.findById users.vasya._id, (err, vasya) ->
          expect(vasya.stats.running.meanSpeed).toBe(55)
          expect(vasya.stats.cycling).toBeDefined()

          done()

  describe 'Workout.nearMe', ->
    it 'finds workous with users in 1000 m', (done) ->
      Workout.nearMe {userId: users.vasya, radius: 1000}, (err, wouts) ->
        expect(err).toBeFalsy()
        return done() if err

        expect(wouts[0]).toBeDefined()
        return done() unless wouts[0]

        expect(wouts[0].user.name).toBe 'Petya'

        done()

  it 'closes db connection', helper.disconnectDb
