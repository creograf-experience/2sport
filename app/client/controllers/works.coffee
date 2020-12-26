start = ->
  angular.module('VitalCms.controllers.works', [])
    .config(['$stateProvider', workConfig])
    .controller('WorkListCtrl', WorkListCtrl)
    .controller('WorkShowCtrl', WorkShowCtrl)
    .controller('WorkCreateCtrl', WorkCreateCtrl)

workConfig = ($stateProvider) ->
  $stateProvider
    .state('works'
      url: '/works'
      templateUrl: '/cms/partials/works/index.html'
      controller: 'WorkListCtrl as mv'
      ncyBreadcrumb:
        label: 'Работы')

    .state('worksCreate'
      url: '/works/new'
      templateUrl: '/cms/partials/works/create.html'
      controller: 'WorkCreateCtrl as mv'
      ncyBreadcrumb:
        label: 'Новая работа'
        parent: 'works')

    .state('worksShow'
      url: '/works/:workId'
      templateUrl: '/cms/partials/works/show.html'
      controller: 'WorkShowCtrl as mv'
      ncyBreadcrumb:
        label: '{{mv.work.title}}'
        parent: 'works')

class WorkListCtrl
  @$inject: ['Work']

  constructor: (Work) ->
    mv = this

    mv.works = Work.query()

    mv.deleteWork = (work) ->
      index = mv.works.indexOf(work)
      work.$delete ->
        mv.works.splice index, 1

    mv.updateWork = (work) ->
      Work.update workId: work._id, work

class WorkCreateCtrl
  @$inject: ['$state', 'Work']

  constructor: ($state, Work) ->
    mv = this
    mv.newWork = new Work(visible: true)

    mv.createWork = ->
      Work.save mv.newWork, ->
        $state.go('works')

class WorkShowCtrl
  @$inject: ['Work', '$stateParams']

  constructor: (Work, $stateParams) ->
    mv = this

    mv.work = Work.get workId: $stateParams.workId

    mv.updateWork = ->
      Work.update workId: mv.work._id, mv.work, ->
        mv.alerts.push
          type: 'success'
          msg: 'Объект обновлен'

    mv.onFileAdd = (file) ->
      Work.addPhoto mv.work._id, file

    mv.onFileRemove = ->
      delete mv.work.photo
      Work.removePhoto workId: mv.work._id

start()
