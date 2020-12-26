newsRouter = require('express').Router()
News = require('mongoose').model('News')

newsRouter.get '/news/?', (req, res) ->
  News.find().exec (err, news) ->
    res.renderError(400) if err
    res.renderError(404) unless news

    res.render 'news/index', news: news, title: 'Новости'

newsRouter.get '/news/:slug', (req, res) ->
  News.findOne(slug: req.params.slug).exec (err, article) ->
    res.renderError(400) if err
    res.renderError(404) unless article

    res.render 'news/show', article: article, title: article.title

module.exports = newsRouter
