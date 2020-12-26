_ = require 'lodash'

deg2rad = (deg) ->
  deg * (Math.PI/180)

properGender = ({suggestMale, suggestFemale}, gender) ->
  !(suggestMale ^ suggestFemale) ||
  (suggestMale && gender == 'm') ||
  (suggestFemale && gender == 'w')

inAgeRange = (ageRange, age) ->
  if ageRange == 'any' || !ageRange.match(/(\d+)\s*?-\s*?(\d+)/)
    return true

  match = ageRange.match /(\d+)\s*?-\s*?(\d+)/
  start = +match[1]
  end = +match[2]

  return age <= end && age >= start

module.exports =
  # param {male: true, female: false}
  # return ['male']
  getTruthy: (obj) ->
    return [] unless _.isObject(obj)
    filtered = _.chain(obj)
      .map (value, key) -> key: key, value: value
      .filter (pair) -> pair.value
      .map (pair) -> pair.key
      .value()

  distance: (p1, p2) ->
    R = 6371
    dLat = deg2rad(p1[0] - p2[0])
    dLon = deg2rad(p1[1] - p2[1])
    a =
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(deg2rad(p1[0])) * Math.cos(deg2rad(p2[0])) *
      Math.sin(dLon/2) * Math.sin(dLon/2)

    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    d = R * c
    return d * 1000

  m2r: (m) ->
    m / (6371 * 1000)

  inHourRange: (a, b, n) ->
    (b > a && n >= a && n <= b) || ((b <= a) && ((n <= b && n >= 0) || (n >= a && n <= 23)))

  matchingAges: (user1, user2) ->
    inAgeRange(user1.ageRange, user2.age) && inAgeRange(user1.ageRange, user2.age)

  matchingGenders: (user1, user2) ->
    properGender(user1, user2.gender) && properGender(user2, user1.gender)
