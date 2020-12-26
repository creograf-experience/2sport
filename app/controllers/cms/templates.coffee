express = require 'express'
fs = require 'fs'
path = require 'path'
templatesRouter = express.Router()

templatesDir = path.join process.cwd(), 'views/templates'

templatesRouter.get '/?', (req, res) ->
  fs.readdir templatesDir, (err, files) ->
    return res.status(400).end() if err
    templates = files
    .filter((file) ->
      file.match /\.jade$/
    ).map (file) ->
      file.match(/^(.+)\.jade$/)[1]
    res.json templates

module.exports.router = templatesRouter
