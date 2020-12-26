start = ->
  angular.module('VitalCms.controllers.trash', [])
    .config(['$stateProvider', trashConfig])
    .controller('TrashListCtrl', TrashListCtrl)

trashConfig = ($stateProvider) ->
  $stateProvider
    .state('trash'
      url: '/trash'
      templateUrl: '/cms/partials/trash/index.html'
      controller: 'TrashListCtrl'
      ncyBreadcrumb:
        label: 'Корзина')

class TrashListCtrl
  @$inject: ['$scope', 'Page', 'Form', 'Product', 'News']

  constructor: ($scope, Page, Form, Product, News) ->
    $scope.displayFull = true
    $scope.resources =
      pages:
        model: Page
        list: Page.listDeleted()
      forms:
        model: Form
        list: Form.listDeleted()
      products:
        model: Product
        list: Product.listDeleted()
      news:
        model: News
        list: News.listDeleted()

    $scope.deleteDoc = (resource, doc) ->
      index = $scope.resources[resource].list.indexOf(doc)

      doc.$delete ->
        $scope.resources[resource].list.splice index, 1
        $scope.alerts.push
          msg: 'Документ удален насовсем'
          type: 'success'

    $scope.restoreDoc = (resource, doc) ->
      index = $scope.resources[resource].list.indexOf(doc)
      doc.$restore ->
        $scope.resources[resource].list.splice index, 1
        $scope.alerts.push
          msg: 'Документ восстановлен'
          type: 'success'

start()
