_ = require 'lodash'

# this middleware if added to the whole app router,
# and some of the helpers are not needed everywhere.
# REFACTOR break it up into routes
module.exports = (req, res, next) ->
  # req.xhr tells if the request is async from a page.
  # It is passed into layout template here
  res.locals.xhr = req.xhr

  res.handleSuccess = (data) ->
    res.json data

  # return res.mongooseErrors(err) if err
  res.mongooseError = res.handleError = (err) ->
    messages = _.map(err.errors, 'message')
    if messages.length < 1 && err.err
      messages.push err.err

    if messages.length < 1 && err.message
      messages.push err.message

    res.status(400).json messages: messages

  res.handleData = (err, data) ->
    return res.mongooseError err if err

    res.json data

  req.logInAndSave = (user, next) ->
    {User} = require('../models')
    ip = req.headers['x-forwarded-for'] || req.connection.remoteAddress

    req.logIn user, (err) ->
      next(err)

      props =
        ipAddress: ip
        visitedAt: new Date()
      props.apnToken = req.body.apnToken if req.body.apnToken
      User.update(_id: user._id, props, ->)

  res.renderPageTemplate = (page, locals) ->
    templatesDir = 'templates/'
    if page.template
      res.render templatesDir + page.template, locals, (err, html) ->
        if err
          page.deleteTemplate (err) ->
            res.render templatesDir + 'simple', locals
        else
          res.end(html)
    else
      res.render templatesDir + 'simple', locals

  next()
