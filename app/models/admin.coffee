crypto = require 'crypto'
mongoose = require 'mongoose'
Schema = mongoose.Schema
_ = require 'lodash'
modules = Object.keys(require('../services/access').modules)

Access = type: Number, default: 3, min: 0, max: 3

AdminSchema = new Schema
  name:
    type: String
    trim: true
    unique: true
    default: ''
  login:
    type: String
    trim: true
    required: true
  password:
    type: String
    trim: true
    required: true
  email:
    type: String
    trim: true
    unique: true
    default: ''
    required: true
  salt:
    type: String
  groupId:
    type: Schema.Types.ObjectId
  fullAccess:
    type: Boolean
    default: false
  access: _.zipObject modules, modules.map -> Access

modules.forEach (module) ->
  AdminSchema.path("access.#{module}").set (access) ->
    return if @fullAccess then 3 else access

AdminSchema.path('groupId').set (newGroupId) ->
  @oldGroupId = @groupId
  return newGroupId

AdminSchema.methods.hashPassword = (password) ->
  if @salt && password
    return crypto.pbkdf2Sync(password, @salt, 10000, 64).toString('base64')
  else
    return password

AdminSchema.pre 'save', (next) ->
  unless @salt
    @salt = crypto.randomBytes(16).toString('base64')
    @password = @hashPassword(@password)

  if !@groupId || String(@groupId) == String(@oldGroupId)
    return next()

  adminShort =
    _id: @_id
    name: @name
    login: @login
    email: @email

  mongoose.model('Group').findOne _id: @groupId, (err, group) =>
    @access = group.access
    mongoose.model('Group').update(
      {_id: $ne: group._id}
      {'$pull': admins: _id: @_id}
      {multi: true}
    ).exec (err) -> group.update('$addToSet': admins: adminShort, next)

AdminSchema.pre 'remove', (next) ->
  mongoose.model('Group').update({_id: @groupId},
    '$pull': admins: _id: @_id
  ).exec (err) ->
    next(err)

AdminSchema.methods.authenticate = (password) ->
  return @password == @hashPassword(password)

AdminSchema.methods.changePassword = (newPassword, done) ->
  @update(password: @hashPassword(newPassword)).exec (err) ->
    done(err)

mongoose.model('Admin', AdminSchema)
