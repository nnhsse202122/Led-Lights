import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_todos/edit_todo/view/edit_todo_page.dart';
import 'package:flutter_todos/l10n/l10n.dart';
import 'package:flutter_todos/todos_overview/todos_overview.dart';
import 'package:todos_repository/todos_repository.dart';

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
                    for (final individualScene in state.scenes)
                      TodoListTile(scene: individualScene
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
