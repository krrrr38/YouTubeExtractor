angular.module('youtube-extractor', ['youtube-extractor-controllers', 'youtube-extractor-directives'])
    .config(["$httpProvider", function(provider) {
        provider.defaults.headers.common["X-CSRF-Token"] = $("meta[name=csrf-token]").attr("content");
    }])
    .run([function(){
        var script = document.createElement('script');
        script.src = "https://www.youtube.com/iframe_api";
        var firstScript = document.getElementsByTagName('script')[0];
        firstScript.parentNode.insertBefore(script, firstScript);
    }]);

angular.module('youtube-extractor-controllers', ['youtube-extractor-services'])
    .controller('SearchController', ['$scope', 'ExtractService', 'AlertPopup', 'NoticePopup', 'YoutubePlayer', 'Playlist', function($scope, extractor, alert, notice, player, playlist){
        $scope.searchUrl = '';
        $scope.isInvalidForm = true;
        $scope.isLoading = false;
        $scope.isFirstAccess = true;

        $scope.searchdUrl = '';
        $scope.youtubeVideos = [];

        $scope.alert = alert;
        $scope.notice = notice;
        notice.openFlush();

        player.setPlaylist(playlist);

        $scope.$watch('searchUrl', function() {
            var url = $scope.searchUrl;
            $scope.isInvalidForm = !url || !url.match(/^https?:\/\/.+/);
        });

        $scope.submit = function() {
            $scope.isInvalidForm = true;
            $scope.showMessage = false;
            $scope.isLoading = true;
            extractor.search($scope.searchUrl).then(function(data) {
                $scope.searchdUrl    = data.data.url;
                $scope.youtubeVideos = data.data.videos;
                alert.show(data.data.message, 'info');
                if ($scope.youtubeVideos.length > 0) {
                    $scope.isFirstAccess = false;
                    playlist.clear();
                    playlist.addVideos($scope.youtubeVideos);
                    player.start();
                }
            }, function(data) {
                alert.show(data.data.message, 'danger');
            }).then(function() {
                $scope.isLoading = false;
                $scope.isInvalidForm = false;
            });
        };

        $scope.playVideo = function(index) {
            player.playWithIndex(index);
        };
    }])
    .controller('YoutubeController', ['$scope', '$window', 'YoutubeService', 'Playlist', 'NoticePopup', function($scope, $window, youtube, playlist, notice){
        youtube.playlists().then(function(data) {
            // playlist: {"id": "", "title": "", "description": ""}
            $scope.playlists = data.data.playlists;
        }, function(data) {
            notice.show(data.data.message, 'danger', data.data.reload);
        });

        $scope.updatePlaylist = function() {
            if ($scope.playlist) {
                youtube.playlist($scope.playlist.id).then(function(data) {
                    // video: {"id": "", title: "", "description": "", "playlist_entry_id": ""}
                    $scope.videos = data.data.videos;
                }, function(data) {
                    notice.show(data.data.message, 'danger');
                });
            }
        };

        $scope.playPlaylist = function() {
            if ($scope.videos[0]) {
                var playPlaylistLink = "https://www.youtube.com/watch?v=" + $scope.videos[0].id + "&list=" + $scope.playlist.id;
                $window.open(playPlaylistLink);
            }
        };

        $scope.createPlaylist = function() {
            youtube.create($scope.newPlaylistTitle, $scope.newPlaylistDescription).then(function(data) {
                $scope.playlists.push({
                    id: data.data.id,
                    title: data.data.title,
                    description: data.data.description
                });
                notice.show(data.data.message, 'info');
            }, function(data) {
                notice.show(data.data.message, 'danger');
            });
        };

        $scope.deletePlaylist = function(playlistId, index) {
            var playlist = $scope.playlists.splice(index, 1);
            youtube.delete(playlistId).then(function(data) {
                notice.show(data.data.message, 'info');
            }, function(data) {
                notice.show(data.data.message, 'danger');
                $scope.playlists.push(playlist);
            });
        };

        $scope.addVideo = function() {
            var playingVideoId = playlist.currentVideo().id;
            if ($scope.playlist && playingVideoId) {
                youtube.add($scope.playlist, playingVideoId).then(function(data) {
                    $scope.videos.push({
                        id: data.data.id,
                        title: data.data.title,
                        description: "",
                        playlist_entry_id: data.data.playlist_entry_id
                    });
                    notice.show(data.data.message, 'info');
                }, function(data) {
                    var message = data.data.message;
                    notice.show(message, 'danger');
                    if (!message.match(/.*ResourceNotFound.*/)) {
                        $scope.playlists.push(playlist);
                    }
                });
            } else {
                notice.show("playlist or playing video has not set yet.", 'danger');
            };
        };

        $scope.removeVideo = function(entryId, index) {
            if ($scope.playlist && entryId) {
                var video = $scope.videos.splice(index, 1);
                youtube.remove($scope.playlist.id, entryId).then(function(data) {
                    notice.show(data.data.message, 'info');
                }, function(data) {
                    notice.show(data.data.message, 'danger');
                    $scope.videos.push(playlist);
                });
            } else {
                notice.show("playlist has not set yet.", 'danger');
            };
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
    .factory('YoutubeService', function($http) {
        return {
            playlists: function() {
                return $http({
                    method: 'GET',
                    url: '/api/playlists.json'
                });
            },
            create: function(title, description) {
                return $http({
                    method: 'POST',
                    url: '/api/playlists.json',
                    data: {
                        title: title,
                        description: description
                    }
                });
            },
            playlist: function(playlistId) {
                return $http({
                    method: 'GET',
                    url: '/api/playlists/' + playlistId + '.json'
                });
            },
            delete: function(playlistId) {
                return $http({
                    method: 'DELETE',
                    url: '/api/playlists/' + playlistId + '.json'
                });
            },
            add: function(playlist, videoId) {
                return $http({
                    method: 'POST',
                    url: '/api/playlists/' + playlist.id + '.json',
                    data: {
                        playlist_title: playlist.title,
                        video_id: videoId
                    }
                });
            },
            remove: function(playlistId, entryId) {
                return $http({
                    method: 'DELETE',
                    url: '/api/playlists/' + playlistId + '/' + entryId + '.json'
                });
            }
        };
    })
    .factory('AlertPopup', ['$timeout', function($timeout) {
        var self = {
            message: "",
            messageClass: ""
        };
        self.show = function(message, messageClass) {
            self.message = message;
            self.messageClass = messageClass;
            $timeout(function() {
                self.message = "";
            }, 10000);
        };
        return self;
    }])
    .factory('NoticePopup', ['$timeout', function($timeout) {
        var self = {
            message: "",
            messageClass: "",
            keepFlush: true
        };
        self.openFlush = function() {
            self.keepFlush = true;
            $timeout(function() {
                self.keepFlush = false;
            }, 8000);
        };
        self.show = function(message, messageClass, keep) {
            self.message = message;
            self.messageClass = messageClass;
            if (!keep) {
                $timeout(function() {
                    self.message = "";
                }, 8000);
            }
        };
        return self;
    }])
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
                                self.play(self.playlist.nextVideo().id);
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

angular.module('youtube-extractor-directives', [])
    .directive('ngConfirmClick', [
        function(){
            return {
                link: function (scope, element, attr) {
                    var msg = attr.ngConfirmClick || "Are you sure?";
                    var clickAction = attr.confirmedClick;
                    element.bind('click',function (event) {
                        if ( window.confirm(msg) ) {
                            scope.$eval(clickAction);
                        }
                    });
                }
            };
    }]);
