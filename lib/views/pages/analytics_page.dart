import 'package:assistantforu/models/room_model.dart';
import 'package:assistantforu/models/task_model.dart';
import 'package:assistantforu/models/user_model.dart';
import 'package:assistantforu/services/room_service.dart';
import 'package:assistantforu/services/task_service.dart';
import 'package:assistantforu/services/user_service.dart';
import 'package:assistantforu/utils/AppStyles.dart';
import 'package:assistantforu/views/widgets/gradient_scaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

enum TimeFrame { Day, Week, Month, Year }

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final RoomService _roomService = RoomService();
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Room? _room;
  List<Task> _tasks = [];
  List<UserModel> _members = [];
  UserModel? _selectedMember;
  TimeFrame _selectedTimeFrame = TimeFrame.Year;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    if (_currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final room = await _roomService.getRoomForUser(_currentUser!.uid);
    if (room != null) {
      final tasks = await _taskService.getTasksForRoom(room.id).first;
      final memberData = await Future.wait(room.members.map((uid) => _userService.getUser(uid)));
      final members = memberData.where((m) => m != null).cast<UserModel>().toList();

      UserModel? selectedMember;
      if (members.isNotEmpty) {
        selectedMember = members.firstWhere(
          (m) => m.uid == _currentUser!.uid,
          orElse: () => members.first,
        );
      }

      if (mounted) {
        setState(() {
          _room = room;
          _tasks = tasks;
          _members = members;
          _selectedMember = selectedMember;
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

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentColor))
          : _room == null
              ? const Center(child: Text('You must be in a room to see analytics', style: AppTextStyles.subtitleStyle))
              : _buildAnalyticsBody(),
    );
  }

  Widget _buildAnalyticsBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 600;
              double cardWidth = isDesktop ? constraints.maxWidth * 0.45 : constraints.maxWidth;
              return Center(
                child: SizedBox(
                  width: cardWidth,
                  child: _buildMemberSelector(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildTimeFrameSelector(),
          const SizedBox(height: 20),
          if (_selectedMember != null) _buildMemberStatistics(),
        ],
      ),
    );
  }

  Widget _buildMemberSelector() {
    return Card(
      color: AppColors.cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: DropdownButtonFormField<UserModel>(
          value: _selectedMember,
          dropdownColor: AppColors.primaryColor,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.accentColor),
          decoration: const InputDecoration(
              border: InputBorder.none,
              labelText: 'Select Member',
              labelStyle: TextStyle(color: AppColors.listTileColor)),
          style: const TextStyle(color: AppColors.textColor),
          items: _members.map((member) {
            return DropdownMenuItem<UserModel>(
              value: member,
              child: Text(member.name ?? member.email ?? member.uid),
            );
          }).toList(),
          onChanged: (UserModel? newValue) {
            setState(() {
              _selectedMember = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTimeFrameSelector() {
    return ToggleButtons(
      isSelected: TimeFrame.values.map((e) => e == _selectedTimeFrame).toList(),
      onPressed: (index) {
        setState(() {
          _selectedTimeFrame = TimeFrame.values[index];
        });
      },
      borderRadius: BorderRadius.circular(50),
      selectedColor: AppColors.primaryColor,
      color: AppColors.textColor,
      fillColor: AppColors.accentColor,
      borderColor: AppColors.accentSecondaryColor,
      selectedBorderColor: AppColors.accentColor,
      children: const [
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Day')),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Week')),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Month')),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Year')),
      ],
    );
  }

  Widget _buildMemberStatistics() {
    final memberTasks = _getFilteredTasks();
    final completedTasks = memberTasks.where((t) => t.status == 'completed').toList();
    final tasksCompletedCount = completedTasks.length;
    final completedOnTime =
        completedTasks.where((t) => t.completedAt != null && !t.completedAt!.toDate().isAfter(t.dueDate.toDate())).length;
    final onTimeCompletionRate = memberTasks.isNotEmpty ? completedOnTime / memberTasks.length : 0.0;
    final completionRate = memberTasks.isNotEmpty ? tasksCompletedCount / memberTasks.length : 0.0;
    final completedLate = tasksCompletedCount - completedOnTime;

    return Column(
      children: [
        const Text(
          'Task Completion Rate',
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
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                            child: Text('Statistics for ${_selectedMember!.name ?? _selectedMember!.email}',
                                style: AppTextStyles.subtitleStyle.copyWith(fontWeight: FontWeight.bold))),
                        const Divider(color: AppColors.listTileColor),
                        _buildStatRow(Icons.list_alt, 'Tasks Assigned', memberTasks.length.toString(), Colors.blue),
                        const Divider(color: AppColors.listTileColor, thickness: 0.5, indent: 8, endIndent: 8),
                        _buildStatRow(Icons.check_circle, 'Tasks Completed', tasksCompletedCount.toString(), Colors.green),
                        const Divider(color: AppColors.listTileColor, thickness: 0.5, indent: 8, endIndent: 8),
                        _buildStatRow(Icons.timer_outlined, 'Completed On Time', completedOnTime.toString(), AppColors.accentColor),
                        const Divider(color: AppColors.listTileColor, thickness: 0.5, indent: 8, endIndent: 8),
                        _buildStatRow(Icons.warning_amber_rounded, 'Completed Late', completedLate.toString(), Colors.orange),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        )
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textColor, fontSize: 16))),
          Text(value, style: const TextStyle(color: AppColors.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<Task> _getFilteredTasks() {
    if (_selectedMember == null) return [];

    DateTime now = DateTime.now();
    return _tasks.where((task) {
      if (!task.assignedTo.contains(_selectedMember!.uid)) return false;

      DateTime taskDate = task.dueDate.toDate();
      switch (_selectedTimeFrame) {
        case TimeFrame.Day:
          return taskDate.year == now.year && taskDate.month == now.month && taskDate.day == now.day;
        case TimeFrame.Week:
          return taskDate.isAfter(now.subtract(const Duration(days: 7))) && taskDate.isBefore(now.add(const Duration(days: 1)));
        case TimeFrame.Month:
          return taskDate.year == now.year && taskDate.month == now.month;
        case TimeFrame.Year:
          return taskDate.year == now.year;
        default:
          return false;
      }
    }).toList();
  }
}
