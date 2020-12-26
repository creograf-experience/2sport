start = ->
  angular.module('VitalCms.controllers.files', [])
    .config(['$stateProvider', '$urlMatcherFactoryProvider',filesConfig])
    .controller('FileManagerCtrl', FileManagerCtrl)
    .controller('FileManagerDirectoryCtrl', FileManagerDirectoryCtrl)
    .controller('DirModalCtrl', DirModalCtrl)

filesConfig = ($stateProvider, $urlMatcherFactoryProvider) ->
  $urlMatcherFactoryProvider.type('filePath',
    decode: (path) -> decodeURIComponent(path)
    encode: (path) -> path
  )
  $stateProvider
    .state('files'
      url: '/files'
      abstract: true
      templateUrl: 'partials/files/index.html'
      controller: 'FileManagerCtrl'
      resolve:
        dirTree: ['PublicFile', (PublicFile) ->
          PublicFile.getDirTree().$promise
        ])

    .state('files.directory'
      url: '{path:filePath}'
      templateUrl: 'partials/files/directory.html'
      controller: 'FileManagerDirectoryCtrl'
      params: path: squash: true
      ncyBreadcrumb:
        label: 'Файловый менеджер')

class FileManagerCtrl
  @$inject: ['$scope', 'dirTree']

  constructor: ($scope, dirTree) ->
      $scope.dirTree = dirTree

class FileManagerDirectoryCtrl
  @$inject: ['$scope', '$state', '$stateParams',
    'PublicFile', 'ModalService']

  constructor: ($scope, $state, $stateParams,
    PublicFile, ModalService) ->
    $scope.currentPath = $stateParams.path || ''
    $scope.upPath = $scope.currentPath.replace(/(.*)\/.*?$/, '$1')
    $scope.currentFolder = PublicFile.get path: $scope.currentPath

    $scope.deleteFile = (file) ->
      index = $scope.currentFolder.indexOf(file)
      file.$delete ->
        $scope.files.splice index, 1

    $scope.updateFile = (file) ->
      file

    $scope.createDir = (name) ->
      if $scope.currentPath.match(/\/$/)
        path = "#{$scope.currentPath}#{name}"
      else
        path = "#{$scope.currentPath}/#{name}"
      PublicFile.createDir path: path

    $scope.deleteNodes = ->
      $scope.currentFolder
      .filter((node) -> node.checked)
      .forEach (node) ->
        index = $scope.currentFolder.indexOf(node)
        $scope.currentFolder.splice index, 1
        PublicFile.delete path: node.path

    $scope.checkAllNodes = ->
      $scope.currentFolder.forEach (node) ->
        node.checked = $scope.allChecked

    $scope.$on 'file:finishUpload', (event, file) ->
      file.path = "#{$scope.currentPath}/#{file.name}"
      $scope.currentFolder.push file

    $scope.openDirModal = ->
      ModalService.showModal
        templateUrl: 'new-directory-modal.html'
        controller: 'DirModalCtrl'
      .then (modal) ->
        modal.close.then (dirname) ->
          return unless dirname
          $scope.createDir dirname

class DirModalCtrl
  @$inject: ['$scope', 'close']
  constructor: ($scope, close) ->
    $scope.addDirectory = ->
      console.log 'adding', $scope.directoryName
      close($scope.directoryName)

    $scope.dismiss = ->
      close(null)

start()
