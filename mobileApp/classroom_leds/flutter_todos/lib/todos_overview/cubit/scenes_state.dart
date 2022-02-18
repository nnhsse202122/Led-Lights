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

  @override
  List<Object> get props => [scenes];
}
