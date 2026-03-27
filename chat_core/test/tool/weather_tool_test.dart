import 'dart:convert';

import 'package:chat_core/chat_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('WeatherTool', () {
    test('returns geocoding and weather raw data', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'geocoding-api.open-meteo.com') {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'name': 'San Jose',
                  'country': 'United States',
                  'admin1': 'California',
                  'latitude': 37.3382,
                  'longitude': -121.8863,
                },
                {
                  'name': 'San José',
                  'country': 'Costa Rica',
                  'latitude': 9.9281,
                  'longitude': -84.0907,
                },
              ],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'current': {'temperature_2m': 18.5, 'weather_code': 2},
          }),
          200,
        );
      });

      final tool = WeatherTool(httpClient: mockClient);
      final result = await tool.execute({'city': 'San Jose'});

      expect(result, contains('San Jose'));
      expect(result, contains('Costa Rica'));
      expect(result, contains('California'));
      expect(result, contains('18.5'));
    });

    test('returns error for unknown city', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({}), 200);
      });

      final tool = WeatherTool(httpClient: mockClient);
      final result = await tool.execute({'city': 'Nonexistent'});

      expect(result, contains('Geocoding results'));
    });

    test('handles HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final tool = WeatherTool(httpClient: mockClient);
      final result = await tool.execute({'city': 'Tokyo'});

      expect(result, contains('Failed to geocode'));
    });

    test('has correct tool definition', () {
      final tool = WeatherTool();
      expect(tool.name, 'get_weather');
      expect(tool.description, isNotEmpty);
      expect(tool.parameters['required'], contains('city'));
    });
  });
}
