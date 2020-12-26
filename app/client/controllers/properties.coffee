start = ->
  angular.module('VitalCms.controllers.productProperties', [])
    .config(['$stateProvider', propertyConfig])
    .controller('ProductPropertyListCtrl', ProductPropertyListCtrl)
    .controller('ProductPropertyCreateCtrl', ProductPropertyCreateCtrl)
    .controller('ProductPropertyShowCtrl', ProductPropertyShowCtrl)
  
propertyConfig = ($stateProvider) ->
  $stateProvider
    .state('properties'
      url: '/properties'
      templateUrl: '/cms/partials/properties/index.html'
      controller: 'ProductPropertyListCtrl'
      ncyBreadcrumb:
        label: 'Свойства товаров'
        parent: 'products.index')

    .state('propertiesNew'
      url: '/properties/new'
      templateUrl: '/cms/partials/properties/create.html'
      controller: 'ProductPropertyCreateCtrl'
      ncyBreadcrumb:
        label: 'Новое свойство'
        parent: 'properties')

    .state('propertiesShow'
      url: '/properties/:propertyId'
      templateUrl: '/cms/partials/properties/show.html'
      controller: 'ProductPropertyShowCtrl'
      ncyBreadcrumb:
        label: '{{property.name}}'
        parent: 'properties')

class ProductPropertyListCtrl
  @$inject: ['$scope', '$filter', 'ProductProperty', 'ngTableParams']

  constructor: ($scope, $filter, ProductProperty, ngTableParams) ->
    $scope.displayFull = true
    $scope.properties = ProductProperty.query ->
      $scope.tableParams.reload()

    $scope.updateFilter = ->
      if $scope.properties.$resolved
        $scope.tableParams.reload()

    $scope.tableParams = new ngTableParams {
      page: 1
      count: 100
      sorting:
        title: 'desc'
      },
      total: $scope.properties.length
      getData: ($defer, params) ->
        filteredData = $filter('filter')($scope.properties, $scope.globalFilter)
        orderedData = if params.sorting()
          $filter('orderBy')(filteredData, params.orderBy())
        else
          filteredData
        $defer.resolve(orderedData.slice((params.page() - 1) *
          params.count(), params.page() * params.count()))

    $scope.deleteProperty = (property) ->
      index = $scope.properties.indexOf(property)

      property.$delete ->
        $scope.properties.splice index, 1
        $scope.tableParams.reload()

    $scope.updateProperty = (property) ->
      ProductProperty.update propertyId: property._id, property

class ProductPropertyCreateCtrl
  @$inject: ['$scope', '$location', 'ProductProperty', 'Form', 'Backup']

  constructor: ($scope, $location, ProductProperty, Form, Backup) ->
    $scope.newProperty = new ProductProperty(type: 'string')

    $scope.propertyTypes = ['string', 'number', 'dict']

    $scope.createProperty = ->
      ProductProperty.save $scope.newProperty, ->
        $location.path('/properties')

class ProductPropertyShowCtrl
  @$inject: ['$scope', '$stateParams', 'ProductProperty', 'Form'
    'modelOptions', '$location']

  constructor: ($scope, $stateParams, ProductProperty, Form, $location) ->
    $scope.property = ProductProperty.get propertyId: $stateParams.propertyId

    $scope.propertyTypes = ['string', 'number', 'dict']

    $scope.deleteProperty = ->
      $scope.property.$delete ->
        $location.path('/properties')

    $scope.updateProperty = ->
      ProductProperty.update propertyId: $scope.property._id, $scope.property, ->
        $scope.alerts.push
          msg: 'Товар успешно обновлен'
          type: 'success'

start()
