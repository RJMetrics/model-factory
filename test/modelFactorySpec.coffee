'use strict'

describe 'Model Factory', ->
 


  modelList = [
      id: 1
      name: "model1"
    ,
      id: 2
      name: "model2"
    ,
      id: 3
      name: "model3"
    ]
  modelUrl = "test.com/model/"
  modelFactory = null
  httpBackend = null
  angularCache = null
  rootScope = null

  beforeEach ->
    module('rjmetrics.model-factory')

  beforeEach inject (_modelFactory_, _$httpBackend_, _$angularCacheFactory_, _$rootScope_) ->
    modelFactory = _modelFactory_
    httpBackend = _$httpBackend_
    angularCache = _$angularCacheFactory_
    rootScope = _$rootScope_

  afterEach ->
    angularCache.get(modelUrl).destroy()
    httpBackend.verifyNoOutstandingRequest()

  it "instantiats a model correctly", ->
    Model = modelFactory(modelUrl)
    #ensure static functions are defined
    expect(Model.url).toBe(modelUrl)
    expect(Model.get).toBeDefined()
    expect(Model.getCollection).toBeDefined()
    expect(Model.save).toBeDefined()
    expect(Model.create).toBeDefined()
    expect(Model.delete).toBeDefined()
    #ensure the cache was initialized
    expect(angularCache.get(modelUrl)).toBeDefined()
    #ensure the instance functions exist
    expect(Model::$get).toBeDefined()
    expect(Model::$save).toBeDefined()
    expect(Model::$delete).toBeDefined()

    model = new Model()
    expect(model instanceof Model).toBeTruthy()
    
  it "gets a model and stores it in the cache", ->
    httpBackend.expectGET(new RegExp("#{modelUrl}1"))
    .respond 200, modelList[0]

    Model = modelFactory(modelUrl)
    aModel = null
    Model.get(1).then (m) -> aModel = m

    httpBackend.flush()

    expect(aModel instanceof Model).toBeTruthy();
    for key, value of aModel
      if not angular.isFunction value
        expect(value).toBe(modelList[0][key])
        expect(angularCache.get(modelUrl).get("#{aModel.id}")[key]).toBe(modelList[0][key])

    aModel2 = null
    aModel.$get().then (m) -> aModel2 = m

    rootScope.$apply()
    expect(aModel2).toBe(aModel)

  it "gets a model, sending appropriate parameters in the get request via httpOptions", ->
    httpBackend.expectGET("#{modelUrl}1?data=true&query=true")
    .respond 200, modelList[0]

    httpOptions = 
      params:
        data: true
        query: true

    Model = modelFactory(modelUrl)
    aModel = null
    Model.get(1, false, httpOptions)
    .then (m) ->
      aModel = m

    httpBackend.flush()

    # Make sure the object ins
    httpBackend.expectGET("#{modelUrl}1?data=true&query=true")
    .respond 200, modelList[0]

    aModel2 = null
    aModel.$get(true, httpOptions).then (m) -> aModel2 = m

    httpBackend.flush()

    expect(aModel2).toBe(aModel)

  it "gets a collection of models and stores them in the cache", ->
    httpBackend.expectGET(new RegExp("#{modelUrl}1"))
    .respond 200, modelList[0]

    httpBackend.expectGET(new RegExp("#{modelUrl}"))
    .respond 200, modelList

    Model = modelFactory(modelUrl)

    Model.get(1)

    collection = null
    Model.getCollection().then (m) -> collection = m

    httpBackend.flush()

    expect(collection instanceof Array).toBeTruthy()
    for model, index in collection
      expect(model instanceof Model).toBeTruthy()
      for key, value of model
        if not angular.isFunction value
          expect(value).toBe(modelList[index][key])
          expect(angularCache.get(modelUrl).get("#{model.id}")[key]).toBe(modelList[index][key])

    collection2 = null
    Model.getCollection().then (m) -> collection2 = m

    rootScope.$apply() 

    expect(collection2).toBe(collection)

  it "passes httpOptions along with the get request in getCollection", ->
    httpBackend.expectGET("#{modelUrl}?data=true&query=true")
    .respond 200, modelList

    Model = modelFactory(modelUrl)

    collection = null
    Model.getCollection false,
      params:
        data: true
        query: true

    httpBackend.flush()

  it "create a model and save it to the back end", ->
    backendModel = 
      id: 5
      name: "model5"
    httpBackend.expectPOST(new RegExp("#{modelUrl}"))
    .respond 200, backendModel

    modelData = 
      name: "model5"

    Model = modelFactory(modelUrl)
    aModel = null
    Model.create(modelData).then (m) -> aModel = m

    httpBackend.flush()

    expect(aModel instanceof Model).toBeTruthy()
    expect(aModel.id).toBe(backendModel.id)
    expect(aModel.name).toBe(backendModel.name)

  it "creates a model, passing httpOptions appropriately", ->
    backendModel = 
      id: 5
      name: "model5"

    modelData =
      name: "model5"

    httpBackend.expectPOST("#{modelUrl}", undefined, {"Authorization":"12345==","Accept":"application/json, text/plain, */*","Content-Type":"application/json;charset=utf-8"}
    ).respond 200, backendModel

    Model = modelFactory(modelUrl)
    Model.create modelData,
      headers:
        'Authorization': '12345=='
   

    httpBackend.flush()



  it "saves an existing model to the backend using static method", ->
    backendModel = 
      id: 5
      name: "model5"
    httpBackend.expectPOST(new RegExp("#{modelUrl}5"))
    .respond 200, backendModel

    Model = modelFactory(modelUrl)

    aModel = new Model
      id: 5
      name: "model5"
    
    Model.save(aModel)

    httpBackend.flush()

    expect(aModel instanceof Model).toBeTruthy()
    expect(aModel.id).toBe(backendModel.id)
    expect(aModel.name).toBe(backendModel.name)

    httpBackend.expectPOST(new RegExp("#{modelUrl}5"))
    .respond 200, backendModel

    aModel2 = null
    aModel.$save().then (m) -> 
      aModel2 = m

    httpBackend.flush()

    expect(aModel2).toBe(aModel)

  it "saves an existing model, passing httpOptions appropriately", ->
    backendModel = 
      id: 5
      name: "model5"

    Model = modelFactory(modelUrl)

    aModel = new Model
      id: 5
      name: "model5"

    httpBackend.expectPOST("#{modelUrl}5", aModel, {"Authorization":"12345==","Accept":"application/json, text/plain, */*","Content-Type":"application/json;charset=utf-8"}
    ).respond 200, backendModel

    httpOptions = 
      headers:
        'Authorization': '12345=='

    Model.save(aModel, httpOptions)

    httpBackend.flush()

    # Ensure that the instance function also allows passing httpOptions.
    httpBackend.expectPOST("#{modelUrl}5", aModel, {"Authorization":"12345==","Accept":"application/json, text/plain, */*","Content-Type":"application/json;charset=utf-8"}
    ).respond 200, backendModel

    aModel.$save(httpOptions)

    httpBackend.flush()

  it "should call the static method when the instance save method is called", ->
    Model = modelFactory(modelUrl)

    aModel = new Model
      id: 5
      name: "model5"
    saveSpy = spyOn(aModel, "$save")
    aModel.$save()

    expect(saveSpy).toHaveBeenCalled()

  it "creates a model, saves it to the backend and puts it in the cache and collection", ->
    backendModel = 
      id: 5
      name: "model5"
    httpBackend.expectPOST(new RegExp("#{modelUrl}"), name: "model5")
    .respond 200, backendModel

    Model = modelFactory(modelUrl)

    aModel = null
    Model.create
      name: "model5"
    .then (m) -> aModel = m

    httpBackend.flush()

    expect(aModel instanceof Model).toBeTruthy()
    expect(aModel.id).toBe(backendModel.id)
    expect(aModel.name).toBe(backendModel.name)
    expect(angularCache.get(modelUrl).get("#{aModel.id}").id).toBe(backendModel.id)

  it "deletes a model and removes it from the cache and collection", ->
    backendModel = 
      id: 5
      name: "model5"
    httpBackend.expectPOST(new RegExp("#{modelUrl}"), name: "model5")
    .respond 200, backendModel

    Model = modelFactory(modelUrl)

    aModel = null
    Model.create
      name: "model5"
    .then (m) -> aModel = m

    httpBackend.flush()

    httpBackend.expectDELETE(new RegExp("#{modelUrl}5"))
    .respond 200

    aModel.$delete()

    httpBackend.flush()

  it "deletes a model, setting httpOptions appropriately", ->
    backendModel = 
      id: 5
      name: "model5"
    httpBackend.expectPOST(new RegExp("#{modelUrl}"))
    .respond 200, backendModel

    modelData = 
      id: 5
      name: "model5"

    Model = modelFactory(modelUrl)

    aModel = null
    Model.create
      name: "model5"
    .then (m) -> aModel = m

    httpBackend.flush()

    httpBackend.expectDELETE(new RegExp("#{modelUrl}5"), {"Authorization":"12345==","Accept":"application/json, text/plain, */*"}
    ).respond 200

    Model.delete modelData, 
      headers:
        'Authorization': '12345=='

    httpBackend.flush()

    #Make sure the instance method version works as well.
    httpBackend.expectPOST(new RegExp("#{modelUrl}"))
    .respond 200, backendModel

    aModel = null
    Model.create
      name: "model5"
    .then (m) -> aModel = m

    httpBackend.flush()

    httpBackend.expectDELETE(new RegExp("#{modelUrl}5"), {"Authorization":"12345==","Accept":"application/json, text/plain, */*"}
    ).respond 200

    aModel.$delete({headers: 'Authorization': '12345=='})

    httpBackend.flush()

  it "throws an error when the object passed to save does not have an id", ->
    Model = modelFactory modelUrl
    aModel = {}
    expect( () -> Model.save(aModel)).toThrow(new Error("Model must have an id property to be saved"))

  it "throws an error when trying to create an object with an id already set", ->
    Model = modelFactory modelUrl
    aModel =
      id: 1
    expect( () -> Model.create(aModel)).toThrow(new Error("Can not create new model that already has an id set"))

  it "uses the same promise while waiting for the backend to return a get request", ->
    httpBackend.expectGET(new RegExp("#{modelUrl}1"))
      .respond 200, modelList[0]

    httpBackend.expectGET(new RegExp("#{modelUrl}2"))
      .respond 200, modelList[1]

    httpBackend.expectGET(new RegExp("#{modelUrl}"))
      .respond 200, modelList

    Model = modelFactory modelUrl

    promise1 = Model.get(1)
    promise2 = Model.get(1)

    promise3 = Model.get(2)
    promise4 = Model.get(2)

    promise5 = Model.getCollection()
    promise6 = Model.getCollection()

    expect(promise1).toBe(promise2)
    expect(promise3).toBe(promise4)
    expect(promise5).toBe(promise6)

    httpBackend.flush()

  it "expires and refreshes or removes the object from the cache", ->
    aModel = null
    Model = modelFactory modelUrl, 
        maxAge: 50
        recycleFreq: 1
    runs ->
      httpBackend.expectGET(new RegExp("#{modelUrl}1"))
        .respond 200, modelList[0]

      Model.get(1).then (m) -> aModel = m

      httpBackend.flush()

      newModel = angular.copy modelList[0]
      newModel.name = "updated"

      httpBackend.expectGET(new RegExp("#{modelUrl}1"))
      .respond 200, newModel

    waits(200)

    runs ->
      httpBackend.flush()

      aModel2 = null
      Model.get(1).then (m) -> aModel2 = m

      rootScope.$apply()

      expect(aModel2.name).toBe("updated")
      expect(aModel.id).toBe(aModel2.id)

      httpBackend.expectGET(new RegExp("#{modelUrl}1"))
        .respond 404

    waits(200)

    runs ->

      httpBackend.flush()

      httpBackend.expectGET(new RegExp("#{modelUrl}1"))
        .respond 404

      error = null;
      Model.get(1).then null, (e) -> error = e

      httpBackend.flush()

      expect(error.status).toBe(404)


