# To be used with formSubmittee. This directive listens for a submit event
# and then broadcasts the formSubmitter-submit-#{form.$name} event down the angular scope
# so formSubmittee can work properly. It needs to be attached to a form element.
angular.module('rjmetrics.model-factory').directive "formSubmitter", [
  "$parse"
  ($parse) ->
    restrict: "A"
    require: 'form'
    link: (scope, elm, attrs, form) ->
      fn = $parse(attrs.formSubmitter)
      elm.on "submit", (event) ->
        scope.$apply ->
          scope.$broadcast("formSubmitter-submit-#{form.$name}")
          scope.$eval attrs.formSubmitter
          form.$setPristine()

      scope.$on "$destroy", () ->
        elm.off "submit"
]