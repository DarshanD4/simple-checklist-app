import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// NOTIFICATION PLUGIN
final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TIMEZONE REQUIRED FOR SCHEDULED NOTIFICATIONS
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  await notificationsPlugin.initialize(initSettings);

  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TO-DO LIST',
      home: TodoHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Task {
  String name;
  bool isCompleted;
  String priority;
  DateTime? reminderTime;

  Task(this.name, this.isCompleted, this.priority, this.reminderTime);
}

class TodoHome extends StatefulWidget {
  @override
  _TodoHomeState createState() => _TodoHomeState();
}

class _TodoHomeState extends State<TodoHome> {
  final TextEditingController _controller = TextEditingController();
  final List<Task> _tasks = [];

  String _selectedPriority = 'Medium';
  DateTime? _selectedDateTime;

  // Pick date + time for reminder
  Future<void> _pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
      initialDate: DateTime.now(),
    );

    if (date == null) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    _selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {});
  }

  // Schedule Notification
  Future<void> scheduleNotification(Task task, int id) async {
    final androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Task Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    final details = NotificationDetails(android: androidDetails);

    if (task.reminderTime == null) return;

    await notificationsPlugin.zonedSchedule(
      id,
      "Reminder",
      "${task.name} (${task.priority})",
      tz.TZDateTime.from(task.reminderTime!, tz.local),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  // Add Task
  void _addTask() {
    if (_controller.text.isNotEmpty) {
      final newTask = Task(
        _controller.text,
        false,
        _selectedPriority,
        _selectedDateTime,
      );

      setState(() {
        _tasks.add(newTask);
      });

      scheduleNotification(newTask, _tasks.length);

      _controller.clear();
      _selectedPriority = 'Medium';
      _selectedDateTime = null;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.redAccent;
      case 'Medium':
        return Colors.orangeAccent;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ❤️ Beautiful Gradient Background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A7BD5), Color(0xFF00D2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Text(
                  "My Tasks",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Organize • Plan • Remind",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),

                SizedBox(height: 20),

                // INPUT BOX with glass effect
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Enter a task...",
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Priority Dropdown
                          DropdownButton<String>(
                            dropdownColor: Colors.black87,
                            value: _selectedPriority,
                            underline: SizedBox(),
                            style: TextStyle(color: Colors.white),
                            items: ['High', 'Medium', 'Low']
                                .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedPriority = value!);
                            },
                          ),

                          // Time Picker
                          TextButton(
                            onPressed: _pickDateTime,
                            child: Text(
                              _selectedDateTime == null
                                  ? "Pick Time"
                                  : "${_selectedDateTime!.hour}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),

                          ElevatedButton(
                            onPressed: _addTask,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text("Add"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // TASK LIST
                Expanded(
                  child: ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final t = _tasks[index];

                      return Dismissible(
                        key: UniqueKey(),
                        direction:
                            DismissDirection.endToStart, // swipe left to delete
                        onDismissed: (direction) {
                          setState(() {
                            _tasks.removeAt(index);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Task deleted"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        },

                        // RED DELETE BACKGROUND
                        background: Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          child:
                              Icon(Icons.delete, color: Colors.white, size: 30),
                        ),

                        child: Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: ListTile(
                            title: Text(
                              t.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                decoration: t.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            subtitle: t.reminderTime != null
                                ? Text(
                                    "Reminder: ${t.reminderTime}",
                                    style: TextStyle(color: Colors.white70),
                                  )
                                : null,
                            leading: Checkbox(
                              value: t.isCompleted,
                              activeColor: Colors.white,
                              checkColor: Colors.blue,
                              onChanged: (value) {
                                setState(() => t.isCompleted = value!);
                              },
                            ),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(t.priority),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                t.priority,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
