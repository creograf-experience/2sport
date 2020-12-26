angular.module('VitalCms', [
  'ui.router'
  'ui.bootstrap'
  'ui.tinymce'
  'ui.sortable'
  'ngAnimate'
  'ngTable'
  'ngImgCrop'
  'ncy-angular-breadcrumb'
  'angularFileUpload'
  'VitalCms.services'
  'VitalCms.filters'
  'VitalCms.directives'
  'VitalCms.controllers'
])
.config(($urlRouterProvider, $locationProvider, $httpProvider, $breadcrumbProvider) ->
  $locationProvider.html5Mode true

  $urlRouterProvider.otherwise '/'

  authInterceptor = ($q, $rootScope) ->
    responseError: (rejection) ->
      if rejection.status == 403
        $rootScope.alerts.push
          msg: 'Нет доступа'
          type: 'danger'
      else if rejection.status == 401
        return window.location = "/cms/login"

      $rootScope.alerts.push
        msg: rejection.data.message || 'Произошла ошибка'
        type: 'danger'

      $q.reject(rejection)

  $httpProvider.interceptors.push(['$q', '$rootScope', authInterceptor])

  $breadcrumbProvider.setOptions
    templateUrl: '/cms/partials/directives/breadcrumbs.html'

  tinyMCE.baseURL = '/tinymce'

).run ['$rootScope', '$location', 'AdminService',
($rootScope, $location, AdminService) ->
  AdminService.getAdminObject().success (admin) ->
    $rootScope.session = admin
]

angular.element(document).ready  ->
  angular.bootstrap document, ['VitalCms']
