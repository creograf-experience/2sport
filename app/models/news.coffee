slug = require 'speakingurl'
mongoose = require 'mongoose'
extend = require 'mongoose-schema-extend'
PublicationSchema = require './publication'

NewsSchema = PublicationSchema.extend
  publishDate:
    type: Date
  preview:
    type: String, trim: true, default: ''

NewsSchema.index createdAt: 1

mongoose.model 'News', NewsSchema
