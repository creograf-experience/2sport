start = ->
  angular.module('VitalCms.controllers.news', [])
    .config(['$stateProvider', newsConfig])
    .controller('NewsListCtrl', NewsListCtrl)
    .controller('NewsCreateCtrl', NewsCreateCtrl)
    .controller('NewsShowCtrl', NewsShowCtrl)

newsConfig = ($stateProvider) ->
  $stateProvider
    .state('news'
      url: '/news'
      templateUrl: '/cms/partials/news/index.html'
      controller: 'NewsListCtrl'
      ncyBreadcrumb:
        label: 'Новости')

    .state('newsNew'
      url: '/news/new'
      templateUrl: '/cms/partials/news/create.html'
      controller: 'NewsCreateCtrl'
      ncyBreadcrumb:
        label: 'Новая новость'
        parent: 'news')

    .state('newsShow'
      url: '/news/:newsId'
      templateUrl: '/cms/partials/news/show.html'
      controller: 'NewsShowCtrl'
      ncyBreadcrumb:
        label: '{{news.title}}'
        parent: 'news')

class NewsListCtrl
  @$inject: ['$scope', 'News']

  constructor: ($scope, News) ->
    $scope.news = News.query()

    $scope.recycleNews = (news) ->
      index = $scope.news.indexOf(news)
      setDefaultStart() if news.isstart

      news.$recycle ->
        $scope.news.splice index, 1
        $scope.alerts.push
          msg: 'Страница помещена в корзину'
          type: 'success'

    $scope.updateNews = (news) ->
      News.update newsId: news._id, news, (updated) ->
        $scope.news.__v = updated.__v

class NewsCreateCtrl
  @$inject: ['$scope', '$location', 'News', 'Form', 'Backup']

  constructor: ($scope, $location, News, Form, Backup) ->
    backup = Backup.restore('news/new')
    $scope.newNews = backup || new News(visible: true)

    $scope.forms = Form.query()

    $scope.createNews = ->
      News.save $scope.newNews, ->
        $scope.newNews = {}
        Backup.remove 'news/new'
        $location.path('/news')

    $scope.storeBackup = ->
      Backup.store 'news/new', $scope.newNews

class NewsShowCtrl
  @$inject: ['$scope', '$stateParams', 'News', 'Form'
    'modelOptions', '$location']

  constructor: ($scope, $stateParams, News, Form,
  modelOptions, $location) ->
    $scope.initialBackup = {}
    $scope.currentVersion = {}
    $scope.modelOptions = modelOptions

    $scope.news = News.get newsId: $stateParams.newsId, ->
      News.getVersions newsId: $scope.news._id, (versions) ->
        $scope.versions = versions

    $scope.forms = Form.query()

    $scope.recycleNews = (i) ->
      $scope.news.$recycle (r) ->
        $scope.alerts.push
          msg: 'Страница помещена в корзину'
          type: 'success'
        $location.path('/news')

    $scope.publish = ->
      News.publish {newsId: $scope.news._id}, $scope.news
      News.getVersions newsId: $scope.news._id, (versions) ->
        $scope.versions = versions

    $scope.changeVersion = ->
      for field, value of $scope.currentVersion
        unless field in ['_id', 'createdAt', 'updatedAt', '__v']
          $scope.news[field] = value
      $scope.publish()

    $scope.updateNews = ->
      News.update newsId: $scope.news._id, $scope.news, ->
        $scope.alerts.push
          msg: 'Страница успешно обновлена'
          type: 'success'

start()
