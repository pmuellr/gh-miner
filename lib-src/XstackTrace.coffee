# Licensed under the Apache License. See footer for details.

path = require "path"

Error.prepareStackTrace = (error, structuredStackTrace) ->
    result = []

    longestFile = 0
    longestLine = 0

    result.push "--------------------------------------------"
    result.push "error: #{error}"
    result.push "stack:"

    for callSite in structuredStackTrace
        callSite.normalizedFileName = normalizeFileName callSite.getFileName()

        file = callSite.normalizedFileName
        line = "#{callSite.getLineNumber()}"

        if file.length > longestFile
            longestFile = file.length

        if line.length > longestLine
            longestLine = line.length

    for callSite in structuredStackTrace
        func = callSite.getFunction()
        file = callSite.normalizedFileName
        line = callSite.getLineNumber()

        #file = path.basename(file)
        line = "#{line}"

        file = alignLeft(  file, longestFile)
        line = alignRight( line, longestLine)

        if callSite.getTypeName() and callSite.getMethodName()
            if callSite.getTypeName() is "Object"
                funcName = callSite.getMethodName()
            else
                funcName = "#{callSite.getTypeName()}::#{callSite.getMethodName()}"
        else if callSite.getFunctionName()
            funcName = callSite.getFunctionName()
        else
            funcName = func.displayName || func.name || '<anon>'

        #if funcName == "Module._compile"
        #    result.pop()
        #    result.pop()
        #    break

        result.push "   #{file} #{line} - #{funcName}()"

    result.join "\n"

#-------------------------------------------------------------------------------
normalizeFileName = (fileName) ->
    dir  = path.dirname  fileName
    base = path.basename fileName

    unless dir is ""
        relDir = path.relative process.cwd(), dir
        if relDir.length < dir.length
            dir = relDir

    path.join dir, base

#-------------------------------------------------------------------------------
alignRight = (string, length) ->
    while string.length < length
        string = " #{string}"
    string

#-------------------------------------------------------------------------------
alignLeft  = (string, length) ->
    while string.length < length
        string = "#{string} "
    string

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
