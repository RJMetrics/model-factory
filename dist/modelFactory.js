(function() {
  angular.module('rjmetrics.model-factory', ['ng', 'jmdobry.angular-cache']).factory("modelFactory", [
    "$q", "$http", "$angularCacheFactory", function($q, $http, $angularCacheFactory) {
      var DEFAULT_OPTIONS;
      DEFAULT_OPTIONS = {
        maxAge: 600000,
        recycleFreq: 300000,
        deleteOnExpire: 'aggressive'
      };
      return function(url, options) {
        var Model;
        options = angular.extend({}, DEFAULT_OPTIONS, options);
        Model = (function() {
          var _addCollection, _addModel, _collectionLoaded, _getCollectionPromise, _getPromiseMap, _modelCache, _modelCollection, _removeModel, _updateModel;

          function Model(value) {
            angular.copy(value || {}, this);
            if (!_modelCache.get("" + this.id)) {
              _modelCache.put("" + this.id, this);
            }
          }

          _getPromiseMap = {};

          _getCollectionPromise = null;

          _modelCollection = [];

          _collectionLoaded = false;

          options.onExpire = function(key, model) {
            _modelCache.put(key, model);
            if (!_getPromiseMap[+key]) {
              return _getPromiseMap[+key] = $http.get(url + key).then(function(successResponse) {
                delete _getPromiseMap[+key];
                return _updateModel(successResponse.data);
              }, function(errorResponse) {
                delete _getPromiseMap[+key];
                return _removeModel(model);
              });
            }
          };

          _modelCache = $angularCacheFactory(url, options);

          _addModel = function(modelData) {
            var model;
            model = new Model(modelData);
            _modelCollection.push(model);
            return model;
          };

          _updateModel = function(modelData) {
            var model;
            model = _modelCache.get("" + modelData.id);
            if (!angular.equals(model, modelData)) {
              angular.copy(modelData, model);
            }
            if (!_(_modelCollection).contains(model)) {
              _modelCollection.push(model);
            }
            return model;
          };

          _addCollection = function(collection) {
            _(collection).each(function(model) {
              if (_modelCache.get("" + model.id)) {
                return _updateModel(model);
              } else {
                return _addModel(model);
              }
            });
            return _modelCollection;
          };

          _removeModel = function(model) {
            if (_modelCollection.length > 0) {
              _modelCollection.splice(_modelCollection.indexOf(model), 1);
            }
            _modelCache.remove("" + model.id);
          };

          Model.url = url;

          Model.get = function(modelId, forceGet, httpOptions) {
            var deferred, httpObject, model;
            if (forceGet == null) {
              forceGet = false;
            }
            if (httpOptions == null) {
              httpOptions = {};
            }
            if (_getPromiseMap[modelId] != null) {
              return _getPromiseMap[modelId];
            }
            deferred = $q.defer();
            model = _modelCache.get("" + modelId);
            if (!forceGet && (model != null)) {
              deferred.resolve(model);
            } else {
              _getPromiseMap[modelId] = deferred.promise;
              httpObject = angular.extend({}, httpOptions, {
                method: 'GET',
                url: this.url + modelId
              });
              $http(httpObject).then(function(successResponse) {
                if (_modelCache.get("" + modelId) != null) {
                  deferred.resolve(_updateModel(successResponse.data));
                } else {
                  deferred.resolve(_addModel(successResponse.data));
                }
                return delete _getPromiseMap[modelId];
              }, function(errorResponse) {
                deferred.reject(errorResponse);
                return delete _getPromiseMap[modelId];
              });
            }
            return deferred.promise;
          };

          Model.getCollection = function(forceGet, httpOptions) {
            var deferred, httpObject;
            if (forceGet == null) {
              forceGet = false;
            }
            if (httpOptions == null) {
              httpOptions = {};
            }
            if (_getCollectionPromise != null) {
              return _getCollectionPromise;
            }
            deferred = $q.defer();
            if (!forceGet && _collectionLoaded) {
              deferred.resolve(_modelCollection);
            } else {
              _collectionLoaded = true;
              _getCollectionPromise = deferred.promise;
              httpObject = angular.extend({}, httpOptions, {
                method: 'GET',
                url: this.url
              });
              $http(httpObject).then(function(successResponse) {
                deferred.resolve(_addCollection(successResponse.data));
                return _getCollectionPromise = null;
              }, function(errorResponse) {
                deferred.reject(errorResponse);
                return _getCollectionPromise = null;
              });
            }
            return deferred.promise;
          };

          Model.save = function(model, httpOptions) {
            var httpObject;
            if (httpOptions == null) {
              httpOptions = {};
            }
            if (model.id == null) {
              throw new Error("Model must have an id property to be saved");
            }
            httpObject = angular.extend({}, httpOptions, {
              method: 'POST',
              url: this.url + model.id,
              data: model
            });
            return $http(httpObject).then(function(successResponse) {
              return _updateModel(successResponse.data);
            }, function(errorResponse) {
              return errorResponse;
            });
          };

          Model.create = function(modelData, httpOptions) {
            var httpObject;
            if (httpOptions == null) {
              httpOptions = {};
            }
            if (modelData.id != null) {
              throw new Error("Can not create new model that already has an id set");
            }
            httpObject = angular.extend({}, httpOptions, {
              method: 'POST',
              url: this.url,
              data: modelData
            });
            return $http(httpObject).then(function(successResponse) {
              return _addModel(successResponse.data);
            }, function(errorResponse) {
              return errorResponse;
            });
          };

          Model["delete"] = function(model, httpOptions) {
            var httpObject;
            if (httpOptions == null) {
              httpOptions = {};
            }
            httpObject = angular.extend({}, httpOptions, {
              method: 'DELETE',
              url: this.url + model.id
            });
            return $http(httpObject).then(function(successResponse) {
              _removeModel(model);
              return successResponse;
            }, function(errorResponse) {
              return errorResponse;
            });
          };

          Model.prototype.$get = function(forceGet, httpOptions) {
            if (forceGet == null) {
              forceGet = false;
            }
            if (httpOptions == null) {
              httpOptions = {};
            }
            return Model.get(this.id, forceGet, httpOptions);
          };

          Model.prototype.$save = function(httpOptions) {
            if (httpOptions == null) {
              httpOptions = {};
            }
            return Model.save(this, httpOptions);
          };

          Model.prototype.$delete = function(httpOptions) {
            if (httpOptions == null) {
              httpOptions = {};
            }
            return Model["delete"](this, httpOptions);
          };

          return Model;

        })();
        return Model;
      };
    }
  ]);

}).call(this);
