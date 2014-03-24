module.exports = function (grunt) {
  'use strict';
    // Project configuration
    grunt.initConfig({
      // Metadata
      pkg: grunt.file.readJSON('package.json'),
      banner: '/*! <%= pkg.name %> - v<%= pkg.version %> - ' +
          '<%= grunt.template.today("yyyy-mm-dd") %>\n' +
          '<%= pkg.homepage ? "* " + pkg.homepage + "\\n" : "" %>' +
          '* Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %>;' +
          ' Licensed <%= props.license %> */\n',
      // Task configuration
      uglify: {
        options: {
            banner: '<%= banner %>'
        },
        dist: {
            src: 'dist/modelFactory.js',
            dest: 'dist/<%= pkg.name %>.min.js'
        }
      },
      jshint: {
        options: {
            node: true,
            curly: true,
            eqeqeq: true,
            immed: true,
            latedef: true,
            newcap: true,
            noarg: true,
            sub: true,
            undef: true,
            unused: true,
            boss: true,
            eqnull: true,
            globals: {
                jQuery: true
            }
        },
        gruntfile: {
            src: 'gruntfile.js'
        }
      },
      watch: {
        gruntfile: {
            files: '<%= jshint.gruntfile.src %>',
            tasks: ['jshint:gruntfile']
        },
        coffee: {
            files: ['src/*.coffee'],
            tasks: 'coffee'
        },
        karma: {
          files: ['src/modelFactory.coffee', 'test/*Spec.coffee'],
          tasks: ['karma:unit:run']
        }
      },
      coffee: {
        options: {
            join: true
        },
        compile: {
            files: {
                'dist/modelFactory.js': ['src/*.coffee']
            }
        }
      },
      karma: {
        unit: {
          configFile: 'karma.conf.js',
          background: true
        }
      }
  });

  // These plugins provide necessary tasks
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-karma');

  // Default task
  grunt.registerTask('default', ['jshint', 'coffee', 'uglify']);
  grunt.registerTask('dev', ['karma:unit:start', 'watch']);
};