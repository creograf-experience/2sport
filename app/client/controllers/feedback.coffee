start = ->
  angular.module('VitalCms.controllers.feedback', [])
    .config(['$stateProvider', feedbackConfig])
    .controller('FeedbackListCtrl', FeedbackListCtrl)
    .controller('FeedbackShowCtrl', FeedbackShowCtrl)

feedbackConfig = ($stateProvider) ->
  $stateProvider
    .state('feedback'
      url: '/feedback'
      templateUrl: '/cms/partials/feedback/index.html'
      controller: 'FeedbackListCtrl'
      ncyBreadcrumb:
        label: 'Отзывы')

    .state('feedbackShow'
      url: '/feedback/:feedbackId'
      templateUrl: '/cms/partials/feedback/show.html'
      controller: 'FeedbackShowCtrl'
      ncyBreadcrumb:
        label: '{{feedback.name || feedback.email}}'
        parent: 'feedback')


class FeedbackListCtrl
  @$inject: ['$scope', 'Feedback']

  constructor: ($scope, Feedback) ->
    $scope.feedbacks = Feedback.query()

    $scope.deleteFeedback = (feedback) ->
      index = $scope.feedbacks.indexOf(feedback)
      feedback.$delete ->
        $scope.feedbacks.splice index, 1

    $scope.updateFeedback = (feedback) ->
      Feedback.update {feedbackId: feedback._id}, {visible: feedback.visible}

class FeedbackShowCtrl
  @$inject: ['$scope', 'Feedback', '$stateParams']

  constructor: ($scope, Feedback, $stateParams) ->
    $scope.feedback = Feedback.get feedbackId: $stateParams.feedbackId

    $scope.updateFeedback = ->
      Feedback.update feedbackId: $scope.feedback._id, $scope.feedback, ->
        $scope.alerts.push
          type: 'success'
          msg: 'Отзыв обновлен'

start()
