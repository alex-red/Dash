(function() {
  var app, feedHandler, homeCtrl;

  app = angular.module('dash', ['ngAnimate', 'mgcrea.ngStrap', 'ui.router', 'ngSanitize']);

  app.config(function($stateProvider, $urlRouterProvider) {
    $urlRouterProvider.otherwise("/index");
    return $stateProvider.state('main', {
      url: '/index',
      views: {
        'main': {
          templateUrl: 'views/home.html',
          controller: homeCtrl
        }
      }
    });
  });

  app.filter('htmlToPlaintext', function() {
    return function(text) {
      return String(text).replace(/<[^>]+>/gm, '');
    };
  });

  app.filter('returnDomainChar', function() {
    return function(text) {
      if (text.indexOf('www.') !== -1) {
        return text.split('www.')[1].substr(0, 1);
      } else {
        return text.split('//')[1].substr(0, 1);
      }
    };
  });

  app.directive('onRepeatEnd', function() {
    return function(scope, elem, attrs) {
      if (scope.$last) {
        return $('.collapsible').collapsible();
      }
    };
  });

  homeCtrl = function($scope, $interval, $http, $sce) {
    var countDelugeInfo, countSystemInfo, countTime, demoMode, getDelugeInfo, getSystemDiskInfo, getSystemInfo, grabFeed, init, time, timeFormat, toKB, toMB, updateTime;
    demoMode = true;
    timeFormat = 'h:mm:ss A';
    time = 0;
    $scope.theme_text_primary = "grey-text text-darken-4";
    $scope.feeds = [];
    $scope.feedsDB = ['http://stackoverflow.com/feeds/tag?tagnames=angularjs&sort=newest', 'https://news.ycombinator.com/rss'];
    $scope.torrents = null;
    updateTime = function() {
      time = moment().format(timeFormat);
      $scope.time_time = time.split(' ')[0];
      return $scope.time_pm = time.split(' ')[1];
    };
    getSystemInfo = function() {
      var data;
      if (demoMode) {
        data = {};
        data.totalmem = 32768;
        data.freemem = data.totalmem - _.random(5000, 8000);
        data.usedmem = (data.totalmem - data.freemem).toFixed(2);
        data.percentmem = ((data.usedmem / data.totalmem) * 100).toFixed(2);
        data.hostname = "Github Server";
        data.type = "Windows_NT";
        data.platform = "win32";
        data.arch = "x64";
        data.cpus = [
          {
            'model': "Intel(R) Xeon(R) CPU E3-1231 v3 @ 3.40GHz"
          }, 1, 2, 3, 4, 5, 6, 7
        ];
        return $scope.sysinfo = data;
      }
      return $http.get('sys_info').success(function(data) {
        data.totalmem = (data.totalmem / (1024 * 1024)).toFixed(2);
        data.freemem = (data.freemem / (1024 * 1024)).toFixed(2);
        data.usedmem = (data.totalmem - data.freemem).toFixed(2);
        data.percentmem = ((data.usedmem / data.totalmem) * 100).toFixed(2);
        return $scope.sysinfo = data;
      }).error(function(err) {
        $interval.cancel(countSystemInfo);
        return console.log("Error! " + err);
      });
    };
    getSystemDiskInfo = function() {
      var data;
      if (demoMode) {
        data = {};
        data.total = 237.69;
        data.free = 152.06;
        data.used = 85.63;
        return $scope.diskInfo = data;
      }
      return $http.get('disk_info').success(function(data) {
        data.total = (data.total / (1024 * 1024 * 1024)).toFixed(2);
        data.free = (data.free / (1024 * 1024 * 1024)).toFixed(2);
        data.used = (data.total - data.free).toFixed(2);
        return $scope.diskInfo = data;
      }).error(function(err) {
        return console.log("Error! " + err);
      });
    };
    getDelugeInfo = function() {
      var data, tmp1, tmp2, tmp3, tmp4;
      if (demoMode) {
        tmp1 = _.random(1230000000, 153000000);
        tmp2 = _.random(530000000, 153000000);
        tmp3 = _.random(30000000, 53000000);
        tmp4 = _.random(30000000, 53000000);
        data = {};
        data.torrents = [
          {
            name: 'Ubuntu-15.04-beta2-desktop-amd64.iso',
            state: 'Downloading',
            download_payload_rate: tmp1,
            active_time: 4323 + _.random(1230),
            num_seeds: 69 + _.random(50),
            eta: 3243 + _.random(1230),
            num_peers: 543 + _.random(50),
            progress: _.random(20, 30)
          }, {
            name: 'Ubuntu-21.5-desktop-amd128.iso',
            state: 'Downloading',
            download_payload_rate: tmp2,
            active_time: 4323 + _.random(1230),
            num_seeds: 69 + _.random(50),
            eta: 3243 + _.random(1230),
            num_peers: 543 + _.random(50),
            progress: _.random(70, 90)
          }
        ];
        data.stats = {
          'download_rate': tmp1 + tmp2,
          'upload_rate': tmp4 + tmp3
        };
        return $scope.torrents = data;
      }
      return $http.get('deluge_info').success(function(data) {
        return $scope.torrents = data.result;
      }).error(function(err) {
        return console.log("Error: " + err);
      });
    };
    toMB = function(b) {
      var res;
      res = (b / 1000 / 1000).toFixed(2).toString() + ' MB/s';
      return res;
    };
    toKB = function(b) {
      return (b / 1000).toFixed(2);
    };
    $scope.parseDLSpeed = function(b) {
      var res;
      res = toKB(b);
      res = res > 1000 ? toMB(b) : res.toString() + ' KB/s';
      return res;
    };
    $scope.parseTime = function(t) {
      var mins, res, secs;
      if (!t) {
        return "N/A";
      }
      res = (t / 60).toString().split('.');
      mins = res[0];
      secs = res[1] ? res[1].substr(0, 2) : 0;
      return "" + mins + "m " + secs + "s";
    };
    countTime = $interval(updateTime, 1000);
    countSystemInfo = $interval(getSystemInfo, 2000);
    countDelugeInfo = $interval(getDelugeInfo, 5000);
    grabFeed = function(URL) {
      var feed;
      feed = new google.feeds.Feed(URL);
      feed.setNumEntries(10);
      feed.setResultFormat(google.feeds.Feed.JSON_FORMAT);
      return feed.load(function(res) {
        if (!res.error) {
          return $scope.feeds = _.union($scope.feeds, res.feed.entries);
        } else {
          return null;
        }
      });
    };
    $scope.grabFeeds = function() {
      var feed, _i, _len, _ref;
      _ref = $scope.feedsDB;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        feed = _ref[_i];
        grabFeed(feed);
      }
      return $('.collapsible').collapsible();
    };
    $scope.debug = function() {
      $('.collapsible').collapsible();
      return false;
    };
    init = function() {
      updateTime();
      getSystemInfo();
      getSystemDiskInfo();
      $scope.grabFeeds();
      return getDelugeInfo();
    };
    init();
    $scope.trustHtml = function(str) {
      return $sce.trustAsHtml(str);
    };
    $scope.checkEmpty = function(obj) {
      return _.isEmpty(obj);
    };
    $scope.openModal = function(target) {
      return $("" + target).openModal();
    };
    return $scope.$on('$destroy', function() {
      $interval.cancel(countTime);
      return $interval.cancel(countSystemInfo);
    });
  };

  feedHandler = function() {
    return console.log('test');
  };

}).call(this);
