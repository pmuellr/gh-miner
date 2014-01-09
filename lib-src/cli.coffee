# Licensed under the Apache License. See footer for details.

fs   = require "fs"
path = require "path"

_    = require "underscore"
nopt = require "nopt"

pkg    = require "../package.json"
server = require "./server"

require "./XstackTrace"

PROGRAM     = pkg.name
VERSION     = pkg.version
HOME        = process.env.HOME || "."
CONFIG_FILE = path.join HOME, ".#{PROGRAM}", "config.json"

cli = exports

#-------------------------------------------------------------------------------
exports.main = ->

    options =
        config:             [ "c", String  ]
        cookieSecret:       [ "",  String  ]
        githubClientId:     [ "",  String  ]
        githubClientSecret: [ "",  String  ]
        port:               [ "p", Number  ]
        verbose:            [ "v", Boolean ]
        help:               [ "h", Boolean ]

    shortOptions = "?": ["--help"]
    for optionName, optionRec of options
        if optionRec[0] isnt ""
            shortOptions[optionRec[0]] = ["--#{optionName}"]

    for optionName, optionRec of options
        options[optionName] = optionRec[1]

    parsed = nopt options, shortOptions, process.argv, 2

    args = parsed.argv.remain

    return help() if args[0] in ["?", "help"]
    return help() if parsed.help

    cmdOptions = {}
    for optionName, ignored of options
        cmdOptions[optionName] = parsed[optionName] if parsed[optionName]?

    if cmdOptions.config
        unless fs.existsSync cmdOptions.config
            console.log "config file not found: #{cmdOptions.config}"
            process.exit 1
    else
        cmdOptions.config = CONFIG_FILE

    envOptions = {}
    envOptions.port = process.env.PORT

    cfgOptions = {}
    cfgContent = null

    try
        cfgContent = fs.readFileSync cmdOptions.config, "utf8"
    catch e

    if cfgContent?
        try
            cfgOptions = JSON.parse cfgContent
        catch e
            console.log "error parsing JSON in #{CONFIG_FILE}: #{e}"
            process.exit 1

    cfgOptions = _.pick cfgOptions, _.keys(options)

    options = _.defaults cmdOptions, envOptions, cfgOptions

    process.on 'uncaughtException', (err) ->
        console.log "uncaught exception: #{err}"
        console.log "stack trace:"
        console.log err.stack || "<no stack trace available>"

    server.run options

#-------------------------------------------------------------------------------
help = ->
#       ---------1---------2---------3---------4---------5---------6---------7---------8
    console.log """
        #{PROGRAM} #{VERSION}

            runs a #{PROGRAM} server

        usage: #{PROGRAM} [options] srcFile1 srcFile2 ... outFile

            options:
                -c --config STRING              configuration file name
                   --cookieSecret STRING        cookie secret
                   --githubClientId STRING      GitHub application client id
                   --githubClientSecret STRING  GitHub application client secret
                   --sessionDB STRING           url of the session database
                -p --port NUMBER                tcp/ip to run server on
                -v --verbose                    be verbose
                -h --help                       print this help

        The port can also be specified by setting the PORT environment variable.

        If the configuration file name is not specified, a config file will be
        looked for in #{CONFIG_FILE}.

        The config file is a JSON file which contains properties corresponding
        to the long option names, and their values.

        If sessionDB is not specified, sessions will not be persisted.

        Currently, only MongoDB URLs can be used for the sessionDB value.
    """

    return

#-------------------------------------------------------------------------------
exports.main() if require.main is module

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
