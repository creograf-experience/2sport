start = ->
  angular.module('VitalCms.controllers.admins', [])
    .config(['$stateProvider', adminsConfig])
    .controller('AdminListCtrl', AdminListCtrl)
    .controller('GroupCreateCtrl', GroupsCreateCtrl)
    .controller('GroupShowCtrl', GroupShowCtrl)
    .controller('AdminCreateCtrl', AdminsCreateCtrl)
    .controller('AdminShowCtrl', AdminShowCtrl)
    .controller('AdminPassCtrl', AdminPassCtrl)

adminsConfig = ($stateProvider) ->
  $stateProvider
    .state('admins',
      url: '/admins'
      abstract: true
      template: '<ui-view/>')

    .state('admins.index'
      url: ''
      templateUrl: '/cms/partials/admins/index.html'
      controller: 'AdminListCtrl'
      ncyBreadcrumb:
        label: 'Пользователи')

    .state('admins.new'
      url: '/new'
      templateUrl: '/cms/partials/admins/create.html'
      controller: 'AdminCreateCtrl'
      ncyBreadcrumb:
        label: 'Новый пользователь'
        parent: 'admins.index')

    .state('admins.show'
      url: '/:adminId'
      templateUrl: '/cms/partials/admins/show.html'
      controller: 'AdminShowCtrl'
      ncyBreadcrumb:
        label: '{{admin.name || admin.email}}'
        parent: 'admins.index')

    .state('adminsChangePass'
      url: '/change-pass'
      templateUrl: '/cms/partials/admins/pass.html'
      controller: 'AdminPassCtrl'
      ncyBreadcrumb:
        label: 'Смена пароля'
        parent: 'admins.index')

    .state('groups',
      url: '/groups'
      abstract: true
      template: '<ui-view/>')

    .state('groups.new'
      url: '/new'
      templateUrl: '/cms/partials/groups/create.html'
      controller: 'GroupCreateCtrl'
      ncyBreadcrumb:
        label: 'Новая группа'
        parent: 'admins.index')

    .state('groups.show'
      url: '/:groupId'
      templateUrl: '/cms/partials/groups/show.html'
      controller: 'GroupShowCtrl'
      ncyBreadcrumb:
        label: 'Группа "{{group.name}}"'
        parent: 'admins.index')

class AdminListCtrl
  @$inject: ['$scope', 'Group', 'Admin']

  constructor: ($scope, Group, Admin) ->
    $scope.newGroup = {}
    $scope.groups = Group.query()
    $scope.admins = Admin.query()

    $scope.deleteAdmin = (admin) ->
      index = $scope.admins.indexOf(admin)
      admin.$delete ->
        $scope.admins.splice index, 1
        $scope.alerts.push
          msg: 'Пользователь успешно удален'
          type: 'success'

    $scope.deleteGroup = (group) ->
      index = $scope.groups.indexOf(group)
      group.$delete ->
        $scope.groups.splice index, 1
        $scope.alerts.push
          msg: 'Группа успешно удалена'
          type: 'success'

class GroupsCreateCtrl
  @$inject: ['$scope', '$location', 'Group', 'accessTypes']

  constructor: ($scope, $location, Group, accessTypes) ->
    $scope.accessTypes = accessTypes
    $scope.modules = Object.keys($scope.session.access)

    accesses = angular.copy($scope.session.access)
    _.each accesses, (val, acc) -> accesses[acc] = 3

    $scope.newGroup = new Group(access: accesses)
    Group.query()

    $scope.changeGlobalAccess = (accessLevel) ->
      console.log 'here'
      _.each $scope.newGroup.access, (val, key) ->
        $scope.newGroup.access[key] = accessLevel

    $scope.createGroup = ->
      Group.save $scope.newGroup, ->
        $location.path('/admins')

class GroupShowCtrl
  @$inject: ['$scope', '$location', '$stateParams', 'Group', 'accessTypes']

  constructor: ($scope, $location, $stateParams, Group, accessTypes) ->
    $scope.group = Group.get groupId: $stateParams.groupId
    $scope.accessTypes = accessTypes

    updateGroup = (callback) ->
      Group.update groupId: $scope.group._id, $scope.group, callback

    $scope.deleteGroup = (i) ->
      $scope.group.$delete (r) ->
        $scope.alerts.push
          msg: 'Страница успешно удалена'
          type: 'success'
        $location.path('/admins')

    $scope.updateGroup = ->
      updateGroup (group) ->
        $scope.alerts.push
          msg: 'Страница успешно обновлена'
          type: 'success'

    $scope.changeGlobalAccess = (accessLevel) ->
      _.each $scope.group.access, (val, key) ->
        $scope.group.access[key] = accessLevel

class AdminsCreateCtrl
  @$inject: ['$scope', '$location', 'Admin', 'Group', 'accessTypes']

  constructor: ($scope, $location, Admin, Group, accessTypes) ->
    $scope.accessTypes = accessTypes
    $scope.newAdmin = new Admin

    $scope.groups = Group.query()

    $scope.createAdmin = ->
      Admin.save $scope.newAdmin, ->
        $location.path('/admins')

class AdminShowCtrl
  inject: ['$scope', '$location', '$stateParams', 'Admin', 'Group', 'accessTypes']

  constructor: ($scope, $location, $stateParams, Admin, Group, accessTypes) ->
    $scope.accessTypes = accessTypes
    $scope.admin = Admin.get adminId: $stateParams.adminId
    $scope.groups = Group.query()

    $scope.updateAdmin = (admin) ->
      Admin.update adminId: $scope.admin._id, $scope.admin, (admin) ->
        $scope.alerts.push
          msg: 'Страница успешно обновлена'
          type: 'success'

    $scope.deleteAdmin = (i) ->
      $scope.admin.$delete (r) ->
        $scope.alerts.push
          msg: 'Страница успешно удалена'
          type: 'success'
        $location.path('/admins')

    $scope.changeGlobalAccess = (accessLevel) ->
      _.each $scope.admin.access, (val, key) ->
        $scope.admin.access[key] = accessLevel

class AdminPassCtrl
  @$inject: ['$scope', 'Admin', '$location']

  constructor: ($scope, Admin, $location) ->
    $scope.changePass = ->
      Admin.changePass
        newPass: $scope.newPass
        oldPass: $scope.oldPass,
        () ->
          $scope.alerts.push
            msg: 'Пароль обновлен'
            type: 'success'

      $location.path('/admins')

start()
