start = ->
  angular.module('VitalCms.controllers.leads', [])
    .config(LeadConfig)
    .controller('LeadListCtrl', LeadListCtrl)
    .controller('StatusCtrl', StatusCtrl)

class LeadConfig
  @$inject: ['$stateProvider']

  constructor: ($stateProvider) ->
    $stateProvider
      .state('leads'
        url: '/leads'
        template: '<ui-view>'
        abstract: true
        resolve:
          settings: ['Settings', (Settings) ->
            Settings.get(module: 'leads').$promise
          ])

      .state('leads.index'
        url: ''
        templateUrl: '/cms/partials/leads/index.html'
        controller: 'LeadListCtrl'
        ncyBreadcrumb:
          label: 'Лиды')

      .state('leads.settings'
        url: '/settings'
        templateUrl: '/cms/partials/leads/settings.html'
        controller: 'StatusCtrl'
        ncyBreadcrumb:
          label: 'Настройки'
          parent: 'leads.index')

class LeadListCtrl
  @$inject: ['$scope', '$filter', 'Lead', 'settings', 'ngTableParams']

  constructor: ($scope, $filter, Lead, settings, ngTableParams) ->
    $scope.leads = []
    $scope.statuses = settings.statuses

    $scope.updateFilter = ->
      if $scope.leads.$resolved
        $scope.tableParams.reload()

    $scope.tableParams = new ngTableParams {
      page: 1
      count: 100
      sorting:
        createdAt: 'desc'
      },
      total: $scope.leads.length
      getData: ($defer, params) ->
        filteredData = $filter('filter')($scope.leads, $scope.globalFilter)

        orderedData = if params.sorting()
          $filter('orderBy')(filteredData, params.orderBy())
        else
          filteredData

        $defer.resolve(orderedData.slice((params.page() - 1) *
          params.count(), params.page() * params.count()))

    $scope.tableParams.settings().$scope = $scope

    $scope.leads = Lead.query ->
      $scope.tableParams.reload()

    $scope.deleteLead = (lead) ->
      index = $scope.leads.indexOf(lead)
      Lead.delete leadId: lead._id, (r) ->
        $scope.leads.splice index, 1
        $scope.tableParams.reload()

    $scope.updateLead = (lead) ->
      Lead.update leadId: lead._id, lead, ->
        $scope.tableParams.reload()

    $scope.addRandomLead = ->
      Lead.addRandom (newLead) ->
        $scope.leads.push(newLead)
        $scope.tableParams.reload()

class StatusCtrl
  @$inject = ['$scope', '$filter', 'Settings', 'settings']

  constructor: ($scope, $filter, Settings, settings) ->
    $scope.settings = settings
    $scope.newStatus = {}

    $scope.updateSettings = ->
      Settings.update module: 'leads', settings

start()
