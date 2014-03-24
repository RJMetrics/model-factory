angular.module('model-factory').factory("modelFactory", [
  "$q"
  "$http"
  "$angularCacheFactory"
  ($q, $http, $angularCacheFactory) ->
    #TODO: see if we should use local or session storage?
    DEFAULT_OPTIONS = 
      maxAge: 600000 # 10 minutes
      recycleFreq: 300000 # 5 minutes
      deleteOnExpire: 'aggressive' #remove items from the cache when they expire

    #Factory function that creates Model Services
    (url, options) ->
      options = angular.extend({}, DEFAULT_OPTIONS, options)

      class Model
        constructor: (value) ->
          angular.copy(value || {}, this)
          # if this model is not in the cache then add it
          unless _modelCache.get("#{@id}")
            _modelCache.put("#{@id}", this)
        # private attributes/functions
        _getPromiseMap = {}
        _getCollectionPromise = null
        _modelCollection = []
        _collectionLoaded = false
        #set up expire function. have to do it here so it can access private vars/functions
        options.onExpire = (key, model) ->
          # re-add the 'expired' model to the cache
          _modelCache.put(key, model)
          #if no current get is in progress go and update the model
          if not _getPromiseMap[+key] # check if a int key exists
            # get the most recent version of the model from the backend
            _getPromiseMap[+key] = $http.get(url+key) #note added the int key to the map
            .then (successResponse) ->
              delete _getPromiseMap[+key]
              return _updateModel(successResponse.data)
            , (errorResponse) ->
              # model was most likely removed so remove it from the cache
              delete _getPromiseMap[+key]
              return _removeModel(model)

        _modelCache = $angularCacheFactory url, options
        
        #add a model to the cache and collection
        _addModel = (modelData) ->
          model = new Model(modelData) #we are craeting a new model to add to the cache
          _modelCollection.push model
          return model

        # update a model in the cache
        _updateModel = (modelData) ->
          model = _modelCache.get "#{modelData.id}"
          if not angular.equals(model, modelData)
            angular.copy modelData, model
          #TODO: revist this to see if we can preserve the collection in sessionStorage
          if not _(_modelCollection).contains(model)
            _modelCollection.push(model)
          return model

        # add an array of modelData to the cache. calls _addModel or _updateModel for
        # for each model in the array depending if the models id is in the cache already
        _addCollection = (collection) ->
          # Add each model individually into the cache
          _(collection).each (model) ->
            if _modelCache.get("#{model.id}")
              _updateModel(model)
            else
              _addModel model

          return _modelCollection

        # remove a model from the cache and collection
        _removeModel = (model) ->
          if _modelCollection.length > 0
            _modelCollection.splice(_modelCollection.indexOf(model), 1)
          _modelCache.remove "#{model.id}"

          return

        @url: url

        # get a model from the backend and add it to the cache and collection array.
        # There are 4 ways to handle getting a model
        # case 1: a request for that particular model id is pending so return that promise
        # else we are always returning a new promise
        # case 2: the model has been loaded and we're not forcing a get so resolve that model
        # case 3: forceGet is true so go to the backend and get the model
        # case 4: the model is not in the cache so get it from the backend and resolve it
        # httpOptions is a list of options that can extend the $http.get request.
        @get = (modelId, forceGet=false, httpOptions={}) ->
          # case 1
          if _getPromiseMap[modelId]?
            return _getPromiseMap[modelId]
          
          deferred = $q.defer()
          model = _modelCache.get "#{modelId}"
          if not forceGet and model?
            deferred.resolve model # case 2
          else # case 3 and 4
            _getPromiseMap[modelId] = deferred.promise
            
            httpObject = angular.extend {}, httpOptions,
              method: 'GET'
              url: @url+modelId

            $http(httpObject)
            .then (successResponse) ->
              if _modelCache.get("#{modelId}")?
                deferred.resolve _updateModel(successResponse.data)
              else
                deferred.resolve _addModel(successResponse.data)
              delete _getPromiseMap[modelId]
            , (errorResponse) ->
              deferred.reject errorResponse
              delete _getPromiseMap[modelId]

          return deferred.promise

        # get all the models for this resource url and store them in the cache
        # and in the collection array. By passing true into the call it will force the collection
        # to refresh and match what is in the backend. 
        # There are 4 possible ways to handle getting a collection
        # case 1: a request is pending with the backend. return the existing promise
        # case 2: the collection has been loaded and we are not doing a force get return the collection array
        # case 4: forceGet is true so go to the backend and refresh what we have in the cache
        # case 3: we haven't loaded the collection yet so load it and add all models to the cache and collection array
        @getCollection = (forceGet = false, httpOptions={}) ->
          # case 1
          if _getCollectionPromise?
            return _getCollectionPromise

          deferred = $q.defer()
          # if we don't need to forceGet and the collection is loaded resolve
          # the collection
          if not forceGet and _collectionLoaded
            deferred.resolve(_modelCollection) # case 2
          else # case 3 and 4
            _collectionLoaded = true
            _getCollectionPromise = deferred.promise

            httpObject = angular.extend {}, httpOptions,
              method: 'GET'
              url: @url

            $http(httpObject)
            .then (successResponse) ->                
              deferred.resolve _addCollection(successResponse.data)
              _getCollectionPromise = null
            , (errorResponse) ->
              deferred.reject errorResponse
              _getCollectionPromise = null

          return deferred.promise

        # save the existing model to the backend and update the model in the
        # cache to match it
        @save = (model, httpOptions={}) ->
          unless model.id?
            throw new Error "Model must have an id property to be saved"

          httpObject = angular.extend {}, httpOptions,
            method: 'POST'
            url: @url + model.id
            data: 
              model

          $http(httpObject)
          .then (successResponse) ->
            # Now that we've saved the model add the updated model to the cached/collection
            return _updateModel successResponse.data
          , (errorResponse) ->
            return errorResponse

        # create a model on the backend from the data passed to this function 
        # and on success add it to the cache and return the created/cached model
        @create = (modelData, httpOptions={}) ->
          if modelData.id?
            throw new Error "Can not create new model that already has an id set"

          httpObject = angular.extend {}, httpOptions,
            method: 'POST'
            url: @url
            data:
              modelData

          $http(httpObject)
          .then (successResponse) ->
            # Now that we've created the model on the back end we need to
            # add the model into the modelCache and the collection.
            return _addModel successResponse.data
          , (errorResponse) ->
            return errorResponse

        # delete a model from the backend and on sucess remove it from the
        # modelCache
        @delete = (model, httpOptions={}) ->
          httpObject = angular.extend {}, httpOptions,
            method: 'DELETE'
            url: @url + model.id

          return $http(httpObject)
          .then (successResponse) ->
            _removeModel(model)
            return successResponse
          , (errorResponse) ->
            return errorResponse

        # instance methods that you can call on an instantiated model 
        # instead of using the static methods. They call the static
        # methods with the correct data.
        $get: (forceGet = false, httpOptions={}) ->
          return Model.get(@id, forceGet, httpOptions)

        $save: (httpOptions={}) ->
           return Model.save(this, httpOptions)

        $delete: (httpOptions={}) ->
          return Model.delete(this, httpOptions)

      return Model
  ]
)
