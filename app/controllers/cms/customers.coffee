Customer = require('mongoose').model 'Customer'
Resource = require('../../services/resource')
customers = new Resource('Customer')

customers.show (query) -> query.select '-passwordHash -salt'
customers.list (query) -> query.select '-passwordHash -salt'

customers.mount()

module.exports = customers
