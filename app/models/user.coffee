path = require 'path'
mongoose = require 'mongoose'
crate = require 'mongoose-crate'
LocalFS = require 'mongoose-crate-localfs'
ImageMagick = require 'mongoose-crate-imagemagick'
mailer = require '../services/mailer'
shortid = require 'shortid'
Schema = mongoose.Schema
crypto = require 'crypto'
moment = require 'moment'
_ = require 'lodash'

{getTruthy, areFriends, isInvited, almostFriends} = require('../services/model-helpers')
{ObjectId, Mixed} = Schema.Types

randomCode = ->
  crypto.randomBytes(2).toString('hex')

stats =
  meanSpeed:
    type: Number
    default: 0
  maxSpeed:
    type: Number
    default: 0
  distance:
    type: Number
    default: 0
  time:
    type: Number
    default: 0
  workoutAmount:
    type: Number
    default: 0

maxLength = (max) ->
  (string) ->
    string.length < max

UserSchema = new Schema
  passwordHash: String
  salt: String
  vkontakteId: String
  facebookId: String
  twitterId: String

  # push notifications
  gcmId: String
  apnToken: String

  promoCode:
    type: String
    default: randomCode

  # for reg
  name:
    type: String
    default: ''
    required: 'Заполните имя'
    validate: [maxLength(50), 'Имя не может быть длиннее 50 символов']
    trim: true
  email:
    type: String
    default: ''
    trim: true
    required: 'Адрес почты не может быть пустым'
    unique: 'Пользователь с таким адресом email уже зарегестрирован'
    match: [
      /^([\w-\.]+@([\w-]+\.)+[\w-]{2,4})?$/
      'Некорректный email']

  # used by passport. do not change nor delete
  role:
    type: String
    default: 'user'
    trim: true

  # for admins
  ipAddress:
    type: String
    default: ''
    trim: true
  visitedAt: Date
  isBanned:
    type: Boolean
    default: false
  resetPassCode: String
  locale:
    type: String
    trim: true
    default: 'ru'
  utcOffset:
    type: Number
    default: 0

  unit:
    type: String
    default: 'км/ч'

  isVisible:
    type: Boolean
    default: true
  isInvitable:
    type: Boolean
    default: true
  showSuggestions:
    type: Boolean
    default: true
  suggestMale:
    type: Boolean
    default: true
  suggestFemale:
    type: Boolean
    default: true

  ageRange:
    type: String
    default: 'any'

  # main info
  phone:
    type: String
    trim: true
    default: ''
  contactEmail:
    type: String
    trim: true
    default: ''
  dob:
    type: Date
    trim: true
    default: ''
  gender:
    type: String
    trim: true
    default: ''
  country:
    type: String
    default: 'RU'
  language:
    type: String
    default: ''
  city:
    type: String
    trim: true
    default: ''

  stats:
    running: stats
    cycling: stats
    skiing: stats

  unreadChats: [ObjectId]

  {
    toObject: virtuals: true
    toJSON: virtuals: true
  }

# место для индексов
UserSchema.index(slug: true)
UserSchema.index(name: true)
UserSchema.index(surname: true)

UserSchema.plugin crate,
  storage: new LocalFS
    directory: path.resolve(__dirname, '../../public/images/users')
    webDirectory: '/images/users'
  fields:
    photo:
      processor: new ImageMagick
        tmpDir: path.resolve(__dirname, '../../tmp')
        formats: ['JPEG', 'PNG']
        transforms:
          thumb:
            thumbnail: '160x160^'
            format: 'jpg'
          profile:
            resize: '640x280>'
            format: 'jpg'

# без использования виртуальных полей
# пароли из формы потеряются
UserSchema.virtual('password')
.get(-> @_password)
.set (value) ->
  @_password = value
  @salt = @salt || crypto.randomBytes(16).toString('base64')
  @passwordHash = @hashPassword(@_password)

UserSchema.virtual('emailConfirm')
.get(-> @_email)
.set (value) ->
  @_email = value

UserSchema.virtual('passConfirm')
.get(-> @_passConfirm)
.set (value) -> @_passConfirm = value

UserSchema.virtual('id').get ->
  @_id.toString()

UserSchema.virtual('age').get ->
  return unless @dob && @dob.constructor.name == 'Date'

  moment().diff @dob, 'years'

UserSchema.path('passwordHash').validate ((value) ->
  return if !@_password && !@_passConfirm && (@vkontakteId || @facebookId || @odnoklassnikiId)
  if @_password || @_passConfirm
    unless (typeof @_password == 'string') && (@_password.length >= 6)
      @invalidate('password', 'Пароль не может содержать менее 6 символов')

    unless @_password == @_passConfirm
      @invalidate('passwordConfirmation', 'Пароль и подтверждение не совпадают')

  if @isNew && !@_password
    this.invalidate('password', 'required')
), null

UserSchema.methods.hashPassword = (password) ->
  return password unless @salt && password
  crypto.pbkdf2Sync(password, @salt, 10000, 64).toString('base64')

UserSchema.methods.authenticate = (password) ->
  return @passwordHash == @hashPassword(password)

# пытаемся найти пользователя по email, генерируем ему код,
# не содержащий урл-специфичных символов и высылаем имейл
# с ящика из настроек
UserSchema.statics.prepareReset = (email, next) ->
  mongoose.model('User').findOne email: email, (err, user) ->
    return next(err) if err || !user
    user.resetPassCode = crypto.randomBytes(4).toString('base64').replace(/[=+]/g, '0')
    user.save next

    mailer.resetPassword(user)

UserSchema.statics.changePass = (props, next) ->
  mongoose.model('User').findOne(
    email: props.email
    resetPassCode: props.code
    (err, user) =>
      return next(err) if err
      return next(message: 'not found') unless user

      user.password = props.password
      user.passConfirm = props.passConfirm
      user.save next)

# name: String
# country: String
# city: String
# orgBranch: String
# post: String
# inviteReady: Boolean
# организатор? (пока не трогаем)
# gender.male: Boolean
# gender.female: Boolean
# language.en: Boolean
# language.ru: Boolean
# age.$gt: Number
# age.$lt: Number
UserSchema.statics.search = (query, user, next) ->
  pageSize = 30
  page = query.page || 0
  query = _.clone(query)

  mongoQuery = _.pick query, ['country', 'city']

  if query.name
    names = (query.name || '').split(/\s+/).map (name) ->
      new RegExp(name, 'i')
    mongoQuery.$or = [
      {name: $in: names}
      {surname: $in: names}]

  # mongo doesn't accept {$in: []} as "anything"
  # so we avoid adding query on field at all
  genders = getTruthy(query.gender)
  if genders.length > 0
    mongoQuery.gender = $in: genders

  if query.age && (query.age.$lt || query.age.$gt)
    mongoQuery.dob = {}

    if +query.age.$gt
      mongoQuery.dob.$lt = moment().subtract('year', +query.age.$gt).toDate()

    if +query.age.$lt
      mongoQuery.dob.$gt = moment().subtract('year', +query.age.$lt).toDate()

  mongoose.model('User')
    .find(mongoQuery)
    .skip(page * pageSize)
    .limit(pageSize)
    .select('name surname photo')
    .lean()
    .exec next

UserSchema.statics.addUnreadChat = (userId, chatSlug, next) ->
  mongoose.model('User').update(
    {_id: userId}
    {$addToSet: unreadChats: chatSlug}, ->)

UserSchema.statics.removeUnreadChat = (userId, chatSlug, next) ->
  mongoose.model('User').update(
    {_id: userId}
    {$pull: unreadChats: chatSlug}, ->)

UserSchema.statics.updateStats = (id, next) ->
  mongoose.model('Workout')
    .aggregate($match:
      user: id
      isActive: false
      updatedAt: $gte: moment().subtract(1, 'month').toDate())

    .group(
      _id:
        type: '$type'
        week: $week: '$updatedAt'
        year: $year: '$updatedAt'
      meanSpeed: $avg: '$meanSpeed'
      maxSpeed: $max: '$maxSpeed'
      time: $avg: '$time'
      distance: $avg: '$distance'
      workoutAmount: $sum: 1)

    .group(
      _id: '$_id.type'
      meanSpeed: $avg: '$meanSpeed'
      maxSpeed: $max: '$maxSpeed'
      time: $avg: '$time'
      distance: $avg: '$distance'
      workoutAmount: $avg: '$workoutAmount')
    .exec (err, results) ->
      return next(err) if err
      return next() unless results.length > 0

      updateObj = {}

      runningStats = _.find(results, _id: 'running')
      if runningStats
        updateObj['stats.running'] = runningStats

      cyclingStats = _.find(results, _id: 'cycling')
      if cyclingStats
        updateObj['stats.cycling'] = cyclingStats

      skiingStats = _.find(results, _id: 'skiing')
      if cyclingStats
        updateObj['stats.skiing'] = skiingStats

      mongoose.model('User').update({_id: id}, updateObj, next)

# vk API
UserSchema.statics.getByVkId = (data, next) ->
  User = mongoose.model('User')

  userData = data.response[0]
  User.findOne vkontakteId: userData.id, (err, user) ->
    return next(err, user) if err || user
    return next(message: 'provide user id') unless userData.id
    return next(message: 'user not found') unless user

UserSchema.statics.registerByVk = (data, next) ->
  User = mongoose.model('User')

  userData = data.response[0]
  user = new User
    vkontakteId: userData.id
    name: "#{userData.first_name} #{userData.last_name}"
    email: data.email
  user.save next

#fb API
UserSchema.statics.getByFbId = (data, next) ->
  User = mongoose.model('User')
  User.findOne facebookId: data.id, (err, user) ->
    return next(err, user) if err || user
    return next(message: 'provide user id') unless data.id
    return next(message: 'user not found') unless user


UserSchema.statics.registerByFb = (data, dataEmail, next) ->
  User = mongoose.model('User')

  user = new User
    facebookId: data.id
    name: data.name
    email: dataEmail
  user.save next

#tw API
UserSchema.statics.getByTwId = (data, next) ->
  User = mongoose.model('User')
  User.findOne twitterId: data.id, (err, user) ->
    return next(err, user) if err || user
    return next(message: 'provide user id') unless data.id
    return next(message: 'user not found') unless user

UserSchema.statics.registerByTw = (data, next) ->
  User = mongoose.model('User')

  user = new User
    twitterId: data.id_str
    name: data.name
    email: data.email
  user.save next

module.exports = mongoose.model 'User', UserSchema
