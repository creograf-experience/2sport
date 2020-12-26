class FileManagerPopupCtrl
  @$inject: ['$scope', '$upload', 'PublicFile']

  constructor: ($scope, $upload, PublicFile) ->
    $scope.currentPath = ''
    $scope.upPath = $scope.currentPath.replace(/.*(\/.*?)$/, '')
    $scope.currentFolder = PublicFile.get path: $scope.currentPath

    $scope.deleteFile = (file) ->
      index = $scope.currentFolder.indexOf(file)
      file.$delete ->
        $scope.files.splice index, 1

    $scope.updateFile = (file) ->
      file

    $scope.onFileSelect = ($files) ->
      $files.forEach (file) ->
        $scope.upload = $upload.upload(
          url: "/cms/api/files/#{$scope.currentPath}"
          method: 'PUT'
          file: file
        ).progress((evt) ->
          console.log('percent: ' + parseInt(100.0 * evt.loaded / evt.total))
        ).success (data, status) ->
          $scope.currentFolder = PublicFile.get path: $scope.currentPath

    $scope.openDir = (path) ->
      pathNoSlashes = path.replace(/^\/?(.*)\/$/, '$1')
      curPathNoSlashes = $scope.currentPath.replace(/^\/?(.*)\/$/, '$1')
      return if pathNoSlashes == curPathNoSlashes
      $scope.currentPath = path
      $scope.upPath = $scope.currentPath.replace(/.*(\/.*?)$/, '')
      $scope.currentFolder = PublicFile.get path: $scope.currentPath

    $scope.createFolder = ->
      name = $scope.newFolderName
      if $scope.currentPath.match(/\/$/)
        path = "#{$scope.currentPath}#{name}"
      else
        path = "#{$scope.currentPath}/#{name}"
      PublicFile.createDir path: path, ->
        $scope.newFolderName = null

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

    $scope.choseFile = (path) ->
      tinymce.activeEditor.insertContent('<img src="'+path+'">')
      tinymce.activeEditor.windowManager.close()

angular.module('VitalCms.controllers.fileManagerPopup', [])
  .controller('FileManagerPopupCtrl', FileManagerPopupCtrl)
