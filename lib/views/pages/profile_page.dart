import 'package:assistantforu/models/user_model.dart';
import 'package:assistantforu/services/room_service.dart';
import 'package:assistantforu/services/user_service.dart';
import 'package:assistantforu/views/pages/login_page.dart';
import 'package:assistantforu/views/widgets/common_scaffold.dart';
import 'package:assistantforu/views/widgets/gradient_scaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/AppStyles.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skillController = TextEditingController();
  final UserService _userService = UserService();
  final RoomService _roomService = RoomService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  UserModel? _userModel;
  List<String> _skills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    if (_currentUser != null) {
      UserModel? user = await _userService.getUser(_currentUser!.uid);
      if (mounted) {
        setState(() {
          if (user != null) {
            _userModel = user;
            _nameController.text = user.name ?? '';
            _skills = user.skills ?? [];
          }
          _isLoading = false;
        });
      }
    }
  }

  void _addSkill() {
    if (_skillController.text.isNotEmpty && !_skills.contains(_skillController.text)) {
      setState(() {
        _skills.add(_skillController.text);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await _userService.updateUser(
        _currentUser!.uid,
        name: _nameController.text,
        skills: _skills,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => CommonScaffold(user: _currentUser!)),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  void _deleteAccount() async {
    if (_currentUser == null) return;

    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _roomService.removeUserFromRoomOnAccountDeletion(_currentUser!.uid);
        await _userService.deleteUser(_currentUser!.uid);
        await _currentUser!.delete();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete account: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text(_userModel?.name == null ? 'Create Your Profile' : 'Edit Your Profile', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color : Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                            borderSide: BorderSide(color: Colors.white, width: 1)
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                          borderSide: BorderSide(color: Colors.white, width: 2)
                        )
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _skillController,
                            style: TextStyle(color : Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Add a skill',
                                labelStyle: TextStyle(color: Colors.white),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(30)),
                                    borderSide: BorderSide(color: Colors.white, width: 1)
                                ),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(30)),
                                    borderSide: BorderSide(color: Colors.white, width: 2)
                                )
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: _addSkill,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _skills.map((skill) {
                        return Chip(
                          label: Text(skill),
                          onDeleted: () => _removeSkill(skill),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 50),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isDesktop = constraints.maxWidth > 600;
                        double buttonWidth = isDesktop ? constraints.maxWidth * 0.35 : constraints.maxWidth;
                        return Center(
                          child: SizedBox(
                            width: buttonWidth,
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: AppButtonStyles.mainButtonStyle,
                              child: const Text('Save Profile',),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isDesktop = constraints.maxWidth > 600;
                        double buttonWidth = isDesktop ? constraints.maxWidth * 0.35 : constraints.maxWidth;
                        return Center(
                          child: SizedBox(
                            width: buttonWidth,
                            child: ElevatedButton(
                              onPressed: _deleteAccount,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Delete Account',),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 150),
                    Divider(
                      color: Colors.white,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    Center(child: Column(
                      children: [
                        Text('TEAM A 4 U', style: TextStyle(color: Colors.white),),
                        Text("ANIRUDH - VENUNADH - THAHA - DILEEP", style: TextStyle(color: Colors.white),),
                        //Text("ANIRUDH VENUNADH THAHA DILEEP(🌧️3️⃣👁️)", style: TextStyle(color: Colors.white),)
                      ],
                    ))
                  ],
                ),
              ),
            ),
    );
  }
}
