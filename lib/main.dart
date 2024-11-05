import 'package:flutter/material.dart';

void main() {
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TO-DO-LIST',
      home: TodoHome(),
    );
  }
}

class TodoHome extends StatefulWidget {
  @override
  _TodoHomeState createState() => _TodoHomeState();
}

class Task {
  String name;
  bool isCompleted;

  Task(this.name, this.isCompleted); // Constructor for the Task class
}

class _TodoHomeState extends State<TodoHome> {
  final TextEditingController _controller = TextEditingController();
  final List<Task> _tasks = []; // List of Task objects

  void _addTask() {
    setState(() {
      if (_controller.text.isNotEmpty) {
        _tasks.add(Task(_controller.text,
            false)); // Add a new task, initially not completed
        _controller.clear();
      }
    });
  }

  // Function to toggle completion status of a task
  void _toggleTaskCompletion(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
  }

  // Function to delete a task
  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter a task',
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addTask,
              child: Text('Add Task'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: Key(
                        _tasks[index].name), // Unique key based on task name
                    onDismissed: (direction) {
                      _deleteTask(index);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Task deleted')),
                      );
                    },
                    background: Container(color: Colors.red),
                    child: ListTile(
                      title: Text(
                        _tasks[index].name,
                        style: TextStyle(
                          decoration: _tasks[index].isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ), // Strike-through if completed
                      ),
                      leading: Checkbox(
                        value: _tasks[index]
                            .isCompleted, // Shows whether the task is completed
                        onChanged: (bool? value) {
                          _toggleTaskCompletion(index); // Toggle task status
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
