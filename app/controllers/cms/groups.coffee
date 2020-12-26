# db = require '../../models'
Resource = require '../../services/resource'
groups = new Resource('Group')

groups.mount()

module.exports = groups
