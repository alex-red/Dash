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

  app.directive('onRepeatEnd', function() {
    return function(scope, elem, attrs) {
      if (scope.$last) {
        return $('.collapsible').collapsible();
      }
    };
  });

  homeCtrl = function($scope, $interval, $http, $sce) {
    var countDelugeInfo, countSystemInfo, countTime, getDelugeInfo, getSystemInfo, grabFeed, init, time, timeFormat, updateTime;
    timeFormat = 'h:mm:ss A';
    time = 0;
    $scope.theme_text_primary = "grey-text text-darken-4";
    $scope.feeds = null;
    $scope.torrents = null;
    updateTime = function() {
      time = moment().format(timeFormat);
      $scope.time_time = time.split(' ')[0];
      return $scope.time_pm = time.split(' ')[1];
    };
    getSystemInfo = function() {
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
    getDelugeInfo = function() {
      return $http.get('deluge_info').success(function(data) {
        $scope.torrents = data.result;
        return console.log($scope.torrents);
      }).error(function(err) {
        return console.log("Error: " + err);
      });
    };
    countTime = $interval(updateTime, 1000);
    countSystemInfo = $interval(getSystemInfo, 2000);
    countDelugeInfo = $interval(getDelugeInfo, 5000);
    grabFeed = function(URL) {
      var feed;
      feed = new google.feeds.Feed(URL);
      feed.setNumEntries(5);
      feed.setResultFormat(google.feeds.Feed.JSON_FORMAT);
      return feed.load(function(res) {
        if (!res.error) {
          console.log(res.feed.entries);
          return $scope.feeds = res.feed.entries;
        } else {
          return null;
        }
      });
    };
    $scope.grabFeeds = function() {
      grabFeed('http://stackoverflow.com/feeds/tag?tagnames=angularjs&sort=newest');
      console.log($scope.feeds);
      return $('.collapsible').collapsible();
    };
    $scope.debug = function() {
      $('.collapsible').collapsible();
      return false;
    };
    init = function() {
      updateTime();
      getSystemInfo();
      $scope.grabFeeds();
      return getDelugeInfo();
    };
    init();
    $scope.trustHtml = function(str) {
      return $sce.trustAsHtml(str);
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
