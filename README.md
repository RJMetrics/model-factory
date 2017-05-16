# model-factory

A tool for building RESTful models for AngularJS

## Developing

Install dependencies:

```bash
npm install
bower install
```

Build:

```bash
grunt build
```

Watch and run unit tests:

```bash
grunt dev
```

### TODO

- docs
- examples
- add directives to handle suppressing model changes from the view to the model
- suggestions?

## Design

This is a simple model factory inspired by angular's
[$resource](http://docs.angularjs.org/api/ngResource/service/$resource) and
built on top of [jmdobry's](https://github.com/jmdobry) awesome
[angular-cache](https://github.com/jmdobry/angular-cache).

The model factory builds simple resources that implement REST/CRUD functions
with the help of angular-cache. The model-factory creates a single point of
truth--all references to an instance point to the same object in memory no
matter how many requests you make. This cuts down on memory usage and ensures
that the model state is identical across all instances of the model in your
controllers. The model-factory also decreases time to render by returning a
cached value instead of making multiple requests.

### CAVEAT

Using angular's two-way binding can lead to unforeseen consequences because all
references to a model point to the same object in memory. Let's say a model is
bound to an input using ng-model and displayed somewhere else on the page.
Editing the input will cause the other value to update immediately. The server
instance of the model will only be updated by calling the model-factory's
create or save call. Make sure to keep this in mind while using the
model-factory in your app.  (visual aids to come).
