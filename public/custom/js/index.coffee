app = angular.module 'dash', ['ngAnimate', 'mgcrea.ngStrap', 'ui.router', 'ngSanitize']

app.config ($stateProvider, $urlRouterProvider) ->
    $urlRouterProvider.otherwise("/index")

    $stateProvider
        .state 'main', {
            url: '/index'
            views: {
                'main': {
                    templateUrl: 'views/home.html'
                    controller: homeCtrl
                }
            }
        }

app.filter 'htmlToPlaintext', ->
  (text) ->
    String(text).replace /<[^>]+>/gm, ''

app.directive 'onRepeatEnd', ->
    (scope, elem, attrs) ->
        if scope.$last
            $('.collapsible').collapsible()


homeCtrl = ($scope, $interval, $http, $sce) ->
    # Vars
    timeFormat = 'h:mm:ss A'
    time = 0
    $scope.theme_text_primary = "grey-text text-darken-4"
    # list of lists of feed objs
    $scope.feeds = null
    $scope.torrents = null

    updateTime = ->
        time = moment().format timeFormat
        $scope.time_time = time.split(' ')[0]
        $scope.time_pm = time.split(' ')[1]

    getSystemInfo = ->
        $http.get 'sys_info'
            .success (data) ->
                data.totalmem = (data.totalmem / (1024 * 1024)).toFixed(2)
                data.freemem = (data.freemem / (1024 * 1024)).toFixed(2)
                data.usedmem = (data.totalmem - data.freemem).toFixed(2)
                data.percentmem = ((data.usedmem / data.totalmem) * 100).toFixed(2)
                $scope.sysinfo = data
            .error (err) ->
                $interval.cancel countSystemInfo
                console.log "Error! #{err}"

    getDelugeInfo = ->
        $http.get 'deluge_info'
            .success (data) ->
                $scope.torrents = data.result
                console.log $scope.torrents
            .error (err) ->
                console.log "Error: #{err}"

    countTime = $interval(updateTime, 1000)
    countSystemInfo = $interval getSystemInfo, 2000
    countDelugeInfo = $interval getDelugeInfo, 5000

    grabFeed = (URL) ->
        feed = new google.feeds.Feed URL
        feed.setNumEntries(5)
        feed.setResultFormat google.feeds.Feed.JSON_FORMAT
        feed.load (res) ->
            if !res.error
                console.log res.feed.entries
                $scope.feeds = res.feed.entries
            else
                return null

    $scope.grabFeeds = ->
        grabFeed 'http://stackoverflow.com/feeds/tag?tagnames=angularjs&sort=newest'
        console.log $scope.feeds
        $('.collapsible').collapsible()
    $scope.debug = ->
        $('.collapsible').collapsible()
        return false

    init = ->
        updateTime()
        getSystemInfo()
        $scope.grabFeeds()

        getDelugeInfo()
    init()

    # Helpers
    $scope.trustHtml = (str) ->
        return $sce.trustAsHtml(str)


    $scope.$on '$destroy', -> # Make sure to cancel the counter
        $interval.cancel countTime
        $interval.cancel countSystemInfo

feedHandler = ->
    console.log 'test'