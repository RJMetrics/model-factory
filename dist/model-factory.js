var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

angular.module('rjmetrics.model-factory', ['ng', 'jmdobry.angular-cache']);

angular.module('rjmetrics.model-factory').directive("formSubmittee", [
  "$parse", "$exceptionHandler", function($parse, $exceptionHandler) {
    return {
      priority: 9000,
      restrict: "A",
      require: ['ngModel', '^form'],
      link: function(scope, elm, attrs, controllers) {
        var form, listener, modelGet, ngModel;
        ngModel = controllers[0];
        form = controllers[1];
        ngModel.$parsers.push(function(value) {
          if (value === ngModel.$modelValue) {
            ngModel.$setPristine();
          }
          return ngModel.$modelValue;
        });
        modelGet = $parse(attrs.ngModel);
        listener = scope.$on("formSubmitter-submit-" + form.$name, function() {
          ngModel.$modelValue = ngModel.$viewValue;
          modelGet.assign(scope, ngModel.$viewValue);
          return angular.forEach(ngModel.$viewChangeListeners, function(listener) {
            var e;
            try {
              return listener();
            } catch (_error) {
              e = _error;
              return $exceptionHandler(e);
            }
          });
        });
        return scope.$on("$destroy", listener);
      }
    };
  }
]);

angular.module('rjmetrics.model-factory').directive("formSubmitter", [
  "$parse", function($parse) {
    return {
      restrict: "A",
      require: 'form',
      link: function(scope, elm, attrs, form) {
        var fn;
        fn = $parse(attrs.formSubmitter);
        elm.on("submit", function(event) {
          return scope.$apply(function() {
            scope.$broadcast("formSubmitter-submit-" + form.$name);
            scope.$eval(attrs.formSubmitter);
            return form.$setPristine();
          });
        });
        return scope.$on("$destroy", function() {
          return elm.off("submit");
        });
      }
    };
  }
]);

angular.module('rjmetrics.model-factory').factory("modelFactory", [
  "$q", "$http", "$angularCacheFactory", function($q, $http, $angularCacheFactory) {
    var DEFAULT_CACHE_OPTIONS, DEFAULT_HTTP_OPTIONS;
    DEFAULT_CACHE_OPTIONS = {
      maxAge: 600000,
      recycleFreq: 300000,
      deleteOnExpire: 'aggressive'
    };
    DEFAULT_HTTP_OPTIONS = {};
    return function(url, options) {
      var Model, cacheOptions;
      if (options == null) {
        options = {};
      }
      cacheOptions = angular.extend({}, DEFAULT_CACHE_OPTIONS, options.cacheOptions);
      Model = (function() {
        var _addCollection, _addModel, _collectionLoaded, _getCollectionPromise, _getPromiseMap, _modelCache, _modelCollection, _removeModel, _updateModel;

        Model.httpConfig = angular.extend({}, options.httpConfig, DEFAULT_HTTP_OPTIONS);

        function Model(value) {
          this.$delete = __bind(this.$delete, this);
          this.$save = __bind(this.$save, this);
          this.$get = __bind(this.$get, this);
          angular.copy(value || {}, this);
          if (!_modelCache.get("" + this.id)) {
            _modelCache.put("" + this.id, this);
          }
        }

        _getPromiseMap = {};

        _getCollectionPromise = null;

        _modelCollection = [];

        _collectionLoaded = false;

        cacheOptions.onExpire = function(key, model) {
          var config;
          _modelCache.put(key, model);
          if (!_getPromiseMap[+key]) {
            config = angular.extend({}, this.httpConfig, {
              method: "GET",
              url: "" + url + "/" + key
            });
            return _getPromiseMap[+key] = $http(config).then(function(successResponse) {
              delete _getPromiseMap[+key];
              return _updateModel(successResponse.data);
            }, function(errorResponse) {
              delete _getPromiseMap[+key];
              return _removeModel(model);
            });
          }
        };

        _modelCache = $angularCacheFactory(url, cacheOptions);

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
            httpObject = angular.extend({}, Model.httpConfig, httpOptions, {
              method: 'GET',
              url: Model.url + "/" + modelId
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
            httpObject = angular.extend({}, Model.httpConfig, httpOptions, {
              method: 'GET',
              url: Model.url
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
          httpObject = angular.extend({}, this.httpConfig, httpOptions, {
            method: options.postSave ? "POST" : "PUT",
            url: this.url + "/" + model.id,
            data: model
          });
          return $http(httpObject).then(function(successResponse) {
            return _updateModel(successResponse.data);
          }, function(errorResponse) {
            return $q.reject(errorResponse);
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
          httpObject = angular.extend({}, Model.httpConfig, httpOptions, {
            method: 'POST',
            url: Model.url,
            data: modelData
          });
          return $http(httpObject).then(function(successResponse) {
            return _addModel(successResponse.data);
          }, function(errorResponse) {
            return $q.reject(errorResponse);
          });
        };

        Model["delete"] = function(model, httpOptions) {
          var httpObject;
          if (httpOptions == null) {
            httpOptions = {};
          }
          httpObject = angular.extend({}, Model.httpConfig, httpOptions, {
            method: 'DELETE',
            url: Model.url + "/" + model.id
          });
          return $http(httpObject).then(function(successResponse) {
            _removeModel(model);
            return successResponse;
          }, function(errorResponse) {
            return $q.reject(errorResponse);
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
