import 'package:assistantforu/models/room_model.dart';
import 'package:assistantforu/models/task_model.dart';
import 'package:assistantforu/services/room_service.dart';
import 'package:assistantforu/services/task_service.dart';
import 'package:assistantforu/utils/AppStyles.dart';
import 'package:assistantforu/views/widgets/gradient_scaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final TaskService _taskService = TaskService();
  final RoomService _roomService = RoomService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  Stream<List<Task>>? _tasksStream;
  Room? _room;

  @override
  void initState() {
    super.initState();
    _fetchUserRoomAndTasks();
  }

  void _fetchUserRoomAndTasks() async {
    if (_currentUser != null) {
      final room = await _roomService.getRoomForUser(_currentUser!.uid);
      if (mounted && room != null) {
        setState(() {
          _room = room;
          _tasksStream = _taskService.getTasksForRoom(room.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: StreamBuilder<List<Task>>(
        stream: _tasksStream,
        builder: (context, snapshot) {
          if (_room == null) {
            return const Center(
              child: Text(
                'Join a room to see analytics',
                style: AppTextStyles.subtitleStyle,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentColor));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No tasks found to generate analytics.',
                style: AppTextStyles.subtitleStyle,
              ),
            );
          }

          final tasks = snapshot.data!;
          final totalTasks = tasks.length;
          final completedTasks = tasks.where((t) => t.status == 'completed').toList();
          final tasksCompletedCount = completedTasks.length;
          final tasksPendingCount = totalTasks - tasksCompletedCount;
          final completionRate = totalTasks > 0 ? tasksCompletedCount / totalTasks : 0.0;

          final completedOnTimeCount = completedTasks.where((t) {
            return t.completedAt != null && !t.completedAt!.toDate().isAfter(t.dueDate.toDate());
          }).length;
          
          final onTimeCompletionRate = totalTasks > 0 ? completedOnTimeCount / totalTasks : 0.0;

          final completedLateCount = tasksCompletedCount - completedOnTimeCount;

          final myActiveTasks = tasks.where((task) {
            return task.assignedTo.contains(_currentUser!.uid) && task.status != 'completed';
          }).toList();

          final overdueTasks = myActiveTasks.where((task) {
            return task.dueDate.toDate().isBefore(DateTime.now());
          }).toList();


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Room Task Completion Rate',
                  style: AppTextStyles.titleStyle,
                ),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularPercentIndicator(
                      radius: 120.0,
                      lineWidth: 15.0,
                      percent: completionRate,
                      progressColor: Colors.orange,
                      backgroundColor: Colors.red,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    CircularPercentIndicator(
                      radius: 120.0,
                      lineWidth: 15.0,
                      percent: onTimeCompletionRate,
                      progressColor: Colors.green,
                      backgroundColor: Colors.transparent,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    Text(
                      '${(completionRate * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isDesktop = constraints.maxWidth > 600;
                    double cardWidth = isDesktop ? constraints.maxWidth * 0.45 : constraints.maxWidth;
                    return Center(
                      child: SizedBox(
                        width: cardWidth,
                        child: Card(
                          elevation: 4,
                          color: AppColors.cardColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Column(
                              children: [
                                _buildStatRow(Icons.list_alt, AppColors.accentSecondaryColor, 'Total Tasks Created', totalTasks),
                                const Divider(color: AppColors.listTileColor, thickness: 0.5, indent: 16, endIndent: 16),
                                _buildStatRow(Icons.check_circle, Colors.green, 'Tasks Completed', tasksCompletedCount),
                                const Divider(color: AppColors.listTileColor, thickness: 0.5, indent: 16, endIndent: 16),
                                _buildStatRow(Icons.timer_outlined, AppColors.accentColor, 'Completed On Time', completedOnTimeCount),
                                const Divider(color: AppColors.listTileColor, thickness: 0.5, indent: 16, endIndent: 16),
                                _buildStatRow(Icons.warning_amber_rounded, Colors.orange, 'Completed Late', completedLateCount),
                                const Divider(color: AppColors.listTileColor, thickness: 0.5, indent: 16, endIndent: 16),
                                _buildStatRow(Icons.pending_actions, Colors.red, 'Tasks Pending', tasksPendingCount),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                const Text("Your Active Tasks", style: AppTextStyles.titleStyle),
                const SizedBox(height: 10),
                myActiveTasks.isEmpty
                    ? const Text("You have no active tasks.", style: AppTextStyles.subtitleStyle)
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: myActiveTasks.length,
                        itemBuilder: (context, index) {
                          return _buildTaskCard(myActiveTasks[index]);
                        },
                      ),
                const SizedBox(height: 20),
                const Text("Overdue Tasks", style: AppTextStyles.titleStyle),
                const SizedBox(height: 10),
                overdueTasks.isEmpty
                    ? const Text("No overdue tasks. Great job!", style: AppTextStyles.subtitleStyle)
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: overdueTasks.length,
                        itemBuilder: (context, index) {
                          return _buildTaskCard(overdueTasks[index]);
                        },
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final bool isOverdue = task.dueDate.toDate().isBefore(DateTime.now()) && task.status != 'completed';
    return Card(
      color: AppColors.cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isOverdue ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        title: Text(task.title, style: const TextStyle(color: AppColors.textColor, fontWeight: FontWeight.bold)),
        subtitle: Text('Status: ${task.status} - Due: ${DateFormat.yMd().format(task.dueDate.toDate())}', style: const TextStyle(color: AppColors.listTileColor)),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, Color color, String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textColor),
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColor),
          ),
        ],
      ),
    );
  }
}
