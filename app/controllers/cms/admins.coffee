Admin = require('mongoose').model 'Admin'
Resource = require('../../services/resource')
admins = new Resource('Admin')

admins.show (query) -> query.select '-password -salt'
admins.list (query) -> query.select '-password -salt'

admins.changepass = (req, res) ->
  Admin.findOne(login: req.user.login).exec (err, admin) ->
    admin.changePassword req.body.newPass, (err) ->
      return res.status(400).json if err

      res.end()

admins.getAdmin = (req, res) ->
  admin =
    name: req.user.name || req.user.login
    access: req.user.access
    group_id: req.user.group_id
  res.json req.user

admins.mount()

module.exports = admins
