start = ->
  angular.module('VitalCms.services', ['ngResource'])
    .factory('Page', ['$resource', Page])
    .factory('News', ['$resource', News])
    .factory('Lead', ['$resource', Lead])
    .factory('User', ['$resource', User])
    .factory('Admin', ['$resource', Admin])
    .factory('Group', ['$resource', Group])
    .factory('AdminService', ['$http', AdminService])
    .factory('Template', ['$resource', Template])
    .factory('PublicFile', ['$resource', PublicFile])
    .factory('Settings', ['$resource', Settings])
    .factory('Form', ['$resource', Form])
    .factory('Feedback', ['$resource', Feedback])
    .factory('Backup', Backup)
    .factory('vitTableParams', ['$filter', 'ngTableParams', vitTableParams])
    .value('accessTypes', accessTypes)
    .value('modelOptions', modelOptions)

Page = ($resource) ->
  $resource '/cms/api/pages/:pageId', {pageId: '@_id'},

    # @returns a hierarchical object which represents
    # site's menu. Nodes are simplified Page objects
    menu:
      method: 'GET'
      url: '/cms/api/menu'

    # action which tells the server that
    # a child node was moved from one parent
    # node to another.
    # it requires json that looks like
    # {parent: _id, child: _id}
    updateMenu:
      method: 'PUT'
      url: '/cms/api/menu'

    # action for a trash module.
    # @returns all deleted pages.
    # obviously
    listDeleted:
      method: 'GET'
      url: '/cms/api/pages/'
      params: recycled: true
      isArray: true

    # update method with PUT verb
    # isn't default in ngResource
    update:
      method: 'PUT'

    # saves .autosave fields
    # and sets .modified = true
    autosave:
      method: 'PUT'
      url: '/cms/api/pages/:pageId/autosave'

    # copies .autosave fields to the root
    # and sets .modified = false
    publish:
      method: 'POST'
      url: '/cms/api/pages/:pageId/publish'

    # sets page.recycled = true
    recycle:
      method: 'PUT'
      url: '/cms/api/pages/:pageId/recycle'

    # sets page.recycled = false
    restore:
      method: 'PUT'
      url: '/cms/api/pages/:pageId/restore'

    # lists versions. They are simular to
    # Page objects
    getVersions:
      method: 'GET'
      url: '/cms/api/pages/:pageId/versions'
      isArray: true

    # returns a Page with isstart == true
    getHomePage:
      method: 'GET'
      url: '/cms/api/pages/home'

# dupe of Page
News = ($resource) ->
  $resource '/cms/api/news/:newsId', {newsId: '@_id'},
    listDeleted:
      method: 'GET'
      url: '/cms/api/news/'
      params: recycled: true
      isArray: true
    update:
      method: 'PUT'
    autosave:
      method: 'PUT'
      url: '/cms/api/news/:newsId/autosave'
    publish:
      method: 'POST'
      url: '/cms/api/news/:newsId/publish'
    recycle:
      method: 'PUT'
      url: '/cms/api/news/:newsId/recycle'
    restore:
      method: 'PUT'
      url: '/cms/api/news/:newsId/restore'
    getVersions:
      method: 'GET'
      url: '/cms/api/news/:newsId/versions'
      isArray: true

Lead = ($resource) ->
  Lead = $resource '/cms/api/leads/:leadId', {leadId: '@_id'},
    update:
      method: 'PUT'

  # adds a random lead for tests (to DB)
  Lead.addRandom = (callback) ->
    newLead = new Lead()
    names = ['Василий', 'Лососина', 'Петр', 'Наталья', 'Кристина']
    name = names[Math.floor(Math.random()*names.length)]

    Lead.save name: name, callback

  return Lead

User = ($resource) ->
  $resource '/cms/api/users/:userId', {userId: '@_id'},
    update:
      method: 'PUT'

Admin = ($resource) ->
  $resource '/cms/api/admins/:adminId', {adminId: '@_id'},
    update:
      method: 'PUT'

    # Admin.changePass(newPass, oldPass)
    changePass:
      method: 'POST'
      url: '/cms/api/changepass'

Group = ($resource) ->
  $resource '/cms/api/groups/:groupId', {groupId: '@_id'},
    update:
      method: 'PUT'

# isn't used currently
AdminService = ($http) ->
  logIn: (username, password) ->
    $http.post '/cms/login', username: username, password: password
  logOut: ->
    $http.post '/cms/logout'
  getAdminObject: (next) ->
    $http.get '/cms/api/admin'

# templates for Page
Template = ($resource) ->
  $resource '/cms/api/templates'

# resource for Files module
PublicFile = ($resource) ->
  $resource '/cms/api/files/:path', {path: '@path'},
    update:
      method: 'PUT'

    # @returns array of files/dirs
    # in current dir
    get:
      isArray: true

    createDir:
      method: 'POST'

    # @returns a hierarchical object
    # which represents directory structure.
    # Does not contain files
    getDirTree:
      method: 'GET'
      url: '/cms/api/files/dirtree'

# api can only recieve requests for main module
# use only Settings.get('main'),
# Settings.update('main' {}), etc
Settings = ($resource) ->
  $resource '/cms/api/settings/:module', {module: '@name'},
    update:
      method: 'PUT'

# resource for the Forms module
Form = ($resource) ->
  $resource '/cms/api/forms/:formId', {formId: '@_id'},
    listDeleted:
      method: 'GET'
      url: '/cms/api/forms/'
      params: recycled: true
      isArray: true

    update:
      method: 'PUT'

    recycle:
      method: 'PUT'
      url: '/cms/api/forms/:formId/recycle'

    restore:
      method: 'PUT'
      url: '/cms/api/forms/:formId/restore'

    # @returns array of filled forms
    getData:
      method: 'GET'
      url: '/cms/api/forms/:formId/data'
      isArray: true

Feedback = ($resource) ->
  Feedback = $resource '/cms/api/feedbacks/:feedbackId', {feedbackId: '@_id'},
    update:
      method: 'PUT'

  # adds method to a feedback instance.
  # @returns an URL to photo based
  # on the given style ('thumb', 'medium', etc)
  # parts of URL are hardcoded.
  # REFACTOR me plox
  Feedback.prototype.photoUrl = (style) ->
    if this.photo
      this.photo[style].url
    else
      '/resources/150x150.gif'
  return Feedback

# wrapup for localStorage, used for saving
# form data and such
Backup = ->
  # stores json on some key
  # in localStorage.backups.
  # writes path relying on the current
  # module or url, e.g.
  # Backup.store('pages/new', formData) or
  # Backup.store("pages/#{page._id}", formData)
  store: (path, document) ->
    return if !(path && document)

    document.updatedAt = Date.now()

    if localStorage.backups
      backups = angular.fromJson(localStorage.backups)
    else
      backups = {}

    backups[path] = document
    localStorage.backups = angular.toJson(backups)

  restore: (path) ->
    if localStorage.backups
      backups = angular.fromJson(localStorage.backups)
      backup = backups[path]
      return backup

  remove: (path) ->
    if localStorage.backups
      backups = angular.fromJson(localStorage.backups)
      delete backups[path]
      localStorage.backups = angular.toJson(backups)

  # returns patched doc if backup is up to date
  patchDoc: (doc, backup) ->
    return doc unless backup
    if doc.updatedAt > backup.updatedAt
      Backup.remove("pages/#{page._id}")
    else
      Object.keys(backup)
        .filter((fieldName) -> fieldName != 'updatedAt')
        .forEach (fieldName) -> doc[fieldName] = backup[fieldName]
    return doc

vitTableParams = ($filter, ngTableParams) ->
  (data, filter, options) ->
    options = {}

    tableParams = new ngTableParams {
      page: 1
      count: 25
      sorting: options.sorting
      total: data.length
    },
      getData: (params) ->
        params.total(data.length)
        filteredData = $filter('filter')(data, filter)
        orderedData = if params.sorting()
          $filter('orderBy')(filteredData, params.orderBy())
        else
          filteredData

        return orderedData.slice((params.page() - 1) *
          params.count(), params.page() * params.count())

# options for access select
# in the Admins/Groups module
accessTypes = [
  'Нет доступа'
  'Только просмотр'
  'Просмотр и добавление'
  'Полный доступ'
]

# ngModelOptions
# required when vitFormAutosave is used
modelOptions =
  debounce: 1000

start()
