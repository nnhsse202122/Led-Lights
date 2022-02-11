import 'package:flutter/material.dart';

class Scene implements Comparable<Scene> {
  final int id;
  DateTime startTime;
  Color color;
  String mode;

  Scene(this.id, this.startTime, this.color, this.mode);

  Scene.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        startTime = DateTime.parse(json['start_time'] as String),
        color = Color(int.parse(json['color'] as String, radix: 16))
            .withAlpha(((json['brightness'] as double) * 255).toInt()),
        mode = json['mode'] as String;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'color': "ff" +
          color.red.toRadixString(16).padLeft(2, '0') +
          color.green.toRadixString(16).padLeft(2, '0') +
          color.blue.toRadixString(16).padLeft(2, '0'),
      'brightness': color.alpha / 255.0,
      'mode': mode,
    } as Map<String, dynamic>;
  }

  @override
  int compareTo(other) {
    if (startTime == null || other == null) {
      return -1;
    }

    return startTime.compareTo(other.startTime);
  }
}
