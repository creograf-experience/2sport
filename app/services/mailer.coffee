nodemailer = require 'nodemailer'
smtpTransport = require 'nodemailer-smtp-transport'
moduleModule = require '../models/module'
mongoose = require 'mongoose'
CmsModule = mongoose.model 'CmsModule'
_ = require 'lodash'

config = domain: process.env.SPORT_DOMAIN || 'localhost:3040'

module.exports =
  transporter: null
  mailOptions: {}

  reinit: ->
    CmsModule.findOne(name: 'main').exec (err, mainModule) =>
      if err || !mainModule || !mainModule.settings || !mainModule.settings.mailer
        return message: "Can't find the main module or its settings"
      settings = mainModule.settings.mailer
      @transporter = nodemailer.createTransport(
        smtpTransport
          host: settings.smtpServer
          auth:
            user: settings.user
            pass: settings.pass
      )

      @mailOptions =
        adminMail: mainModule.settings.adminMail
        managerMail: mainModule.settings.managerMail
        from: settings.from

  send: (options, done) ->
    unless @transporter
      return done(new Error "Can't find the mail transporter")
    if !options.to || !options.text
      return done(new Error "You need to specify receiver and text.")

    options ?= {}
    _.extend options, @mailOptions

    @transporter.sendMail options, done

  notifyAdmin: (message, subject) ->
    return if process.env.NODE_ENV == 'test'
    @send
      to: @mailOptions.adminMail
      text: message
      subject: subject || ''
    , (err, info) ->
      console.log err if err
      console.log info if info

  notifyManager: (message, subject) ->
    @send
      to: @mailOptions.managerMail
      text: message
      subject: subject || ''
    , (err, info) ->
      console.log err if err
      console.log info if info

  resetPassword: (user) ->
    console.log @mailOptions
    return if process.env.NODE_ENV == 'test'

    message = "Введите в приложении этот код:\n#{user.resetPassCode}"
    @send
      to: user.email
      text: message
      subject: "Сброс пароля на #{config.domain}" || ''
    , (err, info) ->
      console.log err if err
      console.log info if info
