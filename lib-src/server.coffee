# Licensed under the Apache License. See footer for details.

path   = require "path"
crypto = require "crypto"

_        = require "underscore"
ports    = require "ports"
express  = require "express"
passport = require "passport"
ppGithub = require "passport-github"

pkg = require "../package.json"

utils = require "./utils"

#-------------------------------------------------------------------------------

PROGRAM = pkg.name
WWW_DIR = path.join __dirname, "..", "www"

DEFAULT_OPTIONS =
    cookieSecret:   "stupid cookie secret for #{PROGRAM}"
    port:           ports.getPort PROGRAM
    verbose:        false

#-------------------------------------------------------------------------------
exports.run = (options) ->
    options = _.defaults options, DEFAULT_OPTIONS

    utils.setVerbose options.verbose

    utils.logv "options: #{JSON.stringify options, null, 4}"

    # main app
    app = express()

    app.use express.cookieParser()
    app.use express.cookieSession {secret: options.cookieSecret}
    app.use setXSRFcookie
    # app.use express.logger()
    # app.use dumpRequest "app"
    app.use "/", express.static WWW_DIR

    console.log "server starting: http://localhost:#{options.port}"
    app.listen options.port

#-------------------------------------------------------------------------------
dirFromRoot = (dir) ->
    path.resolve __dirname, "..", dir

#-------------------------------------------------------------------------------
dumpRequest = (title) ->
    (request, response, next) ->
        console.log "dumpRequest #{title}"
        console.log "    path:    ", request.path

        next()

#-------------------------------------------------------------------------------
setXSRFcookie = (request, response, next) ->
    token = request.session.xsrfToken

    if token?
        response.cookie "XSRF-TOKEN", token
        next()
        return

    session = JSON.stringify request.session

    md5 = crypto.createHash "md5"
    md5.update crypto.randomBytes(16),          "utf8"
    md5.update JSON.stringify(request.session), "utf8"
    md5.update crypto.randomBytes(16),          "utf8"

    token = md5.digest "base64"
    response.cookie "XSRF-TOKEN", token
    request.session.xsrfToken = token

    next()

#-------------------------------------------------------------------------------
checkXSRFheader = (request, response, next) ->
    headerToken  = request.headers["x-xsrf-token"] || ""

    # if headerToken is ""
    #     response.send 400, "no XSRF token in X-XSRF-TOKEN header"
    #     return

    sessionToken = request.session.xsrfToken

    # unless headerToken is sessionToken
    #     response.send 400, "invalid XSRF token in X-XSRF-TOKEN header"
    #     return

    next()

#-------------------------------------------------------------------------------
exports.run() if require.main is module

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
