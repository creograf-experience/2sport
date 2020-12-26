request = require('request-promise')
router = require('express').Router()
{User} = require('../../models')


verifyIosReceipt = (receipt, isTest) ->
  if isTest
    url = 'https://sandbox.itunes.apple.com/verifyReceipt'
  else
    url = 'https://buy.itunes.apple.com/verifyReceipt'
  console.log receipt
  request
  .post(
    url: url
    json: true
    body:
      password: '549cff1345ad41008acbdbbdac7644bb'
      'receipt-data': receipt)
  .then (res) ->
    console.log res
    verified = res.status == 0
    unless verified
      console.log "denied with status #{res.status}"

    return Promise.resolve(verified)

router.post '/ios', (req, res) ->
  verifyIosReceipt(req.body.receipt, false)
  .then (isVerified) ->
    return res.end() if isVerified

    verifyIosReceipt(req.body.receipt, true)

  .then (isVerified) ->
    return res.json message: 'success' if isVerified

    res.status(400).json message: 'verification failed'

module.exports = router
