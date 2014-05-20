angular.module('youtube-extractor', ['youtube-extractor-controllers'])
    .run([function(){
        var script = document.createElement('script');
        script.src = "https://www.youtube.com/iframe_api";
        var firstScript = document.getElementsByTagName('script')[0];
        firstScript.parentNode.insertBefore(script, firstScript);
    }]);

angular.module('youtube-extractor-controllers', ['youtube-extractor-services'])
    .controller('SearchController', ['$window', '$scope', 'ExtractService', 'YoutubePlayer', 'Playlist', function($window, $scope, extractor, player, playlist){
        $scope.searchUrl = '';
        $scope.isInvalidForm = true;
        $scope.isLoading = false;
        $scope.isFirstAccess = true;

        $scope.searchdUrl = '';
        $scope.youtubeVideos = [];

        $scope.messageClass = '';
        $scope.message = '';

        player.setPlaylist(playlist);

        $scope.$watch('searchUrl', function() {
            var url = $scope.searchUrl;
            $scope.isInvalidForm = !url || !url.match(/^https?:\/\/.+/);
        });

        $scope.submit = function() {
            $scope.showMessage = false;
            $scope.isLoading = true;
            extractor.search($scope.searchUrl).then(function(data) {
                $scope.searchdUrl   = data.data.url;
                $scope.youtubeVideos   = data.data.videos;
                $scope.message      = data.data.message;
                $scope.messageClass = "info";
                if ($scope.youtubeVideos.length > 0) {
                    $scope.isFirstAccess = false;
                    playlist.clear();
                    playlist.addVideos($scope.youtubeVideos);
                    player.start();
                }
            }, function(data) {
                $scope.message      = data.data.message;
                $scope.messageClass = "danger";
            }).then(function() {
                $scope.isLoading = false;
            });
        };

        $scope.playVideo = function(index) {
            player.playWithIndex(index);
        };
    }]);

angular.module('youtube-extractor-services', [])
    .factory('ExtractService', function($http) {
        return {
            search: function(url) {
                return $http({
                    method: 'GET',
                    url: '/api/extractor/get.json',
                    params: {
                        url: url
                    }
                });
            }
        };
    })
    .factory('YoutubePlayer', ['$timeout', function($timeout) {
        var self = {
            state: -2,
            player: null,
            playlist: null
        };
        self.setPlaylist = function(playlist) {
            self.playlist = playlist;
        };
        self.start = function () {
            if (!self.playlist) return;
            self.play(self.playlist.currentVideo().id);
        };
        self.stop = function() {
            if (!self.player) return;
            self.player.stopVideo();
            self.state = -2;
        };
        self.play = function(id) {
            if (!self.player) {
                self.player = new YT.Player('player', {
                    videoId: id,
                    playerVars: {
                        autoplay: 1,
                        rel: 0
                    },
                    events: {
                        onStateChange: function(event) {
                            self.state = event.data;
                            if(self.state == YT.PlayerState.ENDED) {
                                self.play(self.playList.nextVideo().id);
                            } else if(self.state == -1) {
                                $timeout(function() {
                                    if (self.state == -1) {
                                        self.play(self.playList.nextVideo().id);
                                    }
                                }, 3000);
                            }
                        }
                    }
                });
            } else {
                self.player.loadVideoById(id);
            }
        };
        self.playWithIndex = function(index) {
            self.playlist.setIndex(index);
            self.player.loadVideoById(self.playlist.currentVideo().id);
        };
        return self;
    }])
    .factory('Playlist', function() {
        var self = {
            list: [],
            index: 0
        };
        self.clear = function() {
            self.list = [];
            self.index = 0;
        };
        self.addVideo = function(id) {
            self.list.push(id);
        };
        self.addVideos = function(ids) {
            self.list = self.list.concat(ids);
        };
        self.currentVideo = function(id) {
            return self.list[self.index];
        };
        self.nextVideo = function() {
            if (self.index + 1 >= self.list.length) {
                self.index = 0;
            } else {
                self.index++;
            }
            return self.list[self.index];
        };
        self.setIndex = function(index) {
            self.index = index;
        };
        return self;
    });
