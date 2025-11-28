import 'package:assistantforu/models/room_model.dart';
import 'package:assistantforu/models/task_model.dart';
import 'package:assistantforu/models/user_model.dart';
import 'package:assistantforu/services/room_service.dart';
import 'package:assistantforu/services/task_service.dart';
import 'package:assistantforu/services/user_service.dart';
import 'package:assistantforu/utils/AppStyles.dart';
import 'package:assistantforu/views/pages/add_task_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TasksPage extends StatefulWidget {
  final Function(Widget?) onFabChanged;
  const TasksPage({super.key, required this.onFabChanged});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final RoomService _roomService = RoomService();
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  Room? _room;
  Stream<List<Task>>? _tasksStream;
  bool _isLeader = false;
  bool _isLoading = true;
  bool _isAddingTask = false;

  @override
  void initState() {
    super.initState();
    _fetchUserRoom();
  }

  void _fetchUserRoom() async {
    if (_currentUser != null) {
      final room = await _roomService.getRoomForUser(_currentUser.uid);
      if (mounted) {
        setState(() {
          _room = room;
          if (room != null) {
            _isLeader = room.leaderId == _currentUser!.uid;
            _tasksStream = _taskService.getTasksForRoom(room.id);
            _updateFab();
          }
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateFab() {
    widget.onFabChanged(_isLeader
        ? FloatingActionButton(
            backgroundColor: AppColors.accentColor,
            foregroundColor: AppColors.primaryColor,
            onPressed: _isAddingTask ? null : _addTask,
            child: _isAddingTask
                ? const CircularProgressIndicator(color: AppColors.primaryColor)
                : const Icon(Icons.add),
          )
        : null);
  }

  void _addTask() async {
    if (_room != null) {
      setState(() {
        _isAddingTask = true;
        _updateFab();
      });

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddTaskPage(room: _room!)),
      );

      setState(() {
        _isAddingTask = false;
        _updateFab();
      });
    }
  }

  void _confirmCompleteTask(String taskId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Confirm Completion', style: TextStyle(color: AppColors.textColor)),
          content: const Text('Are you sure you want to mark this task as completed?', style: TextStyle(color: AppColors.listTileColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.accentSecondaryColor)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _taskService.updateTaskStatus(taskId, 'completed');
                  Navigator.pop(dialogContext);
                } catch (e) {
                  Navigator.pop(dialogContext);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to complete task: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Complete', style: TextStyle(color: AppColors.accentColor)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildBody(),
    );
  }
  
  Widget _buildBody(){
     if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentColor));
    }
    if (_room == null) {
      return const Center(child: Text('Please join a room to see tasks.', style: TextStyle(color: AppColors.textColor)));
    }
    return _buildTasksList();
  }

  Widget _buildTaskCard(Task task) {
    final bool canCompleteTask = _isLeader || task.assignedTo.contains(_currentUser?.uid);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(task.title, style: const TextStyle(color: AppColors.textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 8),
                Text(task.status, style: TextStyle(color: task.status == 'completed' ? AppColors.accentColor : Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(task.description!, style: const TextStyle(color: AppColors.listTileColor)),
              ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<List<UserModel?>>(
                        future: Future.wait(task.assignedTo.map((uid) => _userService.getUser(uid)).toList()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text('Assigned to: Loading...', style: TextStyle(color: AppColors.listTileColor, fontSize: 12));
                          }
                          final names = snapshot.data?.map((user) => user?.name ?? user?.email ?? 'Unknown').join(', ') ?? 'N/A';
                          return Text('Assigned to: $names', overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(color: AppColors.listTileColor, fontSize: 12));
                        },
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Due: ${DateFormat.yMd().add_jm().format(task.dueDate.toDate())}',
                        style: const TextStyle(color: AppColors.listTileColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (canCompleteTask && task.status == 'pending')
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.accentColor, size: 30),
                    onPressed: () => _confirmCompleteTask(task.id),
                  )
                else
                  const SizedBox(width: 30), // Placeholder to maintain alignment
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    return StreamBuilder<List<Task>>(
      stream: _tasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentColor));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No tasks found.', style: TextStyle(color: AppColors.textColor)));
        }

        List<Task> tasks = snapshot.data!;

        tasks.sort((a, b) {
          int getStatusPriority(String status) {
            if (status == 'pending') return 0;
            if (status == 'completed') return 2;
            return 1;
          }

          final statusA = getStatusPriority(a.status);
          final statusB = getStatusPriority(b.status);

          if (statusA != statusB) {
            return statusA.compareTo(statusB);
          }

          return a.dueDate.toDate().compareTo(b.dueDate.toDate());
        });

        return LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 800;

            if (isDesktop) {
              // Desktop: 2-column layout
              List<Widget> column1Tasks = [];
              List<Widget> column2Tasks = [];
              for (int i = 0; i < tasks.length; i++) {
                final taskCard = _buildTaskCard(tasks[i]);
                if (i.isEven) {
                  column1Tasks.add(taskCard);
                } else {
                  column2Tasks.add(taskCard);
                }
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: column1Tasks,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        children: column2Tasks,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Mobile: 1-column layout
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return _buildTaskCard(tasks[index]);
                },
              );
            }
          },
        );
      },
    );
  }
}
