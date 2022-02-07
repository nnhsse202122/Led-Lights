import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'scenes_state.dart';

class ScenesCubit extends Cubit<ScenesState> {
  ScenesCubit() : super(const ScenesInitial());

  void fetchScenes() {
    emit(ScenesLoading());
    //api calls
    emit(ScenesPopulated());
  }
}
