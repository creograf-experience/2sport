start = ->
  angular.module('VitalCms.controllers.orders', [])
    .config(OrderConfig)
    .controller('OrderListCtrl', OrderListCtrl)
    .controller('OrderSettingsCtrl', OrderSettingsCtrl)
    .controller('OrderShowCtrl', OrderShowCtrl)

class OrderConfig
  @$inject: ['$stateProvider']

  constructor: ($stateProvider) ->
    $stateProvider
      .state('orders'
        url: '/orders'
        template: '<ui-view>'
        abstract: true
        resolve:
          settings: ['Settings', (Settings) ->
            Settings.get(module: 'orders').$promise
          ])

      .state('orders.index'
        url: ''
        templateUrl: '/cms/partials/orders/index.html'
        controller: 'OrderListCtrl'
        ncyBreadcrumb:
          label: 'Заказы')

      .state('orders.settings'
        url: '/settings'
        templateUrl: '/cms/partials/orders/settings.html'
        controller: 'OrderSettingsCtrl'
        controllerAs: 'vm'
        ncyBreadcrumb:
          label: 'Настройки'
          parent: 'orders.index')

      .state('orders.show'
        url: '/:orderId'
        templateUrl: '/cms/partials/orders/show.html'
        controller: 'OrderShowCtrl'
        ncyBreadcrumb:
          label: '{{order.code}}'
          parent: 'orders.index')

class OrderListCtrl
  @$inject: ['$scope', '$filter', 'Order', 'settings', 'ngTableParams']

  constructor: ($scope, $filter, Order, settings, ngTableParams) ->
    $scope.statuses = settings.statuses

    $scope.updateFilter = ->
      if $scope.orders.$resolved
        $scope.tableParams.reload()

    $scope.orders = Order.query ->
      $scope.tableParams.reload()

    $scope.tableParams = new ngTableParams {
      page: 1
      count: 100
      sorting:
        createdAt: 'desc'
      },
      total: $scope.orders.length
      getData: ($defer, orders) ->
        filteredData = $filter('filter')($scope.orders, $scope.globalFilter)

        orderedData = if orders.sorting()
          $filter('orderBy')(filteredData, orders.orderBy())
        else
          filteredData

        $defer.resolve(orderedData.slice((orders.page() - 1) *
          orders.count(), orders.page() * orders.count()))

    $scope.tableParams.settings().$scope = $scope

    $scope.deleteOrder = (order) ->
      index = $scope.orders.indexOf(order)
      Order.delete orderId: order._id, (r) ->
        $scope.orders.splice index, 1
        $scope.tableParams.reload()

    $scope.updateOrder = (order) ->
      Order.update orderId: order._id, order, ->
        $scope.tableParams.reload()

    $scope.addRandomOrder = ->
      Order.addRandom (newOrder) ->
        $scope.orders.push(newOrder)
        $scope.tableParams.reload()

class OrderShowCtrl
  @$inject: ['$scope', '$stateParams', 'Order', 'settings']

  constructor: ($scope, $stateParams, Order, settings) ->
    $scope.statuses = settings.statuses
    $scope.order = Order.get orderId: $stateParams.orderId

    $scope.updateOrder = ->
      Order.update orderId: $scope.order._id, $scope.order

class OrderSettingsCtrl
  @$inject: ['$stateParams', 'Settings', 'settings']

  constructor: ($stateParams, Settings, settings) ->
    vm = this
    vm.settings = settings

    vm.updateSettings = ->
      Settings.update module: 'orders', settings

start()
