angular.module('VitalCms.filters', [])
.filter 'bytes', ->
  (bytes, precision) ->
    return '0 bytes' if bytes == 0
    return '-' if isNaN(parseFloat(bytes)) || !isFinite(bytes)
    precision = 1 if typeof precision == 'undefined'
    units = ['bytes', 'kB', 'MB', 'GB', 'TB', 'PB']
    number = Math.floor(Math.log(bytes) / Math.log(1024))
    return (bytes / Math.pow(1024, Math.floor(number))).toFixed(precision) +  ' ' + units[number]

.filter 'cents', ->
  (cents) -> (cents / 100).toFixed(2)

.filter 'truncate', ->
  (string, length) ->
    return string if string.length <= length
    string.substring(0, length).concat('...')
