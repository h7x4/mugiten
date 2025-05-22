import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:signature/signature.dart';

class TimedPoint {
  final DateTime time;
  final Point point;

  const TimedPoint({
    required this.time,
    required this.point,
  });
}

class HandwritingRequest {
  final double appVersion;
  final String apiLevel;
  String? device;
  final int inputType;
  final String options;
  final int writingAreaWidth;
  final int writingAreaHeight;
  final String preContext;
  final int maxNumResults;
  final int maxCompletions;
  final String language;
  final List<List<TimedPoint>> ink;

  HandwritingRequest({
    this.appVersion = 0.4,
    this.apiLevel = '537.36',
    this.device,
    this.inputType = 0,
    this.options = 'enable_pre_space',
    required this.writingAreaWidth,
    required this.writingAreaHeight,
    this.preContext = '',
    this.maxNumResults = 10,
    this.maxCompletions = 0,
    this.language = 'ja',
    required this.ink,
  });

  List<List<dynamic>> get formattedInk => ink
      .map(
        (stroke) => [
          stroke.map((tp) => tp.point.offset.dx).toList(),
          stroke.map((tp) => tp.point.offset.dy).toList(),
          stroke
              .map((tp) => tp.time.difference(stroke.first.time).inMilliseconds)
              .toList(),
        ],
      )
      .toList();

  Map<String, Object?> toJson() => {
        'app_version': appVersion,
        'api_level': apiLevel,
        'device': device,
        'input_type': inputType,
        'options': options,
        'requests': [
          {
            'writing_guide': {
              'writing_area_width': writingAreaWidth,
              'writing_area_height': writingAreaHeight
            },
            'pre_context': preContext,
            'max_num_results': maxNumResults,
            'max_completions': maxCompletions,
            'language': language,
            'ink': formattedInk,
          }
        ]
      };

  Future<List<String>> fetch() async {
    device ??= HttpClient().userAgent;
    final response = await http.post(
      Uri.parse(
        'https://inputtools.google.com/request?itc=ja-t-i0-handwrit&app=translate',
      ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(this),
    );

    final List<dynamic> json = jsonDecode(response.body);
    // TODO: add a more detailed error.
    if (response.statusCode != 200 || json[0] != 'SUCCESS') throw Error();

    return (((json[1] as List<dynamic>)[0] as List<dynamic>)[1]
            as List<dynamic>)
        .map((e) => e as String)
        .toList();
  }
}
