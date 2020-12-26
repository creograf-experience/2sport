start = ->
  angular.module('VitalCms.controllers.pages', [])
    .config(['$stateProvider', pagesConfig])
    .controller('PageCtrl', PageCtrl)
    .controller('PageCreateCtrl', PagesCreateCtrl)
    .controller('PageShowCtrl', PageShowCtrl)
    .controller('MenuItemCreateCtrl', MenuItemCreateCtrl)
    .controller('MenuItemShowCtrl', MenuItemShowCtrl)

pagesConfig = ($stateProvider) ->
  $stateProvider
  .state('pages',
    url: '/pages'
    templateUrl: '/cms/partials/pages/index.html'
    controller: 'PageCtrl'
    abstract: true
    ncyBreadcrumb:
      label: 'Страницы'
    resolve:
      menu: ['Page', (Page) ->
        Page.menu().$promise
      ]

      forms: ['Form', (Form) ->
        Form.query().$promise
      ])

  .state('pages.index',
    url: ''
    templateUrl: '/cms/partials/pages/show.html'
    controller: 'PageShowCtrl'
    ncyBreadcrumb:
      label: 'Страницы'
    resolve:
      page: ['Page'
      (Page) ->
        Page.getHomePage().$promise
      ]
      versions: ['Page', 'page',
      (Page, page) ->
        Page.getVersions pageId: page._id
      ])

  .state('pages.new',
    url: '/new'
    templateUrl: '/cms/partials/pages/create.html'
    controller: 'PageCreateCtrl'
    ncyBreadcrumb:
      label: 'Новая страница'
      parent: 'pages.index')

  # pages with only names and links are called menu items.
  # they are created and edited on diffirent router from pages
  .state('pages.newMenuItem',
    url: '/newmenu'
    templateUrl: '/cms/partials/menu-item/create.html'
    controller: 'MenuItemCreateCtrl'
    ncyBreadcrumb:
      label: 'Новый пункт меню'
      parent: 'pages.index')

  .state('pages.showMenuItem',
    url: '/:pageId/menuItem'
    templateUrl: '/cms/partials/menu-item/show.html'
    controller: 'MenuItemShowCtrl'
    ncyBreadcrumb:
      label: '{{menuItem.title}}'
      parent: 'pages.index')

  .state('pages.show',
    url: '/:pageId'
    templateUrl: 'partials/pages/show.html'
    controller: 'PageShowCtrl'
    ncyBreadcrumb:
      label: '{{page.title}}'
      parent: 'pages.index'
    resolve:
      page: ['Page', '$stateParams'
      (Page, $stateParams) ->
        Page.get(pageId: $stateParams.pageId).$promise
      ]
      versions: ['Page', 'page',
      (Page, page) ->
        Page.getVersions pageId: page._id
      ]
  )

class PageCtrl
  @$inject: ['$scope', '$state', 'Page', 'menu']

  constructor: ($scope, $state, Page, menu) ->
    $scope.menu = menu

    $scope.changeHome = (homeId) ->
      Page.update {pageId: homeId}, {isstart: true}

    setDefaultHome = ->
      $scope.homeId = menu.children[0]._id
      Page.update {pageId: $scope.homeId}, {isstart: true}

    getHomeId = (parent) ->
      parent.children.reduce ((homeId, node) ->
        return homeId ||
          (if node.isstart then node._id else null) ||
          getHomeId(node) ||
          null
      ), null

    $scope.homeId = getHomeId($scope.menu)

    $scope.sortableOptions =
      connectWith: '.page-node'
      delay: 150
      placeholder: 'menu-placeholder'
      stop: (e, ui) ->
        unless ui.item.sortable.dropindex == undefined
          Page.updateMenu
            parent: ui.item.sortable.droptarget.data('node-id')
            child: ui.item.sortable.model._id

    $scope.updatePage = (page) ->
      Page.update pageId: page._id, page

    $scope.updateMenu = (parent, child, children) ->
      Page.updateMenu
        parent: parent
        child: child
        children: children

    $scope.nestedStyle = (menuItem) ->
      pathLength = menuItem.path.split('#').length
      'padding-left': "#{(pathLength-1)*10}px"

    this.refresh = ->
      $state.reload()

class PagesCreateCtrl
  @$inject: ['$scope', '$state', 'Page', 'menu',
    'Form', 'Backup', 'modelOptions']

  constructor: ($scope, $state, Page, menu,
  Form, Backup, modelOptions) ->
    $scope.modelOptions = modelOptions
    backup = Backup.restore('pages/new')
    $scope.newPage = backup || new Page(visible: true, menu: true)
    $scope.forms = Form.query()

    $scope.createPage = ->
      Page.save $scope.newPage, (newPage) ->
        menu.children.push(newPage)
        $scope.newPage = {}
        Backup.remove 'pages/new'
        $state.go('pages.index', {}, reload: true)

class PageShowCtrl
  @$inject: ['$scope', '$state', '$stateParams',
    'Page', 'Form', 'page', 'versions', 'Backup', 'modelOptions']

  constructor: ($scope, $state, $stateParams,
    Page, Form, page, versions, Backup, modelOptions) ->
    $scope.modelOptions = modelOptions
    $scope.initialBackup = {}
    $scope.currentVersion = {}
    $scope.forms = Form.query()
    $scope.page = page
    $scope.page.autosave ?= {}
    $scope.versions = versions

    ['body', 'title'].forEach (autosaveField) ->
      if $scope.page.autosave[autosaveField] == undefined
        $scope.page.autosave[autosaveField] = $scope.page[autosaveField]

    backup = Backup.restore("pages/#{page._id}")
    $scope.page = Backup.patchDoc($scope.page, backup)

    $scope.recyclePage = ->
      $scope.page.$recycle ->
        $scope.alerts.push
          msg: 'Страница помещена в корзину'
          type: 'success'
        $state.go('pages.index', {}, reload: true)

    $scope.changeVersion = ->
      for field, value of $scope.currentVersion
        unless field in ['_id', 'createdAt', 'updatedAt', '__v']
          $scope.page[field] = value

    updatePage = (callback) ->
      Page.update pageId: $scope.page._id, $scope.page, (updated) ->
        $scope.page.__v = updated.__v

    $scope.updatePage = ->
      updatePage (page) ->
        $scope.alerts.push
          msg: 'Страница успешно обновлена'
          type: 'success'

    $scope.publish = ->
      Page.publish {pageId: $scope.page._id}, $scope.page, ->
        Page.getVersions pageId: $scope.page._id, (versions) ->
          $scope.versions = versions

class MenuItemCreateCtrl
  @$inject: ['$scope', '$state', 'Page', 'menu']

  constructor: ($scope, $state, MenuItem, menu) ->
    $scope.newMenuItem = new MenuItem(
      visible: true
      menu: true
      isMenuItem: true)
    $scope.defaultSlugs =
      'Каталог': '/catalog'
      'Новости': '/news'
      'Отзывы': '/feedback'

    $scope.createMenuItem = ->
      MenuItem.save $scope.newMenuItem, (newMenuItem) ->
        menu.children.push(newMenuItem)
        $scope.newMenuItem = {}

        $state.go('pages.index')

class MenuItemShowCtrl
  @$inject: ['$scope', '$state', '$stateParams', 'Page']

  constructor: ($scope, $state, $stateParams, Page) ->
    $scope.menuItem = Page.get(pageId: $stateParams.pageId)
    $scope.defaultSlugs =
      'Каталог': '/catalog'
      'Новости': '/news'
      'Отзывы': '/feedback'

    $scope.recycleMenuItem = ->
      $scope.menuItem.$recycle ->
        $scope.alerts.push
          msg: 'Элемент меню помещен в корзину'
          type: 'success'
        $state.go('pages.index', {}, reload: true)

    updateMenuItem = (callback) ->
      Page.update pageId: $scope.menuItem._id, $scope.menuItem, callback

    $scope.updateMenuItem = ->
      updateMenuItem (menuItem) ->
        $scope.alerts.push
          msg: 'Элемент меню успешно обновлен'
          type: 'success'

start()
