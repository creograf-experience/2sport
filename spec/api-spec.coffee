require '../app/models'
mongoose = require 'mongoose'
_ = require 'lodash'
helper = require './spec-helper'

app = require '../app/server'
request = require('supertest')

cookies = null

describe 'API', ->
  User = mongoose.model 'User'
  Workout = mongoose.model 'Workout'
  Chat = mongoose.model 'Chat'

  users = require('./fixtures/users.coffee')
  usersv = require('./fixtures/usersv.coffee')
  workouts = require('./fixtures/workouts.coffee')
  chats = require('./fixtures/chats.coffee')
  seed = [
    (next) -> Workout.collection.ensureIndex(currentLocation: '2dsphere', next)
    (next) -> User.collection.insert(_.values(_.omit(users, 'vasya')), next)
    (next) -> Workout.collection.insert(workouts, next)
    (next) -> Chat.collection.insert(chats, next)
  ]

  beforeEach (done) ->
    helper.prepareDb(seed) (err) ->
      return done() unless mongoose.connection.readyState

      request(app)
      .post('/api/auth/register')
      .send(users.vasya)
      .end (err, res) ->
        cookies = res.headers['set-cookie']
        done()

  it 'sets up db connection', helper.connectDb

  describe 'POST /auth/registration', ->
    it 'registers a user1', (done) ->
      request(app)
      .post('/api/auth/register')
      .send(
        name: 'Exampl Examplovich'
        email: 'example@example.com'
        password: '123456'
        passConfirm: '123456')
      .end((err,res, body) ->
        expect(res.body.email).toBe('example@example.com')
        done())

  describe 'POST /auth/login', ->
    it 'Авторизация прошла успешно', (done) ->
      request(app)
      .post('/api/auth/register')
      .send(
        name: 'Exampl Examplovich'
        email: 'example@example.com'
        password: '123456'
        passConfirm: '123456')
      .expect(200)
      .end((err, res, body) ->
        request(app)
        .post('/api/auth/login')
        .send(
          email: 'example@example.com'
          password: '123456')
        .expect(200)
        .end((err, res, body) ->
          expect(res.headers['set-cookie']).toBeDefined()
          done()))

  describe 'POST /auth/login', ->
    it 'Неверные логин или пароль', (done) ->
      request(app)
      .post('/api/auth/register')
      .send(
        name: 'Exampl Examplovich'
        email: 'example@example.com'
        password: '123456'
        passConfirm: '123456')
      .expect(200)
      .end((err, res, body) ->
        request(app)
        .post('/api/auth/login')
        .send(
          email: 'example@example.com'
          password: '12')
        .expect(401)
        .end((err, res, body) ->
          expect(res.headers['set-cookie']).toBeDefined()
          done()))

  describe 'GET /api/user', ->
    it 'информация о юзере', (done) ->

      request(app)
        .get('/api/user')
        .set('Cookie', cookies)
        .expect(200)
        .end((err, res, body) ->
          expect(res.statusCode).toBe(200)
          done())

  describe 'PUT /api/user', ->
    it 'Возвращает обновленного пользователя', (done) ->

      request(app)
        .put('/api/user')
        .set('Cookie', cookies)
        .send(
          phone:'999999999'
          gender:'m'
          contactEmail:'Cucu@cucu.cu'
          suggestMale: true
          suggestFemale: true
          ageRange: '18-25'
          dob: '1992-03-05T00:00:00.000Z'
          city: 'Челябинск'
          )
        .expect(200)
        .end((err, res, body) ->
          done())

  describe '/api/workouts', ->
    it 'Сохраненные тренировки', (done) ->
      request(app)
      .get('/api/workouts')
      .set('Cookie', cookies)
      .end((err, res, body) ->
          expect(res.statusCode).toBe(200)
          done())

  describe 'put/api/workouts', ->
    it 'Изменение сохраненной тренировки', (done) ->
      request(app)
      .put("/api/workouts/#{workouts[2]._id}")
      .set('Cookie', cookies)
      .send(currentLocation: [61.322859, 55.199523])
      .expect(200)
      .end((err, res) ->
        expect(res.body.constructor.name).toBe('Array')
        expect(res.body[0].user.name).toBe('Vasya')
        request(app)
        .get("/api/workouts/#{workouts[2]._id}")
        .end((err, res) ->
          expect(res.statusCode).toBe(200)
          expect(res.body.currentLocation[1]).toBe(55.199523)
          done()))

  describe '/api/workouts', ->
    it 'Создание тренировки', (done) ->
      request(app)
      .post('/api/workouts')
      .set('Cookie', cookies)
      .expect(200)
      .end((err, res, body) ->
          done())

  describe '/api/workouts', ->
    it 'Изменение и сохранение тренировки', (done) ->
      request(app)
      .put("/api/workouts/#{workouts[1]._id}")
      .set('Cookie', cookies)
      .send(
        track: [[1, 5, 9],[1, 8, 11]]
        isActive: false)
      .expect(200)
      .end((err, res, body) ->
        request(app)
        .get("/api/workouts/#{workouts[1]._id}")
        .expect(200)
        .end(done))

  describe 'POST /api/workouts/:id/cuttrack', ->
    it 'cuts workouts track', (done) ->
      request(app)
      .post("/api/workouts/#{workouts[0]._id}/cuttrack")
      .set('Cookie', cookies)
      .send(
        start: 1
        end: 5)
      .end((err, res) ->
        expect(res.statusCode).toBe(200)
        return done() unless res.statusCode == 200

        request(app)
        .get("/api/workouts/#{workouts[0]._id}")
        .end((err, res) ->
          expect(res.body.track.length).toBe(4)
          done()))

  describe '/api/users', ->
    it 'Поучение списка рекамендованных пользователей', (done) ->
      request(app)
      .post('/api/users')
      .set('Cookie', cookies)
      .end((err, res) ->
        expect(res.statusCode).toBe(200)
        done())

  describe '/api/users', ->
    it 'Получения информации о рекомендованном пользователе', (done) ->
      request(app)
      .get("/api/users/#{users.vasya._id}")
      .set('Cookie', cookies)
      .end((err, res, body) ->
          expect(res.statusCode).toBe(200)
          done())

  describe '/api/usersv/#usersv', ->
    it 'Получения списка чатов ', (done) ->
      request(app)
      .post('/api/chats/start')
      .set('Cookie', cookies)
      .send(
        receiverId: users.petya._id
        message: 'привет')
      .end((err, res, body) ->
          expect(res.statusCode).toBe(200)
          done())

  describe 'GET /api/chats/lastmessages', ->
    it 'receives a chat with 20 last messages', (done) ->
      request(app)
      .get("/api/chats/lastmessages?chatId=#{chats[0]._id}")
      .set('Cookie', cookies)
      .end((err, res) ->
        expect(res.statusCode).toBe(200)
        expect(res.body.messages[0].body).toBe('привет!!')
        done())

  it 'closes db connection', helper.disconnectDb
