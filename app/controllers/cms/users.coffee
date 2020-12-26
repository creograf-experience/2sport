User = require('mongoose').model 'User'
Resource = require('../../services/resource')
users = new Resource('User')

users.show (query) -> query.select '-passwordHash -salt'
users.list (query) -> query.select '-passwordHash -salt'

users.mount()

module.exports = users
