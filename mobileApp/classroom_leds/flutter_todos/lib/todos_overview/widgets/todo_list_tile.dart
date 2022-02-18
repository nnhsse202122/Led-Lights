import 'package:flutter/material.dart';
import 'package:todos_repository/todos_repository.dart';
import 'package:flutter_todos/todos_overview/models/scene.dart';

class TodoListTile extends StatelessWidget {
  const TodoListTile({
    Key? key,
    required this.scene,
    this.onToggleCompleted,
    this.onDismissed,
    this.onTap,
  }) : super(key: key);

  final Scene scene;
  final ValueChanged<bool>? onToggleCompleted;
  final DismissDirectionCallback? onDismissed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final captionColor = theme.textTheme.caption?.color;

    return Dismissible(
      key: Key('todoListTile_dismissible_${scene.id}'),
      onDismissed: onDismissed,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: theme.colorScheme.error,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(
          Icons.delete,
          color: Color(0xAAFFFFFF),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          '${scene.id}', //to update to title
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: !scene.isCompleted
              ? null
              : TextStyle(
                  color: captionColor,
                  decoration: TextDecoration.lineThrough,
                ),
        ),
        subtitle: Text(
          '$scene', //to update to description
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: Checkbox(
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          value: scene.isCompleted,
          onChanged: onToggleCompleted == null
              ? null
              : (value) => onToggleCompleted!(value!),
        ),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      ),
    );
  }
}
