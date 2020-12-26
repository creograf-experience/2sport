start = ->
  angular.module('VitalCms.controllers.customers', [])
    .config(['$stateProvider', customerConfig])
    .controller('CustomerListCtrl', CustomerListCtrl)
    .controller('CustomerShowCtrl', CustomerShowCtrl)

customerConfig = ($stateProvider) ->
  $stateProvider
    .state('customers'
      url: '/customer'
      templateUrl: '/cms/partials/customers/index.html'
      controller: 'CustomerListCtrl'
      ncyBreadcrumb:
        label: 'Покупатели')

    .state('customersShow'
      url: '/customers/:customerId'
      templateUrl: '/cms/partials/customers/show.html'
      controller: 'CustomerShowCtrl'
      ncyBreadcrumb:
        label: '{{customer.name || customer.email}}'
        parent: 'customers')


class CustomerListCtrl
  @$inject: ['$scope', 'Customer']

  constructor: ($scope, Customer) ->
    $scope.customers = Customer.query()

    $scope.deleteCustomer = (customer) ->
      index = $scope.customers.indexOf(customer)
      customer.$delete ->
        $scope.customers.splice index, 1

    $scope.updateCustomer = (customer) ->
      Customer.update {customerId: customer._id}, {visible: customer.visible}

class CustomerShowCtrl
  @$inject: ['$scope', 'Customer', '$stateParams']

  constructor: ($scope, Customer, $stateParams) ->
    $scope.customer = Customer.get customerId: $stateParams.customerId

    $scope.updateCustomer = ->
      Customer.update customerId: $scope.customer._id, $scope.customer, ->
        $scope.alerts.push
          type: 'success'
          msg: 'Отзыв обновлен'

start()
