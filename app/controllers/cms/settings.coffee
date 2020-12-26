express = require 'express'
mongoose = require('mongoose')
CmsModule = mongoose.model 'CmsModule'
mailer = require '../../services/mailer'
settingsRouter = express.Router()

settingsRouter.get '/:module', (req, res) ->
  CmsModule.findOne(name: req.params.module).exec (err, cmsModule) ->

    res.json cmsModule.settings

settingsRouter.put '/:module', (req, res) ->
  CmsModule.update({name: req.params.module}, {$set: settings: req.body}).exec (err) ->
    return res.status(400).end() if err
    mailer.reinit()

    res.json message: 'ok'

mailTest = (req, res) ->
  mailer.send
    to: 'sosloow@gmail.com'
    text: req.body.message
  , (err, info) ->
    return res.status(400).end() if err

    res.json info

module.exports =
  router: settingsRouter
  mailTest: mailTest
