import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String sseChunk(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';
const sseDone = 'data: [DONE]\n\n';

MockClient mockStreamingClient(String body, {int statusCode = 200}) {
  return MockClient.streaming((request, _) async {
    return http.StreamedResponse(Stream.value(utf8.encode(body)), statusCode);
  });
}
