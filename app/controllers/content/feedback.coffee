feedbackRouter = require('express').Router()
Feedback = require('mongoose').model('Feedback')
mailer = require '../../services/mailer'

feedbackRouter.post '/api/feedback/?', (req, res) ->
  feedback = new Feedback
    name: req.body.name
    body: req.body.body
    email: req.body.email
    phone: req.body.phone

  if req.files && req.files.photo && req.files.photo.size > 0
    feedback.attach 'photo', req.files.photo, (err) ->
      return res.status(400).end() if err

      feedback.save (err) ->
        return res.status(400).json err if err
        res.end()
  else
    feedback.save (err) ->
      return res.status(400).json err if err

      res.end()

feedbackRouter.get '/leavefeedback', (req, res) ->
  res.render 'partials/feedbackForm', title: 'Оставить отзыв'

feedbackRouter.get '/feedback', (req, res) ->
  Feedback.find(visible: true).exec (err, feedbacks) ->
    unless err
      res.render 'partials/feedback', feedbacks: feedbacks, title: 'Отзывы'
    else
      res.status(400).render '404'

module.exports = feedbackRouter
