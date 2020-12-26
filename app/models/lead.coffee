mongoose = require 'mongoose'
Schema = mongoose.Schema
timestamps = require 'mongoose-timestamp'

LeadSchema = new Schema
  name:
    type: String
    required: true
    trim: true
    default: ''
  phone:
    type: String
    trim: true
    default: ''
  email:
    type: String
    trim: true
    default: ''
  nextDate: Date
  nextStep:
    type: String
    trim: true
    default: ''
  status: String

LeadSchema.plugin timestamps

LeadSchema.index createdAt: 1

LeadSchema.pre 'save', (next) ->
  unless @status
    next()
  else
    next()

mongoose.model 'Lead', LeadSchema
