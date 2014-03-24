'use strict'

describe 'FormSubmittee Directive', ->

  scope = null
  elm = null
  changeFn = jasmine.createSpy("changeFn")

  beforeEach ->
    module('rjmetrics.model-factory')

  beforeEach inject(($rootScope, $compile) -> 
    elm = angular.element("""
      <div>
        <form name="testForm">
          <input type="text" ng-model="test" form-submittee ng-change="changeFn()"></input>
        </form>
      </div>""")

    scope = $rootScope.$new()
    $compile(elm)(scope)
    scope.$apply()
  )

  afterEach ->
    scope.$destroy()
    
  it "should only change the model or trigger the changeFn when the correct angular event is triggered", ->
    scope.$apply ->
      scope.test = "testValue"
      scope.changeFn = changeFn

    expect(elm.find('input').eq(0).val()).toEqual("testValue")
    
    elm.find('input').eq(0).val("changedValue")
    elm.find('input').eq(0).triggerHandler("input")
    
    expect(elm.find('input').eq(0).val()).toEqual("changedValue")
    expect(scope.test).toEqual("testValue")
    expect(changeFn).not.toHaveBeenCalled()

    scope.$emit("formSubmitter-submit-testForm")

    expect(elm.find('input').eq(0).val()).toEqual("changedValue")
    expect(scope.test).toEqual("changedValue")
    expect(changeFn).toHaveBeenCalled()