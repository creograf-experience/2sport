News = require('mongoose').model 'News'
Resource = require '../../services/resource'

news = new Resource('News', recyclable: true)

news.list (query) -> query.sort createdAt: -1

news.router.put '/:id/autosave', (req, res) ->
  News.findById(req.params.id).exec (err, news) ->
    news.saveDraft req.body, (data) ->
      return res.status(400).end() if err
      res.end()

news.router.post '/:id/publish', (req, res) ->
  News.findById(req.params.id).exec (err, news) ->
    news.publish (err) ->
      return res.status(400).end() if err
      res.json news

news.router.get '/:id/versions', (req, res) ->
  News.VersionedModel.findOne(refId: req.params.id)
  .exec (err, model) ->
    model.versions.pop()
    res.json model.versions

news.mount()

module.exports = news
