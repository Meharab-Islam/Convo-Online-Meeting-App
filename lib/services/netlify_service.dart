import 'dart:convert';
import 'package:http/http.dart' as http;

class NetlifyService {
  // Use localhost for testing
  final String baseUrl = "http://localhost:8888/api/callHandler";

  Future<void> sendCallInvite({
    required String roomId,
    required List<String> targetTokens,
    required String callerName,
    String callType = 'video',
  }) async {
    await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "type": "callInvite",
        "roomId": roomId,
        "targetTokens": targetTokens,
        "callerName": callerName,
        "callType": callType,
      }),
    );
  }

  Future<void> endCall(String roomId) async {
    await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"type": "endCall", "roomId": roomId}),
    );
  }
}
