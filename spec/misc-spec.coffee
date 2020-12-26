_ = require 'lodash'

describe 'model helpers', ->
  {matchingAges, matchingGenders} = require '../app/services/model-helpers'

  {vasya, petya, misha, kolya, masha} = require './fixtures/users'

  describe 'matchingAges', ->
    it 'returns true if both in range', ->
      expect(matchingAges(vasya, misha)).toBeTruthy()
      expect(matchingAges(vasya, masha)).toBeFalsy()

  describe 'matchingGenders', ->
    it 'returns true if genders match', ->
      expect(matchingGenders(vasya, petya)).toBeTruthy()
      expect(matchingGenders(vasya, misha)).toBeTruthy()
      expect(matchingGenders(vasya, kolya)).toBeTruthy()
      expect(matchingGenders(vasya, masha)).toBeFalsy()
