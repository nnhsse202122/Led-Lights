import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_todos/todos_overview/models/scene.dart';
import 'package:flutter_todos/todos_overview/repository/server_util.dart';
import 'package:intl/intl.dart';

part 'scenes_state.dart';

class ScenesCubit extends Cubit<ScenesState> {
  ScenesCubit() : super(const ScenesInitial());

  Future fetchScenes() async {
    emit(ScenesLoading());

    //api calls
    final randomColor = Color.fromARGB(255, 14, 78, 143);

    var newState = new ScenesPopulated();
    newState.scenes = await fetchScenesFromServer();
    //[Scene(10, DateTime.now(), randomColor, 'solid', false)];

    // TODO: pass scenes to state???
    emit(newState);

    return newState.scenes;
  }
}
