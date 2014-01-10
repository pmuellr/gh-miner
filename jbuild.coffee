# Licensed under the Apache License. See footer for details.

fs   = require "fs"
path = require "path"
zlib = require "zlib"

try
    require "./lib/XstackTrace"
catch e

tasks = exports

#-------------------------------------------------------------------------------

mkdir "-p", "tmp"

__basename    = path.basename __filename
ServerPidFile = "tmp/server.pid"
ServerCmd     = "node"
ServerArgs    = ["bin/gh-miner", "--verbose"]

#-------------------------------------------------------------------------------

angularVersion = "1.2.7"

BowerConfig =

    jquery:
        version:    "2.0.x"
        files:
                    "^.js":  "."

    bootstrap:
        version:    "3.0.x"
        files:
                    "css/^.min.css":                           "dist"
                    "css/^-theme.min.css":                     "dist"
                    "fonts/glyphicons-halflings-regular.eot":  "dist"
                    "fonts/glyphicons-halflings-regular.ttf":  "dist"
                    "fonts/glyphicons-halflings-regular.svg":  "dist"
                    "fonts/glyphicons-halflings-regular.woff": "dist"
                    "js/^.js":                                 "dist"

    angular:
        version:    angularVersion
        files:
                    "^.js": "."

    "angular-animate":
        version:    angularVersion
        files:
                    "^.js": "."

    "angular-cookies":
        version:    angularVersion
        files:
                    "^.js": "."

    "angular-resource":
        version:    angularVersion
        files:
                    "^.js": "."

    "angular-route":
        version:    angularVersion
        files:
                    "^.js": "."

    "angular-touch":
        version:    angularVersion
        files:
                    "^.js": "."

#-------------------------------------------------------------------------------

WatchConfig =
    run: -> buildNserve()
    files: """
        lib-src/**/*
        www-src/**/*
    """

WatchConfig.files = WatchConfig.files.trim().split(/\s+/)

#-------------------------------------------------------------------------------

GzipConfig = [
    /.*\.css$/
    /.*\.js$/
    /.*\.json$/
    /.*\.svg$/
]

#-------------------------------------------------------------------------------

build = ->
    log "starting build"

    cleanDir "lib"
    coffee "--output lib lib-src"

    cleanDir "www"
    cp "www-src/*.html", "www"
    cp "www-src/*.css",  "www"

    cleanDir "www/images"
    cp "www-src/images/*", "www/images"

    copyBowerFiles()
    buildNodeModules()
    buildAngFiles()
    gzipFiles()

#-------------------------------------------------------------------------------

tasks.watch =
    doc: "watch for source file changes, then run build and restart server"
    run: ->
        buildNserve()

        watch WatchConfig

        watch
            files: __basename
            run: ->
                log "file #{__basename} changed; exiting"
                process.exit 0

#-------------------------------------------------------------------------------

tasks.build =
    doc: "build the program"
    run: -> build()

#-------------------------------------------------------------------------------

tasks.serve =
    doc: "start the server"
    run: ->
        log "starting server"
        server.start ServerPidFile, ServerCmd, ServerArgs

#-------------------------------------------------------------------------------

tasks.bower =
    doc: "get files from bower"
    run: ->
        for pkg, {version, files} of BowerConfig
            log "running bower install #{pkg}##{version}"
            bower "install #{pkg}##{version}"

#-------------------------------------------------------------------------------

buildNodeModules = ->
    args = [
        "--outfile tmp/node-modules-1.js"
        "--debug"
        "--transform coffeeify"
        "--extension .coffee"
        "--require ./www-src/index.coffee:index"
        "--require q"
        "--require underscore"
    ]

    browserify args.join " "
    catSourceMap "--fixFileNames tmp/node-modules-1.js tmp/node-modules-2.js"

    args = [
        "                 tmp/node-modules-2.js"
        "--in-source-map  tmp/node-modules-2.js.map.json"
        "--output         tmp/node-modules-3.js"
        "--source-map     tmp/node-modules-3.js.map.json"
        "--source-map-url     node-modules-3.js.map.json"
    ]

    uglifyjs args.join " "
    catSourceMap "--fixFileNames tmp/node-modules-3.js www/node-modules.js"

#-------------------------------------------------------------------------------

buildAngFiles = ->

    angTangle "www-src/ang www/ang-files.js"

#-------------------------------------------------------------------------------

copyBowerFiles = ->

    jsFiles = []

    # copy all files except .js files
    for pkg, {version, files} of BowerConfig
        for oFile, iDir of files
            oFile = oFile.replace /\^/g, pkg
            iDir  = iDir.replace  /\^/g, pkg

            iFile = path.join "bower_components", pkg, iDir, oFile
            oFile = path.join "www", "bower", pkg, oFile

            if iFile.match /.*\.js$/
                jsFiles.push iFile
                continue

            mkdir "-p", path.dirname oFile
            cp iFile, oFile

    return unless jsFiles.length

    # run uglify over bower files
    args = [
        jsFiles.join " "
        "--output         tmp/bower-files.js"
        "--source-map     tmp/bower-files.js.map.json"
        "--source-map-url     bower-files.js.map.json"
    ]

    uglifyjs args.join " "

    catSourceMap "tmp/bower-files.js www/bower-files.js"

#-------------------------------------------------------------------------------
gzipFiles = ->
    wwwFiles = ls "-R", "www"

    gzipped     = 0
    gzippedDone = 0
    for file in wwwFiles
        wwwFile = path.join "www", file
        for pattern in GzipConfig
            if wwwFile.match pattern
                gzFile = path.join "www", "gz", file

                mkdir "-p", path.dirname gzFile
                gzipFile wwwFile, gzFile, ->
                    gzippedDone++

                gzipped++

#-------------------------------------------------------------------------------
gzipFile = (iFile, oFile, callback) ->
    gzip = zlib.createGzip()

    iStream = fs.createReadStream  iFile
    oStream = fs.createWriteStream oFile

    piping = iStream.pipe(gzip).pipe(oStream)

    piping.on "finish", callback

#-------------------------------------------------------------------------------

buildNserve = ->
    tasks.build.run()
    tasks.serve.run()

#-------------------------------------------------------------------------------

cleanDir = (dir) ->
    mkdir "-p", dir
    rm "-rf", "#{dir}/*"

#-------------------------------------------------------------------------------


angTangle    = (parms) ->  exec "node_modules/.bin/ang-tangle #{parms}"
bower        = (parms) ->  exec "bower #{parms}"
browserify   = (parms) ->  exec "node_modules/.bin/browserify #{parms}"
catSourceMap = (parms) ->  exec "node_modules/.bin/cat-source-map #{parms}"
coffee       = (parms) ->  exec "node_modules/.bin/coffee #{parms}"
coffeec      = (parms) ->  coffee "--bare --compile #{parms}"
uglifyjs     = (parms) ->  exec "node_modules/.bin/uglifyjs #{parms}"

#-------------------------------------------------------------------------------
# Copyright 2014 Patrick Mueller
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#-------------------------------------------------------------------------------
