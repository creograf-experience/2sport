util = require 'util'
slug = require 'speakingurl'
mongoose = require 'mongoose'
version = require 'mongoose-version'
timestamps = require 'mongoose-timestamp'
_ = require 'lodash'
Schema = mongoose.Schema

PublicationSchema = new Schema
  title:
    type: String
    trim: true
    required: 'Заголовок не может быть пустым'
  body:
    type: String, trim: true, default: ''
  slug:
    type: String, trim: true, unique: true, default: ''
  seotitle:
    type: String, trim: true, default: ''
  seokeywords:
    type: String, trim: true, default: ''
  seodescr:
    type: String, trim: true, default: ''
  form:
    type: Schema.Types.ObjectId, ref: 'Form'
  modified:
    type: Boolean, default: false
  visible:
    type: Boolean, default: true
  allow_discuss:
    type: Boolean, default: false
  recycled:
    type: Boolean, default: false
  autosave:
    body:
      type: String
    title:
      type: String, trim: true
    preview:
      type: String

autosaveFields = ['body', 'title', 'preview']

PublicationSchema.plugin timestamps

ignoreExcept = (allowedPaths) ->
  Object.keys(PublicationSchema.paths).filter (path) ->
    allowedPaths.indexOf(path) < 0

PublicationSchema.plugin version,
  maxVersions: 10
  removeVersions: true
  suppressVersionIncrement: false
  ignorePaths: ignoreExcept(autosaveFields)

PublicationSchema.pre 'save', (next) ->
  if @isMenuItem
    @slug = @slug
      .split('/')
      .map((sluglet) -> slug(sluglet))
      .join('/')
    return next()

  @slug = slug(@slug || @title)
  @autosave ?= {}
  autosaveFields.forEach (name) =>
    unless typeof @autosave[name] == 'string'
      @autosave[name] = this[name]

  next()

PublicationSchema.methods.saveDraft = (backup, next) ->
  backup = _.pick backup, autosaveFields
  @update(autosave: backup, modified: true).exec next

PublicationSchema.methods.publish = (next) ->
  if typeof @autosave == 'object' && Object.keys(@autosave).length > 0
    @modified = false

    for name, val of @autosave.toObject()
      this[name] = val
    @save next
  else
    next(Error 'autosave field must be object')

module.exports = PublicationSchema
