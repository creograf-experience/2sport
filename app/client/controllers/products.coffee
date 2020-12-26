start = ->
  angular.module('VitalCms.controllers.products', ['ui.select'])
    .config(['$stateProvider', productConfig])
    .controller('ProductListCtrl', ProductListCtrl)
    .controller('ProductCreateCtrl', ProductCreateCtrl)
    .controller('ProductCtrl', ProductCtrl)
    .controller('ProductDetailsCtrl', ProductDetailsCtrl)
    .controller('ProductPropertiesCtrl', ProductPropertiesCtrl)
    .controller('ProductImagesCtrl', ProductImagesCtrl)

productConfig = ($stateProvider) ->
  $stateProvider
    .state('products'
      url: '/products'
      abstract: true
      template: '<ui-view>'
      resolve:
        categories: ['Category', (Category) ->
          Category.query().$promise
        ]
        forms: ['Form', (Form) ->
          Form.query().$promise
        ]
        properties: ['ProductProperty', (ProductProperty) ->
          ProductProperty.query().$promise
        ])

    .state('products.index'
      url: ''
      templateUrl: '/cms/partials/products/index.html'
      controller: 'ProductListCtrl'
      ncyBreadcrumb:
        label: 'Товары')

    .state('products.new'
      url: '/new'
      templateUrl: '/cms/partials/products/create.html'
      controller: 'ProductCreateCtrl'
      ncyBreadcrumb:
        label: 'Новый товар'
        parent: 'products.index')

    .state('products.show'
      url: '/:productId'
      templateUrl: '/cms/partials/products/product.html'
      abstract: true
      controller: 'ProductCtrl'
      resolve:
        product: ['Product', '$stateParams', (Product, $stateParams) ->
          promise = Product.get(productId: $stateParams.productId).$promise
          promise.then (product) -> product.price = product.price / 100
          return promise
        ])

    .state('products.show.details'
      url: ''
      templateUrl: '/cms/partials/products/details.html'
      controller: 'ProductDetailsCtrl'
      ncyBreadcrumb:
        label: '{{product.title}}'
        parent: 'products.index')

    .state('products.show.properties'
      url: '/properties'
      templateUrl: '/cms/partials/products/properties.html'
      controller: 'ProductPropertiesCtrl'
      ncyBreadcrumb:
        label: 'Свойства'
        parent: 'products.show.details({productId: product._id})')

    .state('products.show.images'
      url: '/images'
      templateUrl: '/cms/partials/products/images.html'
      controller: 'ProductImagesCtrl'
      ncyBreadcrumb:
        label: 'Изображения'
        parent: 'products.show.details({productId: product._id})')

class ProductListCtrl
  @$inject: ['$scope', 'Product', 'vitTableParams']

  constructor: ($scope, Product, vitTableParams) ->
    $scope.products = Product.query ->
      $scope.tableParams.reload()

    $scope.updateFilter = ->
      if $scope.products.$resolved
        $scope.tableParams.reload()

    $scope.tableParams = vitTableParams(
      $scope.products
      $scope.globalFilter
      title: 'desc')

    $scope.recycleProduct = (product) ->
      index = $scope.products.indexOf(product)

      product.$recycle ->
        $scope.products.splice index, 1
        $scope.alerts.push
          msg: 'Товар помещен в корзину'
          type: 'success'

    $scope.updateProduct = (product) ->
      Product.update productId: product._id, product

class ProductCreateCtrl
  @$inject: ['$scope', '$state', 'Product',
    'categories', 'Backup', 'modelOptions']

  constructor: ($scope, $state, Product,
  categories, Backup, modelOptions) ->
    backup = Backup.restore('products/new')
    $scope.categories = categories
    $scope.newProduct = new Product(
      visible: true
      categories: []
      categoriesTitles: [])
    $scope.modelOptions = modelOptions

    $scope.createProduct = ->
      Product.save $scope.newProduct, (createdProduct) ->
        $scope.newProduct = {}
        Backup.remove 'products/new'

        if createdProduct && createdProduct._id
          $state.go('products.show.details', productId: createdProduct._id)
        else
          $state.go('products.index')

    $scope.addCategory = (category) ->
      cat = _.chain(categories)
        .find _id: category._id
        .pick ['_id', 'title', 'path', 'slug']
        .value()
      $scope.newProduct.categories.push cat

    $scope.removeCategory = (category) ->
      filtered = _.reject $scope.newProduct.categories, catId: category._id
      $scope.newProduct.categories = filtered

    $scope.nestedStyle = (category) ->
      pathLength = category.path.split('#').length
      'padding-left': "#{(pathLength-1)*10}px"

    $scope.storeBackup = ->
      Backup.store 'products/new', $scope.newProduct

    setInterval $scope.storeBackup, 2000

class ProductCtrl
  @$inject: ['$scope', 'modelOptions', '$location', 'product']

  constructor: ($scope, modelOptions, $location, product) ->
    $scope.modelOptions = modelOptions
    $scope.product = product

    $scope.recycleProduct = ->
      $scope.product.$recycle ->
        $scope.alerts.push
          msg: 'Товар помещен в корзину'
          type: 'success'
        $location.path('/products')

class ProductDetailsCtrl
  @$inject: ['$scope', '$timeout', '$stateParams', '$location', 'Product'
    'product', 'categories', 'modelOptions', 'forms']

  constructor: ($scope, $timeout, $stateParams, $location, Product
    product, categories, modelOptions, forms) ->
    $scope.modelOptions = modelOptions
    $scope.product = product
    $scope.categories = categories
    $scope.forms = forms
    $scope.categoriesTitles = product.categories.slice()
    $scope.relatedTitles = product.related.slice()
    $scope.relatedProducts = []

    $scope.nestedStyle = (category) ->
      pathLength = category.path.split('#').length
      'padding-left': "#{(pathLength-1)*10}px"

    $scope.publish = ->
      Product.publish {productId: $scope.product._id}, $scope.product

    $scope.updateProduct = ->
      productCents = _.omit angular.copy($scope.product), ['related', 'categories']
      productCents.price = +$scope.product.price * 100
      Product.update productId: $scope.product._id, productCents, (updated) ->
        $scope.product.__v = updated.__v
        $scope.alerts.push
          msg: 'Товар успешно обновлен'
          type: 'success'

    $scope.addCategory = (category) ->
      Product.addCategory {productId: product._id}, {catId: category._id}

    $scope.removeCategory = (category) ->
      Product.removeCategory productId: product._id, catId: category._id

    $scope.refreshRelated = (query) ->
      return unless query
      $scope.relatedProducts = Product.search q: query

    $scope.addRelated = (related) ->
      Product.addRelated {productId: product._id}, {relatedId: related._id}

    $scope.removeRelated = (related) ->
      Product.removeRelated productId: product._id, relatedId: related._id

    $scope.relatedFilter = (related) ->
      selected = _.map($scope.product.related, '_id').concat([product._id])
      !(related._id in selected)

class ProductImagesCtrl
  @$inject: ['$scope', 'Product']

  constructor: ($scope, Product) ->
    $scope.Product = Product

class ProductPropertiesCtrl
  @$inject: ['$scope', '$filter', 'Product', 'product', 'properties']

  constructor: ($scope, $filter, Product, product, properties) ->
    $scope.product = product
    $scope.product.properties ?= []

    $scope.newProperty = {}

    countUnusedProps = ->
      productIds = _.map $scope.product.properties, '_id'
      $scope.unusedProps = _.remove properties.slice(), (prop) ->
        !(prop._id in productIds)

    countUnusedProps()

    $scope.sortableOptions =
      delay: 150
      stop: (e, ui) ->
        unless ui.item.sortable.dropindex == undefined
          $scope.updateProduct()

    $scope.updateProduct = ->
      countUnusedProps()
      Product.update
        productId: $scope.product._id, _.pick($scope.product, 'properties'), (updated) ->
          $scope.product.__v = updated.__v

    $scope.deleteProperty = (index) ->
      deletedProp = $scope.product.properties[index]
      $scope.product.properties.splice index, 1

      $scope.updateProduct()

    $scope.addProperty = ->
      property = $scope.newProperty.property
      property.value = $scope.newProperty.value
      $scope.product.properties.push(property)
      $scope.newProperty = {}

      $scope.updateProduct()

start()
