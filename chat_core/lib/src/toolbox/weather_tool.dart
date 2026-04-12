import 'package:http/http.dart' as http;

import '../tool/tool.dart';
import '../tool/tool_labels.dart';

class WeatherTool extends Tool {
  WeatherTool({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  @override
  ToolLabels get labels => const ToolLabels(
    executing: 'Checking weather...',
    result: 'Weather retrieved',
    error: 'Weather lookup failed',
  );

  @override
  String get name => 'get_weather';

  @override
  String get description =>
      'Get current weather conditions for a specific city. '
      'Use this ONLY when the user asks about current or real-time weather. '
      'Do NOT use for general questions about climate, seasons, or weather concepts.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'city': {
        'type': 'string',
        'description': 'City name (e.g. Tokyo, San Jose, Newark)',
      },
    },
    'required': ['city'],
  };

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final city = arguments['city'] as String;

    final geocodingUrl = Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      {'name': city, 'count': '5'},
    );
    final geocodingResult = await _fetch(geocodingUrl);
    if (geocodingResult == null) return 'Failed to geocode "$city".';

    final lat = _firstLat(geocodingResult);
    final lon = _firstLon(geocodingResult);
    if (lat == null || lon == null) return 'City "$city" not found.';

    final weatherUrl = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat,
      'longitude': lon,
      'current': 'temperature_2m,weather_code',
    });
    final weatherResult = await _fetch(weatherUrl);

    return 'Geocoding results:\n$geocodingResult\n\n'
        'Weather (for first match):\n${weatherResult ?? "Failed to fetch weather."}';
  }

  String? _firstLat(String geocodingJson) {
    final match = RegExp(r'"latitude":\s*([\d.-]+)').firstMatch(geocodingJson);
    return match?.group(1);
  }

  String? _firstLon(String geocodingJson) {
    final match = RegExp(r'"longitude":\s*([\d.-]+)').firstMatch(geocodingJson);
    return match?.group(1);
  }

  Future<String?> _fetch(Uri url) async {
    try {
      final response = await _httpClient.get(url);
      if (response.statusCode != 200) return null;
      return response.body;
    } on Exception {
      return null;
    }
  }
}
