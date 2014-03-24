model-factory
=============

A tool for building RESTful models for AngularJS

#### TODO
- docs
- examples
- add directives to handle supressing model changes from the view to the model
- suggestions?

### Design
This is a simple model factory built on top of [jmdobry's](https://github.com/jmdobry) awesome [angular-cache](https://github.com/jmdobry/angular-cache) and inspired by angular's [$resource](http://docs.angularjs.org/api/ngResource/service/$resource).

Currently you can build simple resources that support basic REST CRUD operations and will persist themselves in an angular-cache. This is great for low memory use because only one object exists in memory for each model loaded from the server. Any future requests to get that model will return the cached value helping with illusion of speed or if your model is needed by different controllers on the same page.

#### CAVEAT!
Because each model lives in the same place using angular's two way binding can lead to unforseen consequencs. Ex: a model is two way binded to an input with ng-model and displayed somewhere else on the page. Editing the input will cause the the other value to update immedietly but the server is still not updated. Sometimes this is what you want, sometimes it isn't. Make sure you understand what this means (visual aids to come).
