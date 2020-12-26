module.exports = (error) ->
  if error.errors && error.errors.name && error.errors.name.message
    error.message += ': ' + error.errors.name.message
  return error
