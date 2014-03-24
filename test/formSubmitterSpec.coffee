'use strict'

describe 'FormSubmitter Directive', ->

  scope = null
  elm = null
  changeFn = jasmine.createSpy("changeFn")

  beforeEach ->
    module('rjmetrics.model-factory')

  beforeEach inject(($rootScope, $compile) -> 
    elm = angular.element("""
      <div>
        <form name="testForm" form-submitter="changeFn()"></form>
      </div>""")

    scope = $rootScope.$new()
    $compile(elm)(scope)
    scope.$apply()
  )

  afterEach ->
    scope.$destroy()
    
  it "should broadcast the proper angular event and eval the attribute value on submit event", ->
    scopeEvent = jasmine.createSpy("scopEvent")

    scope.$apply ->
      scope.changeFn = changeFn

    scope.$on "formSubmitter-submit-testForm", scopeEvent

    elm.find("form").eq(0).triggerHandler('submit')

    expect(scopeEvent).toHaveBeenCalled()
    expect(changeFn).toHaveBeenCalled()