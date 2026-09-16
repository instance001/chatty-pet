import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

/// Sends one explicitly selected Chatty reply to FMI's report receiver.
///
/// The Talk panel deliberately does not provide the child's preceding message
/// to this service. A report therefore contains the flagged model output,
/// optional grown-up note, and minimal app/model context only.
class AiReportService {
  // Public `client` keeps unit-test injection readable; the private field is
  // intentionally not exposed as a constructor parameter.
  // ignore: prefer_initializing_formals
  const AiReportService({http.Client? client}) : _client = client;

  static final Uri _endpoint = Uri.parse(
    'https://script.google.com/macros/s/AKfycbwb99_LFCIgblnq8Md6_yLer7sznSfZ1LpW5AujrMDJgBrfBn0WlwOBfuc6iMJ4YWcm0A/exec',
  );

  final http.Client? _client;

  Future<void> submit({
    required String reason,
    required String assistantResponse,
    String? note,
  }) async {
    final client = _client ?? http.Client();
    try {
      final response = await _postAndFollowGoogleRedirect(client, {
        'schemaVersion': 1,
        'reportId': 'rpt_${_randomId()}',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'app': {
          'name': 'Chatty-Pet',
          'packageId': 'io.instance001.chattypet',
          'version': '1.0.1+2',
        },
        'generation': {
          'lane': 'local',
          'providerLabel': 'On-device GGUF',
          'modelLabel': 'SmolLM2-360M-Instruct-Q4_K_M',
        },
        'report': {'reason': reason, 'note': note},
        'content': {
          'assistantResponse': assistantResponse,
          'precedingUserPrompt': null,
        },
      }).timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('The report service returned ${response.statusCode}.');
      }
      final body = jsonDecode(response.body);
      if (body is! Map || body['ok'] != true) {
        throw StateError('The report service did not accept the report.');
      }
    } on FormatException {
      throw StateError('The report service returned an invalid response.');
    } finally {
      if (_client == null) client.close();
    }
  }

  String _randomId() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  Future<http.Response> _postAndFollowGoogleRedirect(
    http.Client client,
    Map<String, Object?> payload,
  ) async {
    final request = http.Request('POST', _endpoint)
      ..headers['Content-Type'] = 'text/plain; charset=utf-8'
      ..body = jsonEncode(payload);
    final first = await client.send(request);
    if (first.statusCode < 300 || first.statusCode >= 400) {
      return http.Response.fromStream(first);
    }

    final location = first.headers['location'];
    if (location == null) {
      throw StateError('The report service redirected without a response URL.');
    }
    final target = first.request!.url.resolve(location);
    if (target.scheme != 'https' ||
        !target.host.endsWith('googleusercontent.com')) {
      throw StateError('The report service redirected to an unexpected host.');
    }
    return http.Response.fromStream(
      await client.send(http.Request('GET', target)),
    );
  }
}
