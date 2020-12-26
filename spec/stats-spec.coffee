_ = require 'lodash'
helper = require './spec-helper'

describe 'UserStat', ->
  {User, Workout, UserStat} = require '../app/models'

  users = require './fixtures/users'
  workouts = require './fixtures/stat-workouts'

  seed = [
    (next) -> Workout.collection.ensureIndex('clusters.location': '2dsphere', next)
    (next) -> Workout.collection.ensureIndex(currentLocation: '2dsphere', next)
    (next) -> User.collection.insert(_.values(users), next)
    (next) -> Workout.collection.insert(workouts, next)
    (next) ->
      Promise.all(_.values(users).map (user) ->
        UserStat.updateUserStats(user._id)
      ).then(-> next())
  ]

  beforeEach helper.prepareDb(seed)

  it 'sets up db connection', helper.connectDb

  describe 'updateUserStats', ->
    it 'generates a list of user\'s locations from workouts', (done) ->
      UserStat.updateUserStats(users.vasya._id)
      .then ->
        UserStat.findOne(user: users.vasya._id)
      .then (us) ->
        expect(us).toBeTruthy()
        return done() unless us
        expect(us.clusters.length).toBe 4
        done()
      .catch(done)

  describe 'findNeighbors', ->
    it 'gets a lists of users in 1km range from locs', (done) ->
      UserStat.findOne(user: users.vasya._id).populate('user')
      .then (userStat) ->
        UserStat.findNeighbors(userStat)
      .then (stats) ->
        misha = _.find stats, (stat) ->
          stat.user._id.toString() == users.misha._id.toString()
        expect(misha).toBeTruthy()
        done()
      .catch(done)

  describe 'neareastNeighbor', ->
    it 'gets a closest matching person', (done) ->
      UserStat.nearestNeighbor(users.vasya._id)
      .then (nn) ->
        expect(Math.round(nn.distance)).toBe 52

        UserStat.findOne(user: users.vasya._id)

      .then (us) ->
        expect(us.lastRecommendationAt).toBeDefined()

        done()
      .catch((err) ->
        console.log err
        expect(err).toBeFalsy()
        done())

  it 'closes db connection', helper.disconnectDb
