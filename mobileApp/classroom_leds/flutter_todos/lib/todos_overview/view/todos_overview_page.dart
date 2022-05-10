import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_todos/edit_todo/view/edit_todo_page.dart';
import 'package:flutter_todos/l10n/l10n.dart';
import 'package:flutter_todos/todos_overview/todos_overview.dart';
import 'package:todos_repository/todos_repository.dart';
import 'package:intl/intl.dart';

class SceneCreator {
  final _controller = StreamController<Scene>();

  SceneCreator(ScenesState state) {
    //create a timer that checks every second and reassigns the current Scene
    if (state is ScenesPopulated) {
      final scenesList = state.scenes;
      Timer.periodic(Duration(seconds: 1), (t) {
        _controller.sink.add(currentScene);
        //if statements to check if the currentScene is updated
        //at the end, currentScene = scene;
      });
      for (Scene scene in scenesList) {
        if (scene.day_of_week.isNotEmpty) {
          final weekDays = [
            'sunday',
            'monday',
            'tuesday',
            'wednesday',
            'thursday',
            'friday',
            'saturday',
          ];
          final day = scene.day_of_week;
          final currentWeekday = DateTime.now().weekday;
          if (weekDays[currentWeekday].compareTo(day) == 0) {
            final timeNow = DateFormat('HH:mm:ss').format(DateTime.now());
            final sceneStartTime =
                DateFormat('HH:mm:ss').format(scene.startTime);
            if (timeNow.compareTo(sceneStartTime) == 0) {
              currentScene = scene;
            }
          }
        }
      }
    }
  }
  Stream<Scene> get stream => _controller.stream;
}

class TodosOverviewPage extends StatelessWidget {
  const TodosOverviewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScenesCubit()..fetchScenes(),
      child: const TodosOverviewView(),
    );
  }
}

//normally, if there is an onPressed attribute, you put in this method
//to check the currentScene when the button is like refreshed or something
final randomColor = Color.fromARGB(255, 14, 78, 143);
var currentScene = Scene(0, new DateTime(2022), randomColor, 'solid',
    DateTime.now().weekday.toString(), false);

Scene checkCurrentScene(List<Scene> scenes) {
  for (Scene scene in scenes) {
    if (scene.day_of_week.isNotEmpty) {
      final weekDays = [
        'sunday',
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
      ];
      final day = scene.day_of_week; //the scene's day
      final currentWeekday = DateTime.now().weekday; //today's day
      if (weekDays[currentWeekday].compareTo(day) == 0) {
        //checking if the days match
        final timeNow = DateFormat('HH:mm:ss').format(DateTime.now());
        final sceneStartTime = DateFormat('HH:mm:ss').format(scene.startTime);
        final previousSceneStartTime = DateFormat('HH:mm:ss').format(
            currentScene
                .startTime); // assumes the scenes are in order in the json file
        //if the start time of this scene is before the current time
        if ((timeNow.compareTo(sceneStartTime) > 0) &&
            (sceneStartTime.compareTo(previousSceneStartTime) > 0)) {
          currentScene = scene;
        }
      }
    }
  }
  return currentScene;
}

class TodosOverviewView extends StatelessWidget {
  const TodosOverviewView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.todosOverviewAppBarTitle),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ScenesCubit, ScenesState>(
            listener: (context, state) {
              if (state is ScenesLoading) {
                print('loading state...');
              } else if (state is ScenesPopulated) {
                print('scenes loaded!');
              }
            },
          ),
        ],
        child: BlocBuilder<ScenesCubit, ScenesState>(
          builder: (context, state) {
            if (state is ScenesLoading) {
              return const Center(child: CupertinoActivityIndicator());
            } else if (state is ScenesPopulated) {
              return CupertinoScrollbar(
                child: ListView(
                  children: [
                    //for (final individualScene in state.scenes)
                    TodoListTile(scene: checkCurrentScene(state.scenes)
                        // onToggleCompleted: (isCompleted) {
                        //   context.read<TodosOverviewBloc>().add(
                        //         TodosOverviewTodoCompletionToggled(
                        //           scene: scene,
                        //           isCompleted: isCompleted,
                        //         ),
                        //       );
                        // },
                        // onDismissed: (_) {
                        //   context
                        //       .read<TodosOverviewBloc>()
                        //       .add(TodosOverviewTodoDeleted(scene));
                        // },
                        // onTap: () {
                        //   Navigator.of(context).push(
                        //     EditTodoPage.route(initialTodo: todo),
                        //   );
                        // },
                        ),
                  ],
                ),
              );
            } else {
              return Center(
                child: Text(
                  l10n.todosOverviewEmptyText,
                  style: Theme.of(context).textTheme.caption,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

//NEW ATTEMPT AT A TIMER STATEFUL PAGE \/

// class ScenePage extends StatefulWidget {
//   const ScenePage({Key? key}) : super(key: key);

//   @override
//   State<ScenePage> createState() => _ScenePageState();
// }

// class _ScenePageState extends State<ScenePage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(l10n.todosOverviewAppBarTitle),
//       ),
//       body: MultiBlocListener(
//         listeners: [
//           BlocListener<ScenesCubit, ScenesState>(
//             listener: (context, state) {
//               if (state is ScenesLoading) {
//                 print('loading state...');
//               } else if (state is ScenesPopulated) {
//                 print('scenes loaded!');
//               }
//             },
//           ),
//         ],
//         child: BlocBuilder<ScenesCubit, ScenesState>(
//           builder: (context, state) {
//             if (state is ScenesLoading) {
//               return const Center(child: CupertinoActivityIndicator());
//             } else if (state is ScenesPopulated) {
//               return CupertinoScrollbar(
//                 child: ListView(
//                   children: [
//                     TodoListTile(scene: checkCurrentScene(state.scenes)),
//                   ],
//                 ),
//               );
//             } else {
//               return Center(
//                 child: Text(
//                   l10n.todosOverviewEmptyText,
//                   style: Theme.of(context).textTheme.caption,
//                 ),
//               );
//             }
//           },
//         ),
//       ),
//     );
//   }
// }
