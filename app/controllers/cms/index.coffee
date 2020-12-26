cmsRouter = require('express').Router()
cmsRouter.use require('./login').router

# api/*
cmsRouter.use '/cms/api/pages', require('./pages').router
cmsRouter.use '/cms/api/menu', require('./menu').router
cmsRouter.use '/cms/api/news', require('./news').router
cmsRouter.use '/cms/api/leads', require('./leads').router

cmsRouter.use '/cms/api/admins', require('./admins').router
cmsRouter.post '/cms/api/changepass', require('./admins').changepass
cmsRouter.get '/cms/api/admin', require('./admins').getAdmin

cmsRouter.use '/cms/api/groups', require('./groups').router
cmsRouter.use '/cms/api/templates', require('./templates').router
cmsRouter.use '/cms/api/files', require('./file-manager').router

cmsRouter.use '/cms/api/settings', require('./settings').router
cmsRouter.post '/cms/api/mail', require('./settings').mailTest

cmsRouter.use '/cms/api/feedbacks', require('./feedback').router
cmsRouter.use '/cms/api/users', require('./users').router

# index.jade loads the angular app
cmsRouter.get '/cms/*', (req, res, next) ->
  res.render 'cms/index'

module.exports = cmsRouter
