require('mongoose').Promise = Promise

module.exports =
  Lead: require('./lead')
  Group: require('./group')
  Admin: require('./admin')
  Page: require('./page')
  CmsModule: require('./module')
  News: require('./news')
  Feedback: require('./feedback')
  User: require('./user')
  Chat: require('./chat')
  Workout: require('./workout')
  UserStat: require('./user-stat')
