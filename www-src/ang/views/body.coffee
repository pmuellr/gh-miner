# Licensed under the Apache License. See footer for details.

AngTangle.controller body = ($scope, Logger, data) ->

    domReady = false

    $ ->
        domReady = true

        $scope.isDev = $("html").hasClass "dev"

    $scope.messages   = Logger.getMessages()
    $scope.pkg        = data.package

    subTitle = ""

    $scope.getSubtitle = ->
        return "" if subTitle is ""
        return ": #{subTitle}"

    $scope.setSubtitle = (s) ->
        subTitle = s

    $scope.$on "$routeChangeSuccess", (next, current) ->
        $(".navbar-collapse").collapse("hide") if domReady

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
