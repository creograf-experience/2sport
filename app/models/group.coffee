mongoose = require 'mongoose'
Schema = mongoose.Schema

Access = type: Number, default: 3, min: 0, max: 3

GroupSchema = new Schema
  name:
    type: String
    required: true
  admins: []
  access:
    pages: Access
    admins: Access
    leads: Access
    settings: Access
    forms: Access
    files: Access
    news: Access
    feedback: Access

GroupSchema.methods.addAdmin = (admin) ->
  unless admin.login in @admins.map((admin) -> admin.login)
    @admins.push
      name: admin.name
      login: admin.login
      email: admin.email

mongoose.model('Group', GroupSchema)
