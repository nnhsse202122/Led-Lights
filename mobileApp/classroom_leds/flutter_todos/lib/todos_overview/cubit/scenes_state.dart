part of 'scenes_cubit.dart';

abstract class ScenesState extends Equatable {
  const ScenesState();

  @override
  List<Object> get props => [];
}

class ScenesInitial extends ScenesState {
  const ScenesInitial();
}

class ScenesLoading extends ScenesState {
  const ScenesLoading();
}

class ScenesPopulated extends ScenesState {
  ScenesPopulated({
    this.scenes = const [],
  });

  List<Scene> scenes;

  Scene getCurrentScene() {
    Scene currentScene;
    for (Scene scene in this.scenes) {
      if (scene.day_of_week == DateTime.now().weekday) {
        if (scene.startTime == DateFormat.Hms().format(DateTime.now())) {
          currentScene = scene;
          return currentScene;
        }
      }
      Scene temp = scene;
    }
    throw new NullThrownError();
  }

  @override
  List<Object> get props => [scenes];
}
