mongoose = require 'mongoose'
{ObjectId} = mongoose.Types
{vasya} = require('./users')
moment = require 'moment'

module.exports = [{
  _id: new ObjectId()
  user: vasya._id
  name: 'Dima'
  surname: 'Dimin'
  slug: 'dima-dimin'
  email: 'dima@cyka.com'
  password: '123123123'
  passConfirm: '123123123'
}, {
  _id: new ObjectId()
  user: vasya._id
  name: 'Petya'
  surname: 'Petrov'
  slug: 'petya-petrov'
  email: 'petya@cyka.com'
  password: '123123123'
  passConfirm: '123123123'
}, {
  _id: new ObjectId()
  user: vasya._id
  name: 'Kolya'
  surname: 'Kasyakov'
  slug: 'kolya-kasyakov'
  email: 'kolya@cyka.com'
  password: '123123123'
  passConfirm: '123123123'
}]