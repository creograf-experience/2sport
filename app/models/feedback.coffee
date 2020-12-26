path = require 'path'
mongoose = require 'mongoose'
Schema = mongoose.Schema
crate = require 'mongoose-crate'
LocalFS = require 'mongoose-crate-localfs'
ImageMagick = require 'mongoose-crate-imagemagick'

FeedbackSchema = new Schema
  name:
    type: String
    required: true
    trim: true
    default: ''
  body:
    type: String
    required: true
    trim: true
    default: ''
  preview:
    type: String
    trim: true
    default: ''
  reply:
    type: String
    require: true
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
  visible:
    type: Boolean
    default: false

FeedbackSchema.pre 'save', (next) ->
  return next() unless @isNew

  @preview = @body

  next()

FeedbackSchema.plugin crate,
  storage: new LocalFS
    directory: path.resolve(__dirname, '../../public/images/feedback')
    webDirectory: '/images/feedback'
  fields:
    photo:
      processor: new ImageMagick
        tmpDir: path.join(process.cwd(), 'tmp')
        formats: ['JPEG', 'PNG']
        transforms:
          thumb:
            thumbnail: '200x200^'
          detail:
            resize: '400x400>'

mongoose.model('Feedback', FeedbackSchema)
