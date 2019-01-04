import 'package:web_socket_channel/web_socket_channel.dart';

/// Manages options that are tied to particular web socket channels.
class ChannelOptionsManager {
  final _optionToChannels = Map<String, Set<WebSocketChannel>>();

  Set<String> get options => _optionToChannels.keys.toSet();

  void addOption(String option, WebSocketChannel channel) {
    if (!_optionToChannels.containsKey(option)) {
      _optionToChannels[option] = Set<WebSocketChannel>();
    }
    _optionToChannels[option].add(channel);
  }

  /// Removes a channel; any options that were only tied to that channel are
  /// also removed.
  void removeChannel(WebSocketChannel channel) {
    var toRemove = [];
    // Find the set of options that no longer have any listeners.
    for (var option in _optionToChannels.keys) {
      var listeners = _optionToChannels[option];
      listeners.remove(channel);
      if (listeners.isEmpty) toRemove.add(option);
    }
    toRemove.forEach(_optionToChannels.remove);
  }
}
