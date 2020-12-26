start = ->
  angular.module('VitalCms.controllers.categories', [])
    .config(['$stateProvider', categoriesConfig])
    .controller('CategoryCtrl', CategoryCtrl)
    .controller('CategoryIndexCtrl', CategoryIndexCtrl)
    .controller('CategoryCreateCtrl', CategoryCreateCtrl)
    .controller('CategoryShowCtrl', CategoryShowCtrl)

categoriesConfig = ($stateProvider) ->
  $stateProvider
  .state('categories',
    url: '/categories'
    templateUrl: '/cms/partials/categories/index.html'
    controller: 'CategoryCtrl'
    abstract: true
    resolve:
      categoryTree: ['Category', (Category) ->
        Category.getTree().$promise])

  .state('categories.index',
    url: ''
    template: ''
    controller: 'CategoryIndexCtrl'
    ncyBreadcrumb:
      label: 'Категории товаров')

  .state('categories.new',
    url: '/new'
    templateUrl: '/cms/partials/categories/create.html'
    controller: 'CategoryCreateCtrl'
    ncyBreadcrumb:
      label: 'Новая категория'
      parent: 'categories.index')

  .state('categories.show',
    url: '/:categoryId'
    templateUrl: 'partials/categories/show.html'
    controller: 'CategoryShowCtrl'
    ncyBreadcrumb:
      label: '{{category.name}}'
      parent: 'categories.index')

class CategoryIndexCtrl
  @$inject: ['$scope']
  constructor: ($scope) -> return

class CategoryCtrl
  @$inject: ['$scope', 'Category', 'categoryTree']

  constructor: ($scope, Category, categoryTree) ->
    $scope.menu = children: categoryTree

    $scope.updateCategory = (category) ->
      console.log category
      Category.update categoryId: category._id, category

    $scope.sortableOptions =
      connectWith: '.category-node'
      delay: 150
      stop: (e, ui) ->
        unless ui.item.sortable.dropindex == undefined
          Category.updateTree
            parent: ui.item.sortable.droptarget.data('node-id')
            child: ui.item.sortable.model._id


class CategoryCreateCtrl
  @$inject: ['$scope', '$state', 'Category']

  constructor: ($scope, $state, Category) ->
    $scope.newCategory = new Category visible: true
    $scope.createCategory = ->
      Category.save $scope.newCategory, ->
        $scope.newCategory = {}
        $state.go('categories.index', {}, reload: true)

class CategoryShowCtrl
  @$inject: ['$scope', '$stateParams', 'Category', 'modelOptions', '$state']

  constructor: ($scope, $stateParams, Category, modelOptions, $state) ->
    $scope.initialBackup = {}
    $scope.currentVersion = {}
    $scope.modelOptions = modelOptions

    $scope.category = Category.get categoryId: $stateParams.categoryId

    $scope.deleteCategory = (i) ->
      Category.delete categoryId: $scope.category._id, ->
        $state.go('categories.index', {}, reload: true)

    $scope.recycleCategory = (i) ->
      $scope.category.$recycle (r) ->
        $scope.alerts.push
          msg: 'Товар помещен в корзину'
          type: 'success'

    $scope.updateCategory = ->
      Category.update categoryId: $scope.category._id, $scope.category, ->
        $scope.alerts.push
          msg: 'Категория обновлена'
          type: 'success'

    $scope.onFileAdd = (file) ->
      Category.addImage $scope.category._id, file

    $scope.onFileRemove = ->
      delete $scope.category.image
      Category.removeImage categoryId: $scope.category._id

    $scope.onFileSelect = ($files) ->
      $files.forEach (file) ->
        Category.addImage($scope.category._id, file).success (data) ->
          $scope.category.image = data.image

start()
