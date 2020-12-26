start = ->
  angular.module('VitalCms.controllers.users', [])
    .config(['$stateProvider', usersConfig])
    .controller('UserListCtrl', UserListCtrl)

usersConfig = ($stateProvider) ->
  $stateProvider
    .state('users',
      url: '/users'
      abstract: true
      template: '<ui-view/>')

    .state('users.index'
      url: ''
      templateUrl: '/cms/partials/users/index.html'
      controller: 'UserListCtrl'
      ncyBreadcrumb:
        label: 'Пользователи')

class UserListCtrl
  @$inject: ['$scope', 'User', 'vitTableParams']

  constructor: ($scope, User, vitTableParams) ->
    $scope.globalFilter = {}
    $scope.users = User.query ->
      $scope.tableParams.reload()

    $scope.banUser = (user) ->
      User.update {userId: user._id}, {isBanned: true}, ->
        user.isBanned = true

    $scope.unbanUser = (user) ->
      User.update {userId: user._id}, {isBanned: false}, ->
        user.isBanned = false

    $scope.updateFilter = ->
      $scope.tableParams.reload()

    $scope.tableParams = vitTableParams(
      $scope.users
      $scope.globalFilter)

    $scope.deleteUser = (user) ->
      index = $scope.users.indexOf(user)
      user.$delete ->
        $scope.users.splice index, 1
        $scope.alerts.push
          msg: 'Пользователь успешно удален'
          type: 'success'

        $scope.tableParams.reload()

start()
