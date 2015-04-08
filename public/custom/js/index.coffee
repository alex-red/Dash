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

app.filter 'returnDomainChar', ->
    (text) ->
        if text.indexOf('www.') != -1
            return text.split('www.')[1].substr 0, 1
        else
            return text.split('//')[1].substr 0, 1

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
    $scope.feeds = []
    $scope.feedsDB = ['http://stackoverflow.com/feeds/tag?tagnames=angularjs&sort=newest', 'http://www.reddit.com/r/treeofsavior.rss']
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

    getSystemDiskInfo = ->
        $http.get 'disk_info'
            .success (data) ->
                data.total = (data.total / (1024 * 1024 * 1024)).toFixed(2)
                data.free = (data.free / (1024 * 1024 * 1024)).toFixed(2)
                data.used = (data.total - data.free).toFixed(2)
                $scope.diskInfo = data
            .error (err) ->
                console.log "Error! #{err}"

    ## Torrents
    getDelugeInfo = ->
        $http.get 'deluge_info'
            .success (data) ->
                $scope.torrents = data.result

            .error (err) ->
                console.log "Error: #{err}"

    toMB = (b) ->
        res = (b / 1000 / 1000).toFixed(2).toString() + ' MB/s'
        return res
    toKB = (b) ->
        return (b / 1000).toFixed(2)
    $scope.parseDLSpeed = (b) ->
        res = toKB(b)
        res = if res > 1000 then toMB(b) else res.toString() + ' KB/s'
        return res
    $scope.parseTime = (t) ->
        if !t then return "N/A"
        res = (t / 60).toString().split('.')
        mins = res[0]
        secs = if res[1] then (res[1].substr(0,2)) else 0
        return "#{mins}m #{secs}s"

    countTime = $interval(updateTime, 1000)
    countSystemInfo = $interval getSystemInfo, 2000
    countDelugeInfo = $interval getDelugeInfo, 5000

    grabFeed = (URL) ->
        feed = new google.feeds.Feed URL
        feed.setNumEntries(5)
        feed.setResultFormat google.feeds.Feed.JSON_FORMAT
        feed.load (res) ->
            if !res.error
                $scope.feeds = _.union $scope.feeds, res.feed.entries
            else
                return null

    $scope.grabFeeds = ->
        for feed in $scope.feedsDB
            grabFeed feed
        # console.log $scope.feeds
        $('.collapsible').collapsible()

    $scope.debug = ->
        $('.collapsible').collapsible()
        return false

    init = ->
        updateTime()
        getSystemInfo()
        getSystemDiskInfo()
        $scope.grabFeeds()
        getDelugeInfo()
    init()

    # Helpers
    $scope.trustHtml = (str) ->
        return $sce.trustAsHtml(str)

    $scope.checkEmpty = (obj) ->
        return _.isEmpty obj

    $scope.openModal = (target) ->
        $("#{target}").openModal()


    $scope.$on '$destroy', -> # Make sure to cancel the counter
        $interval.cancel countTime
        $interval.cancel countSystemInfo

feedHandler = ->
    console.log 'test'