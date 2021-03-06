# Development


## Setup

### Requirements

SnapEditor expects the following Ruby environment.

    Ruby 2.x

Actually I tested under 2.0.x but assume 2.1.x should work too.


### Git Submodules

Get all the submodules using git.

    git submodule update --init

### Bundle Install

Use

    bundle install


### CoffeeScript, NodeJS, and NPM

Note: Currently you must install coffee-script version 1.2.0 or else the
compile fails.

    sudo apt-get install nodejs npm -y
    sudo npm install -g coffee-script@1.2.0

  For other releases, take a look at this [post](http://www.opinionatedprogrammer.com/2010/12/installing-coffeescript-on-debian-or-ubuntu/)

For Windows:

Install node using the installer (I think) and then

    npm install -g coffee-script@1.2.0
    npm install -g requirejs


### Ruby and RubyGems

Ruby 2.0.x is used in this project.

To install Ruby and RubyGems, take a look at [rbenv](https://github.com/sstephenson/rbenv) or [rvm](https://rvm.beginrescueend.com/).

### Bundler

Bundler 1.0.21 is used. The following command was used to install the required gems.

    bundle install --path vendor/bundle


### Jasmine

For testing, the project uses Jasmine, Jasmine-Guard and JasmineRice.


### Markdown

This project uses markdown.

    sudo apt-get install markdown


## Compiling

### CoffeeScript

All SnapEditor code is written in the `coffeescripts/` directory. These files are compiled into JavaScript and placed in the `javascripts/` directory;
however, the `javascripts/` directory is not version controlled.


### Guard

Guard is used for continuous compiling. It listens to the `coffeescripts/` directory for any changes. If there is, it will compile the CoffeeScript file into a JavaScript file and place it in `javascripts/`. Use the following command to run Guard.

    bundle exec guard start


### Rake

A rake task is provided for compiling.

    rake compile

## Running Tests

### jasmine-headless-webkit

The Jasmine specs are written in CoffeeScript. Use the following command to compile and run them manually.

    bundle exec jasmine-headless-webkit

### Guard

Guard is used for continuous testing. It watches for any changes to JavaScript files in the `javascripts/` directory, CoffeeScript files in the `spec/` directories, and `spec/javascripts/support/jasmine.yml`. Use the following command to run Guard.

    bundle exec guard start

### Browser Completeness

This runs the tests only in WebKit. It is a good idea to test in all browsers, including a non-headless WebKit. A rackup file has been provided.

    rackup config.ru

You can now point your browser to `locahost:9292` and the Jasmine specs will run.

### Configuration

If you would like to configure which specs to run, you can modify `spec/javascripts/support/jasmine.yml`. Look for the `spec_files` property.

### Acceptance Tests

Although automated tests are preferred, the editor requires a lot of actions that simply can't be automated.

The `spec/acceptance/` contains two files: `dev.html` and `test.html`. These contain both the form and inline editor for testing purposes.

`dev.html` sources `build/snapeditor.js` which changes whenever any CoffeeScript files are modified. This is used during development.

`test.html` sources `spec/acceptance/assets/javascripts/snapeditor.js` which does not change unless it gets overwritten. This is meant to be used during testing.

A rake task has been provided to generate `spec/acceptance/assets/javascripts/snapeditor.js`.

    rake prepare:test

## Writing Tests

### Asynchronous it()

RequireJS loads files asynchronously. However, Jasmine runs its tests immediately. Therefore, the `it()` function does not give RequireJS the chance to load any files.

Changes have been made to RequireJS in the tests in order to load files synchronously. These changes can be found in

    spec/javascripts/support/cs.custom.js
    spec/javascripts/support/require.custom.coffee

### Notes

#### jQuery

SnapEditor is written using a custom jQuery (`javascripts/jquery.custom.coffee`). If the tests used the default jQuery (`lib/jquery.js`), we would be mixing different jQuerys. In most cases, this mixing does not cause problems.

However, listening to and triggering events from different jQuerys causes problems. Triggering an event from one jQuery does not trigger the eventHandler in another jQuery.

    # example.coffee
    define ["jquery.custom"], ($) ->
      # $ is the custom jQuery
      return {
        element: (el) -> $(el).on("click", -> console.log("CLICK"))
        jQueryElement: ($el) -> $el.on("click", -> console.log("CLICK"))
      }

    # example_without_custom_jquery.spec.coffee
    require ["example"], (Example) ->
      describe "Example", ->
        # The default jQuery is used in the test and the custom jQuery is used
        # inside the function.
        it "doesn't log CLICK when using different jQuerys", ->
          # $ is the default jQuery
          $el = $("<div/>")
          Example.element($el[0])
          # CLICK is not logged
          $el.trigger("click")

        # The default jQuery is used in the test and inside the function.
        it "logs CLICK when using the same default jQuery", ->
          # $ is the default jQuery
          $el = $("<div/>")
          Example.jQueryElement($el)
          # CLICK is logged
          $el.trigger("click")

    # example_with_custom_jquery.spec.coffee
    require ["jquery.custom", "example"], ($, Example) ->
      # The custom jQuery is used in the test and inside the function.
      it "logs CLICK when using the same custom jQuery", ->
        # $ is the custom jQuery
        $el = $("<div/>")
        Example.element($el[0])
        # CLICK is logged
        $el.trigger("click")

In order to keep things consistent, always require `jquery.custom`. This guarantees that the tests will be using the custom jQuery and so everything will be using the same jQuery.

# Building

## SnapEditor

The beginning of the build starts at `javascripts/snapeditor.js`. It is the start of all the requires.

## Build File

`build/` contains all the necessary files for building SnapEditor. `build.js` has been provided as a profile for building SnapEditor using `r.js`. Use the following command to use `r.js`.

    node r.js -o build.js

## Guard

Whenever there are changes to the `javascripts/` directory, the build is invoked.

## Rake

Two rake tasks have been created to aid in building.

    rake build            # builds snapeditor.js without compiling
    rake compileAndBuild  # compile and build snapeditor.js

# Bundling

## Rake

A rake task is provided for bundling SnapEditor.

    rake prepare:bundle
