mongoose = require 'mongoose'
Schema = mongoose.Schema
slug = require 'speakingurl'
extend = require 'mongoose-schema-extend'
tree = require 'mongoose-path-tree'
async = require 'async'
cache = require '../services/cache-manager'
_ = require 'lodash'
PublicationSchema = require './publication'

PageSchema = PublicationSchema.extend
  template:
    type: String, trim: true, default: ''
  menu:
    type: Boolean, default: true
  isstart:
    type: Boolean, default: false
  isMenuItem:
    type: Boolean, default: false

PageSchema.plugin tree

PageSchema.pre 'save', (next) ->
  return next() unless @isstart
  @model('Page').update(
    {_id: '$ne': @_id}
  , {isstart: false}
  , {multi: true})
  .exec next

PageSchema.methods.deleteTemplate = (next) ->
  @update template: null, next

PageSchema.statics.getHome = (options, done) ->
  query = @model('Page').findOne(isstart: true)
  query = query.populate('form') if options.form
  query.exec (err, home) ->
    return done(err) if err
    return done(null, home) if home
    query = Page.findOne()
    query.populate('form') if options.form
    query.exec (err, first) ->
      first.isstart = true
      first.update()
      done(null, home)

PageSchema.statics.getCachedMenu = (done) ->
  cache.wrap 'menu', ((cacheDone) =>
    @model('Page').getChildrenTree filters: menu: true, (err, menu) ->
      return cacheDone(err) if err
      cacheDone(null, children: menu)
  ), done

PageSchema.statics.getCachedHome = (done) ->
  cache.wrap 'homePage', ((cacheDone) =>
    @model('Page').getHome form: true, cacheDone
  ), done

PageSchema.statics.getCachedPage = (slug, done) ->
  cache.wrap slug, ((cacheDone) =>
    @model('Page').findOne(slug: slug).populate('form')
    .exec cacheDone
  ), done

mongoose.model 'Page', PageSchema
