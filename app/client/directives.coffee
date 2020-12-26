start = ->
  angular.module('VitalCms.directives', [])
    .directive('ngReallyClick', ngReallyClick)
    .directive('vitEditableText', vitEditableText)
    .directive('vitDatePopover', vitDatePopover)
    .directive('vitEditableDate', vitEditableDate)
    .directive('vitAccess', vitAccess)
    .directive('vitFileIcon', vitFileIcon)
    .directive('vitEnter', vitEnter)
    .directive('vitFieldValue', vitFieldValue)
    .directive('vitDirPath', vitDirPath)
    .directive('vitThumb', vitThumb)
    .directive('vitQueuedFile', ['$upload', '$stateParams', vitQueuedFile])
    .directive('vitFileUploader', vitFileUploader)
    .directive('vitFormAutosave', vitFormAutosave)
    .directive('vitImageManager', vitImageManager)
    .directive('vitAttachedImage', vitAttachedImage)
    .directive('vitAutofocus', ['$timeout', vitAutofocus])
    .directive('vitSelectEditor', vitSelectEditor)
    .directive('vitFileSelect', vitFileSelect)
    .directive('vitAttachedFile', vitAttachedFile)
    .directive('vitMainMenu', vitMainMenu)
    .directive('vitMenuPane', vitMenuPane)
    .factory('newDirectoryModal', ['btfModal', newDirectoryModal])

# displays yes/no dialog.
# takes message from ngReallyMessage
ngReallyClick = ->
  restrict: 'A'
  link: (scope, element, attrs) ->
    element.bind 'click', ->
      message = attrs.ngReallyMessage
      if message && confirm(message)
        scope.$apply attrs.ngReallyClick

# slap it on the first input
vitAutofocus = ($timeout) ->
  restrict: 'A'
  link : (scope, $element) ->
    $timeout ->
      $element[0].focus()

# doesn't change directive's ngModel on blur,
# but stores the value in inner input,
# so edited text can be accesses when clicked again.
# Compile is used instead of link, we need to add
# "required" to input before compile
vitEditableText = ->
  restrict: 'E'
  require: 'ngModel'
  templateUrl: '/cms/partials/directives/editable-text.html'
  scope:
    change: '&'
    text: '=ngModel'
  compile: (tElement) ->
    if tElement.attr('required')
      tElement.find('input').attr('required', true)
    return pre: (scope, element, attrs, ngModel) ->
      scope.showEditor = false
      scope.focus = false

      scope.openEditor = ->
        if ngModel.$pristine
          scope.newText = scope.text
        scope.showEditor = true
        setTimeout (-> element.find('input')[0].focus()), 0
        scope.focus = true

      scope.closeWithoutSaving = ->
        ngModel.$setDirty()
        scope.showEditor = false

      scope.saveChanges = ->
        scope.showEditor = false
        ngModel.$setPristine()
        unless scope.newText == scope.text
          scope.text = scope.newText
          ngModel.$setViewValue(scope.newText)

          scope.change()

# hideous unrefactored Chimera.
# does stuff
vitDatePopover = ->
  restrict: 'EA'
  transclude: true
  templateUrl: '/cms/partials/directives/date-popover.html'
  controller: ($scope, $element, $position) ->
    $scope.open = false
    $scope.today = new Date()

    this.setDateField = (date, field, onchange) ->
      popover = angular.element($element.children()[1])
      popoverPos = $position.position(popover)
      fieldPos = $position.position(field)

      popover.css
        top:
          (fieldPos.top + popoverPos.height / 4 -
          fieldPos.height / 2)+'px'
        left:
          (fieldPos.left)+'px'

      $scope.date = date
      $scope.onchange = (newDate) ->
        onchange(newDate)
        $scope.open = false
    this.toggle = ->
      $scope.open = true

# hideous unrefactored Chimera.
# does stuff
vitEditableDate = ->
  restrict: 'EA'
  templateUrl: '/cms/partials/directives/editable-date.html'
  require: '^vitDatePopover'
  scope:
    lead: '='
    change: '&'
  link: (scope, element, attrs, dateCtrl) ->
    scope.selected = false
    scope.showPicker = ->
      dateCtrl.toggle()
      dateCtrl.setDateField scope.lead.nextDate, element, (date) ->
        date.setHours(12)
        scope.lead.nextDate = date
        unless scope.lead.nextDate == scope.oldDate
          scope.change()
        scope.oldDate = date

vitAccess = ->
  restrict: 'A'
  scope:
    vitAccess: '='
  link: (scope, element, attrs) ->
    prevDisp = element.css('display')
    module = Object.keys(scope.vitAccess)[0]
    scope.$root.$watch "session.access.#{module}", (accessLevel) ->
      if accessLevel != undefined
        if accessLevel < scope.vitAccess[module]
          element.css('display', 'none')
        else
          element.css('display', prevDisp)

# directive which displays icon for a file
# relying on its type
vitFileIcon = ->
  scope:
    nodeType: '=vitFileIcon'
  restrict: 'A'
  template: '<span class="glyphicon"
    style="padding-right:5px" ng-class="icon"></span>'
  link: (scope, element, attrs) ->
    if scope.nodeType == 'directory'
      scope.icon = 'glyphicon-folder-open'
    else if scope.nodeType == 'image'
      scope.icon = 'glyphicon-picture'
    else
      scope.icon = 'glyphicon-file'

# add this attribute to an input.
# It will fire stuff on enter
vitEnter = ->
  restrict: 'A'
  link: (scope, element, attrs) ->
    element.bind "keydown keypress", (event) ->
      if event.which == 13
        scope.$apply ->
          scope.$eval(attrs.vitEnter)
        event.preventDefault()

# directive used in form constructor.
# It renders a 'default value' field
# for every type of form input
vitFieldValue = ->
  restrict: 'E'
  templateUrl: 'field-value-input.html'
  scope:
    fieldType: '=vitFieldType'
    defaultValue: '=ngModel'
  link: (scope, element, attrs) ->
    scope.showTextarea = ->
      scope.fieldType in ['textarea', 'select', 'hidden', 'radio']

# directive which takes a filepath (directive path)
# and renders breadcrumbs for file explorer
vitDirPath = ->
  restrict: 'E'
  templateUrl: 'dir-path.html'
  link: (scope, element, attrs) ->
    scope.paths = attrs.vitCurrentPath.split('/')
    .reduce ((paths, dir) ->
      return paths unless dir
      lastPath = paths[paths.length-1]
      del = if lastPath.path.match(/\/$/) then '' else '/'
      path = paths[paths.length-1].path + del + dir
      paths.concat [{name: dir, path: path}]
    ), [{name:'public', path:'/'}]

# directive for thumb displayed in
# a queued file directive.
# It renders new image every time
# corresponded image being cropped
vitThumb = ->
  restrict: 'A'
  template: '<canvas/>'
  scope:
    dtUrl: '='
  link: (scope, element, attrs) ->
    params = scope.$eval(attrs.vitThumb)
    canvas = element.find('canvas')
    reader = new FileReader()
    scope.img = new Image()
    scope.img.onload = ->
      maxDim = Math.max this.height, this.width
      width = params.width || this.width / this.height * params.height
      height = params.height || this.height / this.width * params.width
      canvas.attr(width: width, height: height)
      canvas[0].getContext('2d').drawImage(this, 0, 0,
        width * (this.width / maxDim),
        height * (this.height / maxDim))

    scope.$on 'file:load', (event, dataUrl) ->
      scope.img.src = dataUrl

# directive for a single file in the uploader.
# It takes a file object (not filename or path)
# from "file" attribute,
# uploads it if it's not an image,
# lets crop an image with cropper directive
# (which uses canvas),
# uploads image converting it from dataUrl
# to Blob (adding the filename in a hackish way),
# emits signals on upload finish and crop finish.
# It has progress of file uploading and status.
# TODO cancel of upload, progress bar
vitQueuedFile = ($upload, $stateParams) ->
  helper =
    isImage: (file) ->
      type =  '|' + file.type.slice(file.type.lastIndexOf('/') + 1) + '|'
      return '|jpg|png|jpeg|bmp|gif|'.indexOf(type) != -1
    dataUrlToBlob: (dataURI) ->
      binary = atob(dataURI.split(',')[1])
      mimeString = dataURI.split(',')[0].split(':')[1].split(';')[0]
      array = []
      for i in [0..binary.length]
        array.push binary.charCodeAt(i)

      return new Blob([new Uint8Array(array)], {type: mimeString})

  return {
    restrict: 'E'
    templateUrl: 'queued-file.html'
    scope:
      file: '='
    link: (scope, element, attrs) ->
      scope.currentPath = $stateParams.path || ''
      reader = new FileReader()
      scope.isImage = helper.isImage(scope.file)
      scope.status = 'ready'
      console.log scope.currentPath
      scope.uploadFile = ->
        return unless scope.status == 'ready'
        scope.upload = $upload.upload(
          url: "/cms/api/files/#{scope.currentPath}"
          method: 'PUT'
          file: scope.file
        ).progress((evt) ->
          console.log('percent: ' + parseInt(100.0 * evt.loaded / evt.total))
        ).success (data) ->
          scope.status = 'finished'
          scope.$emit 'file:finishUpload',
            name: scope.file.name
            type: if scope.isImage then 'image' else 'file'
            size: scope.file.size

        scope.status = 'inProgress'

      onLoadFile = (event) ->
        scope.dataUrl = event.target.result
        scope.$digest()
        scope.$broadcast 'file:load', scope.dataUrl

      if scope.isImage
        reader.onload = onLoadFile
        reader.readAsDataURL(scope.file)

      scope.cropImage = ->
        scope.$emit 'image:crop',
          name: scope.file.name
          dataUrl: scope.dataUrl

      scope.$on 'image:cropFinish', (event, data) ->
        if data.name == scope.file.name
          scope.croppedDataUrl = data.dataUrl
          scope.$broadcast 'file:load', scope.croppedDataUrl
          name = scope.file.name
          scope.file = helper.dataUrlToBlob(data.dataUrl)
          scope.file.name = name

      scope.$on 'file:upload', ->
        scope.uploadFile()
      scope.uploadFile() if !scope.isImage
  }

# widget for file uploading.
# it stores queue of uploading files,
# manages events sent from chilren vitQueuedFiles
# and sends them to cropper.
# It sets limit for number of queued files
vitFileUploader = ->
  restrict: 'E'
  templateUrl: '/cms/partials/directives/file-uploader.html'
  controller: ($scope, $stateParams, $upload, ModalService) ->
    $scope.queuedFiles = []
    fileLimit = 10

    $scope.onFileSelect = ($files) ->
      $scope.queuedFiles = $scope.queuedFiles.filter (file) ->
        !file.finished
      filenames = $scope.queuedFiles.map (file) -> file.name
      $files.forEach (file) ->
        return if $scope.queuedFiles.length >= fileLimit
        return if file.name in filenames
        $scope.queuedFiles.push(file)

      ModalService.showModal(
        templateUrl: 'upload-preview-modal.html'
        controller: ($scope, close) ->
          $scope.currentImage = ''
          $scope.dismiss = close

          $scope.uploadAll = ->
            $scope.$broadcast 'file:upload'

          $scope.$on 'image:crop', (event, data) ->
            $scope.currentImage = data.dataUrl
            $scope.currentFile = data.name
            ModalService.showModal(
              templateUrl: 'crop-modal.html'
              controller: ($scope, close) ->
                $scope.croppedImage = ''
                $scope.dismiss = close
                $scope.finishCrop = ->
                  close($scope.croppedImage)

                $scope.$on 'file:finishUpload', (event, finishedFile) ->
                  $scope.queuedFiles = $scope.queuedFiles.map (file) ->
                    file.finished = true if file.name == finishedFile.name
                    return file
              ).then (modal) ->
                modal.scope.currentPath = $scope.currentPath
                modal.scope.currentImage = data.dataUrl
                modal.scope.currentFile = data.name
                modal.close.then (dataUrl) ->
                  $scope.$broadcast 'image:cropFinish',
                    name: $scope.currentFile
                    dataUrl: dataUrl

        ).then (modal) ->
          modal.scope.queuedFiles = $scope.queuedFiles

# directive added to forms autosaves them on change
# (use with ng-model-options='{debounce: 500}'
# to prevent event spam).
# vit-autosave-fields is required
# to filter fields which must be saved
vitFormAutosave = (Backup) ->
  restrict: 'A'
  require: '^form'
  scope:
    formData: '=ngModel'
  link: (scope, element, attrs, formCtrl) ->
    scope.$watch ->
      return if formCtrl.$pristine
      unless attrs.vitAutosaveFields
        throw Error('vit-autosave-fields must be specified')
      unless attrs.vitFormAutosave
        throw Error('vit-form-autosave must be specified')
      return if (attrs.vitAutosaveFields
        .split(/[, ]+/)
        .map (fieldName) -> formCtrl[fieldName]
        .every (input) -> !input || input.$pristine)

      savePath = attrs.vitFormAutosave
      fieldsToSave = attrs.vitAutosaveFields
        .split(/[, ]+/)
        .concat(['_id'])
      formDataToSave = {}
      fieldsToSave.forEach (fieldName) ->
        if scope.formData.autosave
          formDataToSave[fieldName] = scope.formData.autosave[fieldName]
          formDataToSave._id = scope.formData._id
        else
          formDataToSave[fieldName] = scope.formData[fieldName]

      formDataToSave.$autosave = scope.formData.$autosave
      if formDataToSave.$autosave
        formDataToSave.$autosave(
          (responce) ->
          (responce) ->
            Backup.store savePath, formDataToSave
        )
      else
        Backup.store savePath, formDataToSave
      formCtrl.$setPristine()

# directive for adding and deleting images
# from doc that hold multiple images.
# takes an instance of resourse and it's
# parent Resource. Imlying that Resource
# has .addImage and .removeImage actions.
vitImageManager = ->
  restrict: 'E'
  templateUrl: 'image-manager.html'
  scope:
    item: '=vitItem'
    resource: '=vitResource'
  link: (scope) ->
    scope.images = scope.item.images

    scope.currentImage = ''
    scope.croppedImage = ''
    fileLimit = 10

    scope.$on 'image:crop', (event, data) ->
      scope.currentImage = data.dataUrl
      scope.currentFile = data.name

    scope.$on 'file:finishUpload', (event, finishedFile) ->
      scope.queuedFiles = scope.queuedFiles.map (file) ->
        file.finished = true if file.name == finishedFile.name
        return file

    scope.$on 'image:delete', (event, imageId) ->
      scope.resource.removeImage
        productId: scope.item._id
        imageId: imageId, ->
          scope.images = _.reject scope.images, _id: imageId

    scope.finishCrop = ->
      scope.$broadcast 'image:cropFinish',
        name: scope.currentFile
        dataUrl: scope.croppedImage

    scope.onFileSelect = ($files) ->
      $files.forEach (file) ->
        scope.resource.addImage(scope.item._id, file).success (data) ->
          scope.images = data.images

# copy pasted from queued file directive.
# only for displaying image now
vitAttachedImage = ->
  restrict: 'E'
  templateUrl: 'attached-image.html'
  scope:
    image: '=vitImage'
  link: (scope, element, attrs) ->
    scope.deleteImage = ->
      scope.$emit 'image:delete', scope.image._id

    onLoadFile = (event) ->
      scope.dataUrl = event.target.result
      scope.$digest()
      scope.$broadcast 'file:load', scope.dataUrl

    scope.$on 'image:cropped', (dataUrl) ->
      reader = new FileReader()
      reader.onload = onLoadFile
      reader.readAsDataURL(dataUrl)

# allows to edit options for a select
vitSelectEditor = ($timeout) ->
  restrict: 'E'
  templateUrl: '/cms/partials/directives/select-editor.html'
  scope:
    update: '&vitChange'
    options: '=vitOptions'
  link: (scope) ->
    unless (scope.options && _.isArray(scope.options) &&
    (typeof scope.update == 'function'))
      throw Error('provide vit-options and vit-change event')

    scope.sortableOptions =
      delay: 150
      stop: (e, ui) ->
        unless ui.item.sortable.dropindex == undefined
          scope.update()

    scope.addOption = (select) ->
      scope.options.push(scope.newOption)
      scope.update()

    scope.deleteOption = (option) ->
      scope.options.splice scope.options.indexOf(option), 1
      scope.update()

vitFileSelect = ->
  restrict: 'A'
  scope:
    fileHandler: '&vitFileSelect'
  link: (scope, element, attr) ->
    element.bind 'change', (e) ->
      scope.fileHandler($files: e.target.files)

vitAttachedFile = ->
  helper =
    isImage: (file) ->
      type =  '|' + file.type.slice(file.type.lastIndexOf('/') + 1) + '|'
      return '|jpg|png|jpeg|bmp|gif|'.indexOf(type) != -1
    dataUrlToBlob: (dataURI) ->
      binary = atob(dataURI.split(',')[1])
      mimeString = dataURI.split(',')[0].split(':')[1].split(';')[0]
      array = []
      for i in [0..binary.length]
        array.push binary.charCodeAt(i)

      return new Blob([new Uint8Array(array)], {type: mimeString})

  return {
    restrict: 'E'
    templateUrl: '/cms/partials/directives/attached-file.html'
    scope:
      model: '=vitFile'
      onFileAdd: '&vitFileAdd'
      onFileRemove: '&vitFileRemove'
    link: (scope, element, attrs, ngModel) ->
      reader = new FileReader()

      scope.$watch 'model', (value) ->
        if scope.model && (scope.model.constructor.name != 'FileList')
          scope.fromFile = false

          if scope.model.detail
            scope.file = scope.model.detail || scope.model.thumb

      reader.onload = (event) ->
        scope.fromFile = true
        scope.dataUrl = event.target.result
        scope.$digest()
        scope.$broadcast 'file:load', scope.dataUrl

      scope.onFileSelect = (files) ->
        scope.model = files
        scope.file = files[0]
        scope.isImage = helper.isImage(scope.file)

        if scope.isImage
          reader.readAsDataURL(scope.file)

        scope.onFileAdd(file: scope.file) if scope.onFileAdd

      scope.removeFile = ->
        delete scope.file
        delete scope.model
        scope.onFileRemove() if scope.onFileRemove
  }

vitMainMenu = ->
  templateUrl: '/cms/partials/directives/menu-aside.html'
  controllerAs: 'mv'
  controller: ->
    mv = this

    mv.menu = [{
      name: 'Страницы'
      className: 'nav_page'
      children: [{
        name: 'Страницы'
        createNewState: 'pages.new'
        state: 'pages.index'
        access: pages: 1
      }, {
        name: 'Новости'
        createNewState: 'newsNew'
        state: 'news'
        access: news: 1
      }, {
        name: 'Отзывы'
        state: 'feedback'
        access: feedback: 1
      }, {
        name: 'Корзина'
        state: 'trash'
      }]
    }, {
      name: 'Управление'
      className: 'nav_settings'
      children: [{
        name: 'Настройки сайта'
        state: 'settings'
        access: settings: 1
      }, {
        name: 'Управление пользователями'
        state: 'users.index'
        access: admins: 1
      }, {
        name: 'Администраторы'
        state: 'admins.index'
        access: admins: 1
      }]
    }, {
      name: 'Продажи'
      className: 'nav_sales'
      children: [{
        name: 'Лиды'
        state: 'leads.index'
        access: leads: 1
        settingsState: 'leads.settings'
      }, {
        name: 'Статистика поиска'
        state: 'statsSearch'
      }, {
        name: 'Статистика каталога'
        state: 'statsCatalog'
      }]
    }, {
      name: 'Файлы'
      className: 'nav_files'
      state: 'files.directory({path: "/uploads"})'
    }, {
      name: 'Формы'
      className: 'nav_forms'
      state: 'forms'
    }]

    mv.closePane = ->
      mv.isOpen = false
      mv.activeMenu = null

    mv.changeActiveMenu = (index) ->
      unless mv.activeMenu == mv.menu[index]
        mv.activeMenu = mv.menu[index]
      else
        mv.activeMenu = null

      mv.isOpen = !!(mv.activeMenu && mv.activeMenu.children)

    mv.isActive = (index) ->
      'active' if mv.activeMenu == mv.menu[index]

    return

vitMenuPane = ->
  templateUrl: '/cms/partials/directives/menu-pane.html'
  require: '^vitMainMenu'
  scope:
    subMenu: '=vitActiveMenu'
  link: (scope, element, attrs, MainMenuCtrl) ->
    scope.MainMenuCtrl = MainMenuCtrl

newDirectoryModal = (btfModal) ->
  btfModal

start()
