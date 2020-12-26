mongoose = require 'mongoose'
_ = require 'lodash'
cache = require '../services/cache-manager'
Schema = mongoose.Schema
{Mixed} = Schema.Types

ModuleSchema = new Schema
  name: type: String, trim: true, require: true
  settings: Mixed

ModuleSchema.statics.getCachedSettings = (done) ->
  cache.wrap 'settings', ((cacheDone) ->
    mongoose.model('CmsModule').findOne(name: 'main')
    .exec (err, mainModule) ->
      return cacheDone(err) if err
      return cacheDone(null, {}) unless mainModule && mainModule.settings

      settings = _.pick mainModule.settings, [
        'footer', 'contacts', 'phone', 'email'
        'address', 'metaYandex'
      ]
      cacheDone err, settings

  ), done

mongoose.model('CmsModule', ModuleSchema)
