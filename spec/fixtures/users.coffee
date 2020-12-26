{ObjectId} = require('mongoose').Types

module.exports =
  vasya:
    _id: new ObjectId()
    name: 'Vasya'
    email: 'vaya@gmail.com'
    dob: new Date('11.11.1991')
    gender: 'm'
    password: '123123123'
    passConfirm: '123123123'
    ageRange: '18 - 30'
    isVisible: true
    suggestMale: true
    suggestFemale: false

  petya:
    _id: new ObjectId()
    name: 'Petya'
    email: 'petya@cyka.com'
    dob: new Date('11.11.1991')
    age: 24
    gender: 'm'
    password: '123123123'
    passConfirm: '123123123'
    ageRange: '18 - 30'
    isVisible: true
    isInvitable: true
    suggestMale: false
    suggestFemale: false

  misha:
    _id: new ObjectId()
    name: 'Misha'
    email: 'misha@cyka.com'
    dob: new Date('11.11.1991')
    age: 24
    gender: 'm'
    password: '123123123'
    passConfirm: '123123123'
    ageRange: '18 - 30'
    isInvitable: true
    isVisible: false
    suggestMale: true
    suggestFemale: true

  kolya:
    _id: new ObjectId()
    name: 'Kolya'
    email: 'kolya@cyka.com'
    dob: new Date('11.11.1991')
    age: 24
    gender: 'm'
    password: '123123123'
    passConfirm: '123123123'
    ageRange: '18 - 30'
    isInvitable: true
    isVisible: true
    suggestMale: true
    suggestFemale: false

  masha:
    _id: new ObjectId()
    name: 'Masha'
    email: 'masha@cyka.com'
    dob: new Date('11.11.1991')
    age: 35
    gender: 'm'
    password: '123123123'
    passConfirm: '123123123'
    ageRange: '18 - 30'
    isInvitable: true
    isVisible: true
    suggestMale: false
    suggestFemale: true

  forSlugTest:
    _id: new ObjectId()
    email: 'stepan@example.com'
    dob: new Date('11.11.1991')
    name: 'Stepan'
    surname: 'Shilin'
    password: 'lojkadegtya'
    passConfirm: 'lojkadegtya'
