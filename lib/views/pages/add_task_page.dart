import 'package:assistantforu/models/room_model.dart';
import 'package:assistantforu/models/task_model.dart';
import 'package:assistantforu/models/user_model.dart';
import 'package:assistantforu/services/ai_service.dart';
import 'package:assistantforu/services/task_service.dart';
import 'package:assistantforu/services/user_service.dart';
import 'package:assistantforu/views/widgets/gradient_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../../utils/AppStyles.dart';

class AddTaskPage extends StatefulWidget {
  final Room room;
  const AddTaskPage({super.key, required this.room});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  final List<String> _selectedMemberIds = [];
  List<Map<String, dynamic>> _generatedSubtasks = [];
  Map<String, String> _memberNames = {};
  bool _isAssigning = false;
  bool _isGenerating = false;
  final Set<int> _assignedSubtaskIndices = {};

  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  final AIService _aiService = AIService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  List<UserModel> _roomMembers = [];
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    _loadRoomMembers();
  }

  void _loadRoomMembers() async {
    List<UserModel> members = [];
    List<String> memberIds = widget.room.members.where((member) => member != _currentUser?.uid).toList();

    for (String memberId in memberIds) {
      UserModel? user = await _userService.getUser(memberId);
      if (user != null) {
        members.add(user);
      }
    }
    if (mounted) {
      setState(() {
        _roomMembers = members;
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _sendTaskNotificationEmail(
      String recipientEmail, String taskTitle, String description, DateTime dueDate) async {
    final smtpServer = gmail('anirudhnaginayanicheruvu.05@gmail.com', 'ocfb flol yrow rosv');

    final message = Message()
      ..from = const Address('anirudhnaginayanicheruvu.05@gmail.com', 'Assistant For U')
      ..recipients.add(recipientEmail)
      ..subject = 'New Task Assigned: $taskTitle'
      ..html = """
      <h1>New Task Assigned</h1>
      <p><b>Task:</b> $taskTitle</p>
      <p><b>Description:</b> $description</p>
      <p><b>Due Date:</b> ${DateFormat.yMd().add_jm().format(dueDate)}</p>
      <p>Please log in to Assistant For U to view the details.</p>
      """;

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      debugPrint('Message not sent. \\n' + e.toString());
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentColor,
              onPrimary: AppColors.primaryColor,
              surface: AppColors.primaryColor,
            ),
            dialogBackgroundColor: AppColors.primaryColor,
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.accentColor,
                onPrimary: AppColors.primaryColor,
                surface: AppColors.primaryColor,
              ),
              dialogBackgroundColor: AppColors.primaryColor,
            ),
            child: child!,
          );
        },
      );
      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _generateSubtasks() async {
    if (!_formKey.currentState!.validate() || _selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and select at least one member to generate tasks for.')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    List<UserModel> selectedMembers = [];
    for (String userId in _selectedMemberIds) {
      UserModel? user = await _userService.getUser(userId);
      if (user != null) {
        selectedMembers.add(user);
      }
    }

    final memberNames = {for (var member in selectedMembers) member.uid: member.name ?? member.email ?? member.uid};

    final subtasks = await _aiService.generateSubtasks(
      _titleController.text,
      _descriptionController.text,
      selectedMembers,
    );

    setState(() {
      _generatedSubtasks = subtasks;
      _memberNames = memberNames;
      _isGenerating = false;
      if (subtasks.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI could not generate subtasks. Please try again.')),
        );
      }
    });
  }

  void _assignMainTask() async {
    if (!_formKey.currentState!.validate() || _dueDate == null || _selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select at least one member.')),
      );
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      Task mainTask = Task(
        id: '',
        roomId: widget.room.id,
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: Timestamp.fromDate(_dueDate!),
        assignedTo: _selectedMemberIds,
      );

      await _taskService.addTask(mainTask);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task assigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }

      // Fire-and-forget email notifications
      for (String memberId in _selectedMemberIds) {
        _userService.getUser(memberId).then((user) {
          if (user?.email != null) {
            _sendTaskNotificationEmail(
              user!.email!,
              mainTask.title,
              mainTask.description ?? '',
              _dueDate!,
            );
          }
        });
      }
    } catch (e) {
      debugPrint("Error assigning main task: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to assign task. Please check logs for details.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
      }
    }
  }

  void _assignSubtaskAsMain(int index, Map<String, dynamic> subtaskData) async {
    if (_assignedSubtaskIndices.contains(index)) return;

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date for the main task first.')),
      );
      return;
    }

    setState(() {
      _assignedSubtaskIndices.add(index);
    });

    try {
      final String assignedUid = subtaskData['assignedTo'];
      final String subtaskTitle = subtaskData['title'] ?? 'Untitled Task';
      final String subtaskDescription = subtaskData['description'] ?? '';

      Task newTask = Task(
        id: '',
        roomId: widget.room.id,
        title: subtaskTitle,
        description: subtaskDescription,
        dueDate: Timestamp.fromDate(_dueDate!),
        assignedTo: [assignedUid],
      );

      await _taskService.addTask(newTask);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task assigned.'), backgroundColor: Colors.green),
        );
      }

      // Fire-and-forget email notification
      _userService.getUser(assignedUid).then((user) {
        if (user?.email != null) {
          _sendTaskNotificationEmail(
            user!.email!,
            newTask.title,
            newTask.description ?? '',
            _dueDate!,
          );
        }
      });

    } catch (e) {
      debugPrint("Error assigning subtask as main task: $e");
      setState(() {
        _assignedSubtaskIndices.remove(index);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to assign subtask. Please check logs for details.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
        appBar: AppBar(
          title: const Text('Add New Task', style: AppTextStyles.heading),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.textColor),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width > 600 ? 600 : double.infinity,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: AppColors.textColor),
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 20),
                          labelText: 'Title',
                          labelStyle: const TextStyle(color: AppColors.listTileColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          )
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: AppColors.textColor),
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 20),
                          labelText: 'Description',
                          labelStyle: const TextStyle(color: AppColors.listTileColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                          )
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(45),
                          border: Border.all(color: AppColors.listTileColor)
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today, color: AppColors.accentColor),
                        title: Text(
                          _dueDate == null
                              ? 'Select Due Date'
                              : 'Due: ${DateFormat.yMd().add_jm().format(_dueDate!)}',
                          style: const TextStyle(color: AppColors.textColor),
                        ),
                        onTap: _selectDueDate,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Members for Task:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textColor, fontSize: 16)),
                    const SizedBox(height: 8),
                    _isLoadingMembers
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _roomMembers.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final member = _roomMembers[index];
                            final displayName = member.name ?? member.email ?? member.uid;
                            return CheckboxListTile(
                              title: Text(displayName, style: const TextStyle(color: AppColors.textColor)),
                              value: _selectedMemberIds.contains(member.uid),
                              activeColor: AppColors.accentColor,
                              checkColor: AppColors.primaryColor,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedMemberIds.add(member.uid);
                                  } else {
                                    _selectedMemberIds.remove(member.uid);
                                  }
                                });
                              },
                            );
                          },
                        ),
                    const SizedBox(height: 16),
                    if (_isGenerating)
                      const Center(child: CircularProgressIndicator(color: AppColors.accentColor))
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.auto_awesome),
                            iconSize: 35,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.accentSecondaryColor),
                              foregroundColor: AppColors.textColor,

                            ),
                            onPressed: _isAssigning ? null : _generateSubtasks,
                          ),
                        ],
                      ),
                    const SizedBox(height: 30),
                    if (_isAssigning)
                      const Center(child: CircularProgressIndicator(color: AppColors.accentColor))
                    else
                      ElevatedButton(
                        style: AppButtonStyles.themeButtonStyle,
                        onPressed: _isGenerating ? null : _assignMainTask,

                        child: const Text('ASSIGN TASK'),
                      ),
                    const SizedBox(height: 16),
                    if (_generatedSubtasks.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Text('Generated Tasks:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textColor)),
                      ),
                    if (_generatedSubtasks.isNotEmpty)
                      ListView.builder(
                        itemCount: _generatedSubtasks.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final subtask = _generatedSubtasks[index];
                          final assignedUid = subtask['assignedTo'];
                          final assignedName = _memberNames[assignedUid] ?? 'Unassigned';
                          final isAssigned = _assignedSubtaskIndices.contains(index);
                          return Card(
                            color: AppColors.cardColor,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              title: Text(subtask['title'] ?? 'No Title', style: const TextStyle(color: AppColors.textColor)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(subtask['description'] ?? 'No Description', style: const TextStyle(color: AppColors.listTileColor)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Assigned to: $assignedName',
                                    style: const TextStyle(
                                      color: AppColors.listTileColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: isAssigned
                                  ? const Icon(Icons.check_circle, color: AppColors.accentColor)
                                  : ElevatedButton(
                                onPressed: () => _assignSubtaskAsMain(index, subtask),
                                style: AppButtonStyles.themeButtonStyle.copyWith(padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 8))),
                                child: const Text('Assign'),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }
}
