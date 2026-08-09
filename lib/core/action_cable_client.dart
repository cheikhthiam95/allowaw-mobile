import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'constants.dart';
import 'token_storage.dart';

/// Client ActionCable minimal — juste ce qu'il faut pour s'abonner à
/// UserChannel et recevoir ses diffusions. Gère la reconnexion (délai
/// croissant) puisque les réseaux mobiles coupent la connexion souvent
/// (mise en veille, changement wifi/4G...).
///
/// Protocole ActionCable (JSON sur WebSocket) :
///  - le serveur envoie {"type":"welcome"} à la connexion
///  - le client envoie {"command":"subscribe","identifier":"{...}"}
///  - le serveur confirme par {"identifier":"...","type":"confirm_subscription"}
///  - le serveur envoie `{"type":"ping","message":<unix ts>}` périodiquement
///  - les diffusions arrivent en {"identifier":"...","message":{...}}
class ActionCableClient {
  ActionCableClient._();
  static final instance = ActionCableClient._();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _wantConnected = false;

  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  /// Flux des messages reçus sur UserChannel (déjà désenveloppés du
  /// "message" ActionCable — ping/confirm_subscription/welcome filtrés).
  Stream<Map<String, dynamic>> get messages => _controller.stream;

  Future<void> connect() async {
    _wantConnected = true;
    if (_channel != null) return;

    final token = await TokenStorage.read();
    if (token == null) return;

    final wsUrl = ApiConfig.webBaseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');

    try {
      final channel = WebSocketChannel.connect(Uri.parse('$wsUrl/cable?token=$token'));
      _channel = channel;
      _sub = channel.stream.listen(_onData, onDone: _onDone, onError: (_) => _onDone(), cancelOnError: true);

      // Envoie la commande "subscribe" dès que le handshake WS est terminé
      // (pas besoin d'attendre le message "welcome" du serveur en pratique).
      channel.ready.then((_) {
        if (_channel == channel) _subscribeToUserChannel();
      }).catchError((_) {
        // La connexion a échoué avant même d'ouvrir — onDone gérera la reconnexion.
      });
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = data['type'] as String?;
    if (type == 'ping' || type == 'welcome') return;

    if (type == 'confirm_subscription') {
      _reconnectAttempt = 0;
      return;
    }

    if (data['identifier'] != null && data['message'] != null) {
      final message = data['message'];
      if (message is Map<String, dynamic>) {
        _controller.add(message);
      }
      return;
    }
  }

  void _subscribeToUserChannel() {
    _channel?.sink.add(jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'UserChannel'}),
    }));
  }

  void _onDone() {
    _sub?.cancel();
    _channel = null;
    if (_wantConnected) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    // Délai croissant plafonné à 30s (1,2,4,8,16,30,30...).
    final delaySeconds = [1, 2, 4, 8, 16, 30][_reconnectAttempt.clamp(0, 5)];
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), connect);
  }

  void disconnect() {
    _wantConnected = false;
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
