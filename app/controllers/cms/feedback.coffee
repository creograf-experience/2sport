Feedback = require('mongoose').model 'Feedback'
Resource = require('../../services/resource')
feedbacks = new Resource('Feedback')

feedbacks.mount()

module.exports = feedbacks
