_ = require('lodash')
dateFormat = require 'dateformat'
moment = require 'moment'

placeholderImage = '/resources/150x150.gif'

module.exports =
  extendedTitle: (title, siteName) ->
    return if title
      "#{title} | #{siteName}"
    else
      siteName

  safeImage: (imgObject, style) ->
    if imgObject && imgObject[style] && imgObject[style].url
      imgObject[style].url
    else
      placeholderImage

  formatTime: (time, format) ->
    moment(time).utc().format(format)

  formatPrice: (price) ->
    (price/100).toFixed(2)

  absolutify: (path) ->
    if path.match /^\// then path else '/' + path

  formatNumber: (number) ->
    return number unless _.isNumber(number)

    return number.toFixed(2)

  formatSpeed: (mps) ->
    return mps unless _.isNumber(mps)

    coeffs =
      kmph: 3.6

    return (mps * coeffs['kmph']).toFixed(2)

  doctype: 'html'
  placeholderImage: placeholderImage
  env: process.env['NODE_ENV']
