require '../models'
mongoose = require 'mongoose'
express = require 'express'
_ = require 'lodash'

mongooseError = require './error-handler'

class Resource
  # model name must be capitalized
  # options:
  ## recycleble - adds recycle and restore methods,
  # uses recycled field in the model which must be presented.
  ## fileAttached - adds functionality to every method
  # for handling files. Value is the name of db field
  constructor: (@name, options) ->
    @options =
      recyclable: false
      fileAttached: false
      multipleFiles: false

    if options && (typeof options == 'object')
      _.each options, (value, key) =>
        return if (key == 'multipleFiles' && !options['fileAttached'])

        @options[key] = value

    @Model = mongoose.model(@name)
    @router = express.Router()
    @noQuery = (query) -> query

  mount: =>
    if @options.recyclable
      @router.put "/:id/recycle", @recyclePrivate
      @router.put "/:id/restore", @restorePrivate

    @router.get "/?", @listPrivate
    @router.post "/?", @createPrivate
    @router.get "/:id", @showPrivate
    @router.put "/:id", @updatePrivate
    @router.delete "/:id", @destroyPrivate

    return @router

  listPrivate: (req, res) =>
    if @options.recyclable
      req.query.recycled ?= false

    params = _.omit req.query, ['sort', 'select', 'pageNumber', 'pageLimit']

    query = @listQuery || @noQuery
    transform = @noQuery || @listTransform

    query = query(mongoose.model(@name).find(params))
    if req.query.pageNumber
      pageNumber = +req.query.pageLimit
      pageLimit = +req.query.pageLimit || 25
      query = query.skip(pageLimit * (pageNumber - 1)).limit(pageLimit)

    if req.query.select
      query = query.select(req.query.select)

    query.lean().exec (err, instances) ->
      return res.status(400).json mongooseError(err) if err
      res.json transform(instances)

  createPrivate: (req, res) =>
    attributes = @creatingInstance || req.body
    instance = new @Model(attributes)
    filename = @options.fileAttached

    ((next) =>
      return next() unless req.files[filename]
      instance.attach filename,
        req.files[filename],
        next
    ) (err) ->
      return req.status(400).json(err) if err
      instance.save (err, instance) ->
        return res.status(400).json mongooseError(err) if err

        res.json instance

  showPrivate: (req, res) =>
    query = @showQuery || @noQuery
    params = _.extend _id: req.params.id, _.clone(req.query)
    query(mongoose.model(@name).findOne(params))
    .exec (err, instance) ->
      return res.status(400).json mongooseError(err) if err
      return res.json instance.toObject(virtuals: true) if instance

      res.status(404).end()

  updatePrivate: (req, res) =>
    attributes = @updatingInstance || req.body

    mongoose.model(@name).findById(req.params.id)
    .exec (err, instance) =>
      return res.status(404).end() unless instance
      unless _.isObject(attributes)
        return res.status(400).json message: 'Invalid instance'
      _.extend instance, _.omit(attributes, '_id', @options['fileAttached'])

      instance.save (err, updated) ->
        return res.status(400).json err if err
        res.json updated

  destroyPrivate: (req, res) =>
    mongoose.model(@name).findById(req.params.id)
    .exec (err, instance) ->
      unless instance
        return res.status(404).end()
      instance.remove (err) ->
        res.json mongooseError(err) if err

        res.end()

  recyclePrivate:  (req, res) =>
    mongoose.model(@name).findById(req.params.id)
    .exec (err, instance) ->
      return res.status(400).json mongooseError(err) if err
      if !instance
        return res.status(404).end()
      instance.recycled = true
      instance.save (err, saved) ->
        return res.status(400).json mongooseError(err) if err
        res.end()

  restorePrivate:  (req, res) =>
    mongoose.model(@name).findById(req.params.id)
    .exec (err, instance) ->
      return res.status(400).json mongooseError(err) if err
      if !instance
        return res.status(404).end()

      instance.recycled = false
      instance.save (err, saved) ->
        return res.status(400).json err if err
        res.end()

  list: (query, transform) =>
    @listQuery = query
    @listTransform = transform
    return this

  show: (query) =>
    @showQuery = query
    return this

  destroy: (query) =>
    @destroyQuery = query
    return this

  create: (returnQuery, attributes) =>
    @creatingInstance = attributes
    @createdQuery = returnQuery
    return this

  update: (returnQuery, attributes) =>
    @updatingInstance = attributes
    @updatedQuery = returnQuery
    return this

  action: (method, action, callback) =>
    @router[method] "/#{action}", callback

module.exports = Resource
