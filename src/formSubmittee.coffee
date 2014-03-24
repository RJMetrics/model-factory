# This function is intended to be used with ng-model inside a ng-form with formSubmitter.
# It delays updating the model ng-model refrencing until the form is submitted, breaking
# two way binding until the user actually wants the model value(s) updated. This allows cached models
# to be used in multiple places without having to worry about unsubmitted changes showing up in multiple places.
# It will also trigger all the ngModel.$viewChangeListeners such as ng-change.
angular.module('rjmetrics.model-factory').directive "formSubmittee", [
  "$parse"
  "$exceptionHandler"
  ($parse, $exceptionHandler) ->
    priority: 9000 # need to try and gaurentee the link function will go last
    restrict: "A"
    require: [
      'ngModel'
      '^form'
    ]
    link: (scope, elm, attrs, controllers) ->
      ngModel = controllers[0]
      form = controllers[1]

      # add a new 
      ngModel.$parsers.push (value) ->
        if value is ngModel.$modelValue
          ngModel.$setPristine()
        return ngModel.$modelValue

      modelGet = $parse(attrs.ngModel)

      listener = scope.$on "formSubmitter-submit-#{form.$name}", () ->
        ngModel.$modelValue = ngModel.$viewValue
        modelGet.assign(scope, ngModel.$viewValue)
        # need this to trigger any listeners such as ng-change
        angular.forEach ngModel.$viewChangeListeners, (listener) ->
          try
            listener()
          catch e
            $exceptionHandler e

      scope.$on "$destroy", listener
]