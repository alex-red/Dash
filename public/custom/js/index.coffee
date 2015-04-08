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
    demoMode = true
    timeFormat = 'h:mm:ss A'
    time = 0
    $scope.theme_text_primary = "grey-text text-darken-4"
    # list of lists of feed objs
    $scope.feeds = []
    $scope.feedsDB = ['http://stackoverflow.com/feeds/tag?tagnames=angularjs&sort=newest', 'https://news.ycombinator.com/rss']
    $scope.torrents = null

    updateTime = ->
        time = moment().format timeFormat
        $scope.time_time = time.split(' ')[0]
        $scope.time_pm = time.split(' ')[1]

    getSystemInfo = ->
        if demoMode
            data = {}
            data.totalmem = 32768
            data.freemem = data.totalmem - _.random(5000,8000)
            data.usedmem = (data.totalmem - data.freemem).toFixed(2)
            data.percentmem = ((data.usedmem / data.totalmem) * 100).toFixed(2)
            data.hostname = "Github Server"
            data.type = "Windows_NT"
            data.platform = "win32"
            data.arch = "x64"
            data.cpus = [{'model': "Intel(R) Xeon(R) CPU E3-1231 v3 @ 3.40GHz"},1,2,3,4,5,6,7]
            return $scope.sysinfo = data

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
        if demoMode
            data = {}
            data.total = 237.69
            data.free = 152.06
            data.used = 85.63
            return $scope.diskInfo = data

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
        if demoMode
            tmp1 = _.random 1230000000, 153000000
            tmp2 = _.random 530000000, 153000000
            tmp3 = _.random 30000000, 53000000
            tmp4 = _.random 30000000, 53000000
            data = {}
            data.torrents = [
                {name: 'Ubuntu-15.04-beta2-desktop-amd64.iso'
                state: 'Downloading'
                download_payload_rate: tmp1
                active_time: 4323 + _.random(1230)
                num_seeds: 69 + _.random(50)
                eta: 3243  + _.random(1230)
                num_peers: 543 + _.random(50)
                progress: _.random(20,30)
                },
                {name: 'Ubuntu-21.5-desktop-amd128.iso'
                state: 'Downloading'
                download_payload_rate: tmp2
                active_time: 4323  + _.random(1230)
                num_seeds: 69 + _.random(50)
                eta: 3243 + _.random(1230)
                num_peers: 543 + _.random(50)
                progress: _.random(70,90)
                }
            ]
            data.stats =
                'download_rate': tmp1 + tmp2
                'upload_rate': tmp4 + tmp3

            return $scope.torrents = data


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
        feed.setNumEntries(10)
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