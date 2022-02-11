import 'dart:async';
import 'dart:convert';

import 'package:flutter_todos/todos_overview/models/scene.dart';
import 'package:http/http.dart' as http;

final String url = 'https://classroomLEDs.nnhsse.org'; // "10.0.2.2"

Future<List<Scene>> fetchScenesFromServer() async {
  print('URL: $url/leds/1');

  final response = await http.get(Uri.parse('$url/leds/1'));
  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    final List<Scene> sceneList = json
        .decode(response.body)['scenes']
        .map((Map<String, dynamic> i) => Scene.fromJson(i))
        .toList() as List<Scene>;
    print(json.decode(response.body)['scenes']);
    sceneList.sort((a, b) {
      return a.compareTo(b);
    });
    return sceneList;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load LED');
  }
}

void deleteSceneFromServer(int sceneID) async {
  final response = await http.delete(Uri.parse('$url/leds/1/scenes/$sceneID'));

  if (response.statusCode == 200) {
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to delete scene');
  }
}

void addSceneToServer(Scene scene) async {
  // set up POST request arguments
  Map<String, String> headers = {'Content-type': 'application/json'};
  String json = jsonEncode(scene);
  // make POST request
  final response = await http.post(Uri.parse('$url/leds/1/scenes'),
      headers: headers, body: json);
  if (response.statusCode != 201) {
    // If the server did not return a 201 response,
    // then throw an exception.
    throw Exception('Failed to add scene');
  }
}

void updateSceneOnServer(Scene scene) async {
  // set up POST request arguments
  Map<String, String> headers = {'Content-type': 'application/json'};
  String json = jsonEncode(scene);
  // make PUT request
  final response = await http.put(Uri.parse('$url/leds/1/scenes/${scene.id}'),
      headers: headers, body: json);
  if (response.statusCode != 200) {
    // If the server did not return a 200 response,
    // then throw an exception.
    throw Exception('Failed to update scene');
  }
}
