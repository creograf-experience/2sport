express = require 'express'
fs = require 'fs-extra'
path = require 'path'
fileManager = require '../../services/file-manager'
filesRouter = express.Router()

filesRouter.get '/dirtree', (req, res) ->
  fileManager.getDirTree (err, tree) ->
    res.json tree

filesRouter.get '/:path(*)?', (req, res) ->
  fileManager.listDir req.params.path, (err, tree) ->
    res.json tree

# put for files upload
filesRouter.put '/:path(*)?', (req, res) ->
  file = req.files.file
  fileManager.uploadFiles file, req.params.path
  , (err) ->
    return res.status(400).end() if err

    res.end()

# post for mkdir
filesRouter.post '/:path(*)?', (req, res) ->
  fileManager.createDir req.params.path, (err) ->
    return res.status(400).end() if err

    res.json message: 'ok'

filesRouter.delete '/:path(*)?', (req, res) ->
  fileManager.removeDir req.params.path, (err) ->
    return res.status(400).end() if err

    res.json message: 'ok'

module.exports.router = filesRouter
