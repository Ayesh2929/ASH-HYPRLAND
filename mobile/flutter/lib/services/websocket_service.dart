import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
class WsService {
  WebSocketChannel? ch;
  void connect(String url) { ch = WebSocketChannel.connect(Uri.parse(url)); }
  Stream get stream => ch?.stream ?? const Stream.empty();
  void close() => ch?.sink.close();
}
