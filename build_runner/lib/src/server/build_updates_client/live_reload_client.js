(function () {
  var _buildUpdatesProtocol = '$buildUpdates';
  var prefix = location.href.indexOf('https') > -1 ? 'wss' : 'ws';
  var ws = new WebSocket(prefix + '://' + location.host, [_buildUpdatesProtocol]);
  ws.onmessage = function (event) {
    location.reload();
  };
})();
