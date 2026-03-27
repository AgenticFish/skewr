import 'package:http/http.dart' as http;

import '../tool/tool.dart';

class WeatherTool implements Tool {
  WeatherTool({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  @override
  String get name => 'get_weather';

  @override
  String get description =>
      'Search for a city and get its current weather. '
      'Returns geocoding results (may include multiple matches) '
      'and weather data as raw JSON.';

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

    final geocodingResult = await _fetch(
      'https://geocoding-api.open-meteo.com/v1/search?name=$city&count=5',
    );
    if (geocodingResult == null) return 'Failed to geocode "$city".';

    final weatherResult = await _fetch(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${_firstLat(geocodingResult)}'
      '&longitude=${_firstLon(geocodingResult)}'
      '&current=temperature_2m,weather_code',
    );

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

  Future<String?> _fetch(String url) async {
    try {
      final response = await _httpClient.get(Uri.parse(url));
      if (response.statusCode != 200) return null;
      return response.body;
    } on Exception {
      return null;
    }
  }
}
