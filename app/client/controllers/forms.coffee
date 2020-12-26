start = ->
  angular.module('VitalCms.controllers.forms', [])
    .config(['$stateProvider', formsConfig])
    .controller('FormListCtrl', FormListCtrl)
    .controller('FormCreateCtrl', FormsCreateCtrl)
    .controller('FormShowCtrl', FormShowCtrl)
    .controller('FormDataCtrl', FormDataCtrl)

formsConfig = ($stateProvider) ->
  $stateProvider
    .state('forms'
      url: '/forms'
      templateUrl: '/cms/partials/forms/index.html'
      controller: 'FormListCtrl'
      ncyBreadcrumb:
        label: 'Конструктор форм')

    .state('formsNew'
      url: '/forms/new'
      templateUrl: '/cms/partials/forms/create.html'
      controller: 'FormCreateCtrl'
      ncyBreadcrumb:
        label: 'Новая форма'
        parent: 'forms')

    .state('form'
      abstract: true
      url: '/forms/:formId'
      template: '<ui-view/>'
      resolve:
        form: ['$stateParams', 'Form', ($stateParams, Form) ->
          Form.get(formId: $stateParams.formId).$promise
        ])

    .state('form.show'
      url: ''
      templateUrl: '/cms/partials/forms/show.html'
      controller: 'FormShowCtrl'
      ncyBreadcrumb:
        label: '{{form.name}}'
        parent: 'forms')

    .state('form.data'
      url: '/data'
      templateUrl: '/cms/partials/forms/data.html'
      controller: 'FormDataCtrl'
      ncyBreadcrumb:
        label: 'Данные'
        parent: 'form.show({formId: form._id})')

class FormListCtrl
  @$inject: ['$scope', 'Form']

  constructor: ($scope, Form) ->
    $scope.forms = Form.query()

    $scope.deleteForm = (form) ->
      index = $scope.forms.indexOf(form)
      form.$recycle ->
        $scope.forms.splice index, 1
        $scope.alerts.push
          msg: 'Форма успешно удалена'
          type: 'success'

class FormsCreateCtrl
  @$inject: ['$scope', '$location', 'Form']

  constructor: ($scope, $location, Form) ->
    $scope.fieldTypes = [
      'text'
      'textarea'
      'hidden'
      'radio'
      'checkbox'
      'select'
    ]
    $scope.newForm = new Form
    $scope.newForm.fields = []
    $scope.newField = type: 'text'

    $scope.addField = ->
      if $scope.newField.label && $scope.newField.name
        newField = {}
        newField = angular.copy($scope.newField)
        newField.type ?= 'text'
        newField.required ?= false
        newField.disabled ?= false
        $scope.newForm.fields.push(newField)
        $scope.newField = type: 'text'
      else
        $scope.alerts.push
          msg: 'Введите name и название поля'
          type: 'danger'

    $scope.deleteField = ($index) ->
      $scope.newForm.fields.splice $index, 1

    $scope.createForm = ->
      Form.save $scope.newForm, ->
        $location.path('/forms')

class FormShowCtrl
  @$inject: ['$scope', '$location', 'Form', 'form']

  constructor: ($scope, $location, Form, form) ->
    console.log $scope.form = form
    $scope.form.fields ?= []
    $scope.fieldTypes = [
      'text'
      'textarea'
      'hidden'
      'radio'
      'checkbox'
      'select'
    ]

    $scope.newField = type: 'text'

    $scope.addField = ->
      if $scope.newField.label && $scope.newField.name
        newField = {}
        newField = angular.copy($scope.newField)
        newField.type ?= 'text'
        newField.required ?= false
        newField.disabled ?= false
        $scope.form.fields.push(newField)
        $scope.newField = type: 'text'
        $scope.updateForm()
      else
        $scope.alerts.push
          msg: 'Введите name и название поля'
          type: 'danger'

    $scope.deleteField = ($index) ->
      $scope.form.fields.splice $index, 1
      $scope.updateForm()

    $scope.updateForm = ->
      Form.update formId: $scope.form._id, $scope.form, (form) ->
        $scope.form = form

    $scope.sortableOptions =
      stop: (e, ui) ->
        unless ui.item.sortable.dropindex == undefined
          $scope.updateForm()
      delay: 150

    $scope.deleteForm = ->
      $scope.form.$recycle (r) ->
        $scope.alerts.push
          msg: 'Форма успешно помещена в корзину'
          type: 'success'
        $location.path('/forms')

class FormDataCtrl
  @$inject: ['$scope', '$filter', 'Form', 'form', 'ngTableParams']

  constructor: ($scope, $filter, Form, form, ngTableParams) ->
    $scope.form = form
    $scope.formData = []
    $scope.tableParams = new ngTableParams {
      page: 1
      count: 50
      sorting:
        createdAt: 'desc'
      },
      total: $scope.formData.length
      getData: ($defer, params) ->
        filteredData = $filter('filter')($scope.formData, $scope.globalFilter)

        orderedData = if params.sorting()
          $filter('orderBy')(filteredData, params.orderBy())
        else
          filteredData

        $defer.resolve(orderedData.slice((params.page() - 1) *
          params.count(), params.page() * params.count()))

    $scope.formData = Form.getData formId: form._id, ->
      $scope.tableParams.reload()

    $scope.sortCol = (fieldName) ->
      $scope.tableParams.sorting(fieldName,
        if $scope.tableParams.isSortBy(fieldName, 'asc') then 'desc' else 'asc')

    $scope.$watch 'globalFilter.$', ->
      if $scope.formData.$resolved 
        $scope.tableParams.reload()

start()
