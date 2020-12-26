Page = require('mongoose').model 'Page'
Resource = require '../../services/resource'

pages = new Resource('Page', recyclable: true)

pages.router.get '/home', (req, res) ->
  Page.getHome form: false, (err, home) ->
    res.status(400).json err if err
    res.json home

pages.router.put '/:id/autosave', (req, res) ->
  Page.findById(req.params.id).exec (err, page) ->
    return res.status(404).end() if err
    page.saveDraft req.body, (err, data) ->
      return res.status(400).end() if err
      res.end()

pages.router.post '/:id/publish', (req, res) ->
  Page.findById(req.params.id).exec (err, page) ->
    page.publish (err) ->
      return res.status(400).end() if err

      res.json page

pages.router.get '/:id/versions', (req, res) ->
  Page.VersionedModel.findOne(refId: req.params.id)
  .exec (err, model) ->
    return res.json [] unless model && model.versions
    model.versions.pop()
    res.json model.versions

pages.mount()

module.exports = pages
