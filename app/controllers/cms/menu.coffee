menuRouter = require('express').Router()
Page = require('mongoose').model('Page')

menuRouter.get '/?', (req, res) ->
  Page.getChildrenTree
    fields: 'title slug menu isstart'
    filters:
      recycled: false,
    (err, menu) ->
      return res.status(400).json err if err
      res.json children: menu

menuRouter.put '/?', (req, res) ->
  unless req.body.child && req.body.parent != undefined
    return res.status(400).json
      message: 'parent and child must be provided'

  Page.findById req.body.child, (err, page) ->
    page.parent = req.body.parent

    page.save (err) ->
      return res.status(400).json message: err if err
      res.end()

module.exports.router = menuRouter
