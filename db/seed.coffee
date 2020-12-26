config = require 'nconf'
path = require 'path'
async = require 'async'
db = require '../app/models'
mongoose = require 'mongoose'
Admin = mongoose.model 'Admin'
Group = mongoose.model 'Group'
Page = mongoose.model 'Page'
CmsModule = mongoose.model 'CmsModule'
_ = require 'lodash'

config.file(file: path.join __dirname, '../config/application.json')

mongoose.connect config.get("database:production")
mongoose.connection.once 'open', ->
  async.parallel [
    seedAdmins
    seedPages
    seedModules
  ], (err) ->
    console.log err if err
    mongoose.disconnect()

seedAdmins = (next) ->
  Group.findOne(name: 'Супервизоры').exec (err, group) ->
    group ?= new Group
      name: 'Супервизоры'
      super: true

    group.save ->
      Admin.findOne(login: 'admin').exec (err, admin) ->
        return next() if admin
        admin = new Admin
          name: 'admin'
          login: 'admin'
          email: 'admin@adminland.hk'
          password: config.get('adminPass')
          fullAccess: true
          groupId: group._id

        admin.save next

seedPages = (next) ->
  Page.find().exec (err, pages) ->
    return next() if pages.length > 0
    Page.create
      title: 'домашняя'
      body: '<p>Заглушка</p>'
      isstart: true
      template: 'simple'
      , (err) ->
        next(err)

seedModules = (next) ->
  CmsModule.find (err, modules) ->
    hasPages = !!_.find modules, name: 'pages'
    hasMain = !!_.find modules, name: 'main'
    hasLeads = !!_.find modules, name: 'leads'
    hasMM = !!_.find modules, name: 'MM'

    pagesModule =
      name: 'pages'
      settings:
        maxVersions: 10
    mainModule =
      name: 'main'
      settings:
        mailer: from: 'admin@vitalcms.org'
    leadsModule =
      name: 'leads'
      settings:
        statuses: [
          'новый'
          'в обработке'
          'отвалился'
          'работаем']

    MModule =
      name: 'mm'
      settings:
        orgBranches: require('./org-branches')

    async.parallel [
      (nextModule) ->
        return nextModule() if hasPages
        CmsModule.create pagesModule, nextModule
      (nextModule) ->
        return nextModule() if hasMain
        CmsModule.create mainModule, nextModule
      (nextModule) ->
        return nextModule() if hasMM
        CmsModule.create MModule, nextModule
      (nextModule) ->
        return nextModule() if hasLeads
        CmsModule.create leadsModule, nextModule
    ], next
  
