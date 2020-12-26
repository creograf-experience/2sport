start = ->
  angular.module('VitalCms.controllers.stats', [])
    .config(['$stateProvider', searchStatConfig])
    .controller('SearchStatCtrl', SearchStatCtrl)
    .controller('CatalogStatCtrl', CatalogStatCtrl)

searchStatConfig = ($stateProvider) ->
  $stateProvider
    .state('statsSearch'
      url: '/stats/seach'
      templateUrl: '/cms/partials/stats/search.html'
      controller: 'SearchStatCtrl'
      ncyBreadcrumb:
        label: 'Статистика поиска')
    .state('statsCatalog'
      url: '/stats/catalog'
      templateUrl: '/cms/partials/stats/catalog.html'
      controller: 'CatalogStatCtrl'
      ncyBreadcrumb:
        label: 'Статистика поиска')

class SearchStatCtrl
  @$inject: ['$scope', '$filter', 'SearchStat', 'ngTableParams']

  constructor: ($scope, $filter, SearchStat, ngTableParams) ->
    $scope.records = []
    $scope.tableParams = new ngTableParams {
      page: 1
      count: 50
      sorting:
        createdAt: 'desc'
      },
      total: $scope.records.length
      getData: ($defer, params) ->
        filteredData = $filter('filter')($scope.records, $scope.globalFilter)

        orderedData = if params.sorting()
          $filter('orderBy')(filteredData, params.orderBy())
        else
          filteredData

        $defer.resolve(orderedData.slice((params.page() - 1) *
          params.count(), params.page() * params.count()))

    $scope.records = $scope.records = SearchStat.query ->
      $scope.tableParams.reload()

    $scope.sortCol = (fieldName) ->
      $scope.tableParams.sorting(fieldName,
        if $scope.tableParams.isSortBy(fieldName, 'asc') then 'desc' else 'asc')

    $scope.$watch 'globalFilter.$', ->
      if $scope.records.$resolved 
        $scope.tableParams.reload()

class CatalogStatCtrl
  @$inject: ['$scope', '$filter', 'CatalogStat', 'ngTableParams']

  constructor: ($scope, $filter, CatalogStat, ngTableParams) ->
    $scope.records = []
    $scope.tableParams = new ngTableParams {
      page: 1
      count: 50
      sorting:
        createdAt: 'desc'
      },
      total: $scope.records.length
      getData: ($defer, params) ->
        filteredData = $filter('filter')($scope.records, $scope.globalFilter)

        orderedData = if params.sorting()
          $filter('orderBy')(filteredData, params.orderBy())
        else
          filteredData

        $defer.resolve(orderedData.slice((params.page() - 1) *
          params.count(), params.page() * params.count()))

    $scope.records = $scope.records = CatalogStat.query ->
      $scope.tableParams.reload()

    $scope.sortCol = (fieldName) ->
      $scope.tableParams.sorting(fieldName,
        if $scope.tableParams.isSortBy(fieldName, 'asc') then 'desc' else 'asc')

    $scope.formatPercents = (a, b) ->
      return '100%' if a > b
      return '0%' if b == 0
      (a / b * 100).toFixed(2) + '%'

    $scope.$watch 'globalFilter.$', ->
      if $scope.records.$resolved 
        $scope.tableParams.reload()

start()
