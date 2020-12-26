fs = require('fs')
path = require('path')
pagesRouter = require('express').Router()
{Page, Workout} = require('../../models')
phantom = require('phantom')

imagesDir = path.resolve(__dirname, '../../../public/images/workouts')

renderWorkout = (id, location) ->
  _ph = _page = null

  phantom.create().then (ph) ->
    _ph = ph
    ph.createPage()

  .then (page) ->
    _page = page
    page.open("http://localhost:3040/workouts/#{id}?nolayout=true")

  .then (status) ->
    promise = _page.render(location)

    _ph.exit()

    return promise

renderWorkoutVk = (id, location) ->
  _ph = _page = null

  phantom.create().then (ph) ->
    _ph = ph
    ph.createPage()

  .then (page) ->
    _page = page
    page.open("http://localhost:3040/workouts/#{id}?vk=true")

  .then (status) ->
    promise = _page.render(location)

    _ph.exit()

    return promise

pagesRouter.get '/workouts/:id', (req, res) ->
  if !!req.query.vk
    template = 'workouts/show-no-layout-vk'
  else if !!req.query.nolayout
    template = 'workouts/show-no-layout'
  else
    template = 'workouts/show'
  Workout.findById(req.params.id)
  .then (workout) ->
    res.render template, {
      workout: workout
    }
  .catch(res.handleError)

pagesRouter.get '/workouts/:id/preview.png', (req, res) ->
  location = path.join(imagesDir, "#{req.params.id}.png")
  sendImage = ->
    fs.readFile location, (err, file) ->
      return res.status(400).end() if err

      base64Image = new Buffer(file, 'binary').toString('base64')
      image = "data:image/gif;base64,#{base64Image}"
      #image = "<img src='data:image/gif;base64,#{base64Image}' />"

      #res.set('Content-Type', 'image/gif;base64')
      res.send image

  #fs.exists location, (exists) ->
    #return sendImage() if exists

  renderWorkout(req.params.id, location)
  .then(sendImage)

  .catch(res.mongooseError)

pagesRouter.get '/workouts/vk/:id', (req, res) ->
  location = path.join(imagesDir, "#{req.params.id}.png")
  sendImage = ->
    fs.readFile location, (err, file) ->
      return res.status(400).end() if err

      #base64Image = new Buffer(file, 'binary').toString('base64')
      #image = "<img src='data:image/gif;base64,#{base64Image}' />"

      res.set('Content-Type', 'image/gif;base64')
      res.send file

  #fs.exists location, (exists) ->
    #return sendImage() if exists

  renderWorkoutVk(req.params.id, location)
  .then(sendImage)

  .catch(res.mongooseError)

module.exports = pagesRouter
