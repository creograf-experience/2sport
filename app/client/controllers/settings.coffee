start = ->
  angular.module('VitalCms.controllers.settings', [])
    .config(['$stateProvider', settingsConfig])
    .controller('SettingsMainCtrl', SettingsMainCtrl)

settingsConfig = ($stateProvider) ->
  $stateProvider
    .state('settings'
      url: '/settings'
      templateUrl: '/cms/partials/settings/main.html'
      controller: 'SettingsMainCtrl'
      ncyBreadcrumb:
        label: 'Настройки сайта')

class SettingsMainCtrl
  @$inject: ['$scope', 'Settings', '$http']

  constructor: ($scope, Settings, $http) ->
    $scope.settings = Settings.get(module: 'main')
    $scope.trackers = [
      {code: 'ga', fullName: 'Google Analytics'}
      {code: 'ya', fullName: 'Яндекс метрика'}
    ]

    $scope.updateOptions = ->
      Settings.update module: 'main', $scope.settings, ->
        $scope.alerts.push
          msg: 'Настройки обновлены'
          type: 'success'

    $scope.sendMail = ->
      $http.post('/cms/api/mail', message: 'success').success (data) ->
        console.log data

start()
