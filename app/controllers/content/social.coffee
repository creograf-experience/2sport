router = require('express').Router()

router.post '/share/workout/:id', (req, res) ->
  res.json
    _id: req.params.id
    user: req.user._id
    token: req.body.token

module.exports = router
