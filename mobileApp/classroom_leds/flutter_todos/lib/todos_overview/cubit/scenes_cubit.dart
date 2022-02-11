import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_todos/todos_overview/models/scene.dart';
import 'package:flutter_todos/todos_overview/repository/server_util.dart';

part 'scenes_state.dart';

class ScenesCubit extends Cubit<ScenesState> {
  ScenesCubit() : super(const ScenesInitial());

  void fetchScenes() async {
    emit(ScenesLoading());

    //api calls
    List<Scene> scenes = await fetchScenesFromServer();

    // TODO: pass scenes to state???
    emit(ScenesPopulated());
  }
}
