mongoose = require 'mongoose'
{ObjectId} = mongoose.Types
{vasya, petya, misha, kolya} = require('./users')
track = require('./track')
moment = require 'moment'

module.exports = [{
  _id: new ObjectId()
  user: petya._id
  type: 'running'
  isActive: false
  updatedAt: moment().subtract(1, 'day').toDate()
  meanSpeed: 50
  maxSpeed: 60
  distance: 2956.840236969609
  time: 92904
  track: track
}, {
  _id: new ObjectId()
  user: vasya._id
  type: 'running'
  isActive: false
  updatedAt: moment().subtract(1, 'day').toDate()
  meanSpeed: 50
  maxSpeed: 60
  distance: 5000
  time: 20 * 60 * 60 * 1000
  track: track
}, {
  _id: new ObjectId()
  user: vasya._id
  type: 'running'
  isActive: false
  updatedAt: moment().subtract(1, 'day').toDate()
  meanSpeed: 60
  maxSpeed: 70
  distance: 6000
  time: 30 * 60 * 60 * 1000
}, {
  _id: new ObjectId()
  user: vasya._id
  type: 'running'
  isActive: true
  updatedAt: moment().subtract(1, 'day').toDate()
  meanSpeed: 60
  maxSpeed: 70
  distance: 6000
  time: 30 * 60 * 60 * 1000
  currentLocation: [61.322859, 55.199522]
}, {
  _id: new ObjectId()
  user: misha._id
  type: 'running'
  isActive: true
  updatedAt: moment().subtract(1, 'day').toDate()
  meanSpeed: 60
  maxSpeed: 70
  distance: 6000
  time: 30 * 60 * 60 * 1000
  currentLocation: [61.321609, 55.199657]
}, {
  _id: new ObjectId()
  user: petya._id
  type: 'running'
  isActive: true
  updatedAt: moment().subtract(1, 'day').toDate()
  meanSpeed: 60
  maxSpeed: 70
  distance: 6000
  time: 30 * 60 * 60 * 1000
  currentLocation: [61.337961, 55.197134]
}]
# , {
#   _id: new ObjectId()
#   user: kolya._id
#   type: 'running'
#   isActive: true
#   updatedAt: moment().subtract(1, 'day').toDate()
#   meanSpeed: 60
#   maxSpeed: 70
#   distance: 6000
#   time: 30 * 60 * 60 * 1000
#   currentLocation: [55.196570, 61.337678]
# }]
