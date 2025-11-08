import 'package:assistantforu/models/room_model.dart';
import 'package:assistantforu/models/user_model.dart';
import 'package:assistantforu/services/room_service.dart';
import 'package:assistantforu/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/AppStyles.dart';
import '../widgets/gradient_scaffold.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  final RoomService _roomService = RoomService();
  final UserService _userService = UserService(); // Add user service
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  Room? _room;
  Stream<Room?>? _roomStream;
  bool _isLoading = true;

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
            _roomStream = _roomService.getRoomStream(room.id);
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

  void _createRoom() async {
    if (_currentUser == null) return;

    if (_room != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are already in a room.')),
      );
      return;
    }

    Room? newRoom = await _roomService.createRoom(_currentUser!.uid);
    if (newRoom != null) {
      setState(() {
        _room = newRoom;
        _roomStream = _roomService.getRoomStream(newRoom.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room created successfully!')),
      );
    }
  }

  void _joinRoom() {
    final TextEditingController roomIdController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Join Room'),
          content: TextField(
            controller: roomIdController,
            decoration: const InputDecoration(hintText: "Enter Room ID"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final roomId = roomIdController.text;
                Navigator.pop(context);

                if (_currentUser == null || roomId.isEmpty) {
                  return;
                }

                if (_room != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You are already in a room.')),
                  );
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Joining room...')),
                );

                Room? joinedRoom = await _roomService.joinRoom(roomId, _currentUser!.uid);

                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                if (joinedRoom != null) {
                  setState(() {
                    _room = joinedRoom;
                    _roomStream = _roomService.getRoomStream(joinedRoom.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Successfully joined room!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to join room. You might be in a room already or the ID is invalid.')),
                  );
                  _fetchUserRoom();
                }
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
  }

  void _exitRoom() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Exit Room'),
          content: const Text('Are you sure you want to exit this room?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (_currentUser != null && _room != null) {
                  await _roomService.exitRoom(_room!.id, _currentUser!.uid);
                  if (mounted) {
                    setState(() {
                      _room = null;
                      _roomStream = null;
                    });
                  }
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _deleteRoom() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Room'),
          content: const Text('Are you sure you want to delete this room?n cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (_room != null) {
                  await _roomService.deleteRoom(_room!.id);
                  if (mounted) {
                    setState(() {
                      _room = null;
                      _roomStream = null;
                    });
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _removeMember(String memberId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Member'),
          content: const Text('Are you sure you want to remove this member from the room?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (_room != null) {
                  await _roomService.exitRoom(_room!.id, memberId);
                }
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold( // <-- WRAP WITH GRADIENT SCAFFOLD
      body: Builder( // Use a Builder to get the right context if needed, though direct return is fine here
        builder: (context) {
          if (_isLoading) {
            // Still show a loading indicator, but now it's on top of the gradient
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          // This part remains the same, it just decides what to show in the body
          return _room == null ? _buildRoomActions() : _buildTeamView();
        },
      ),
    );
  }

  Widget _buildRoomActions() {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 600;
          double cardWidth = isDesktop ? constraints.maxWidth * 0.35 : constraints.maxWidth;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: cardWidth,
                  child: ElevatedButton(
                    onPressed: _createRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      foregroundColor: AppColors.primaryColor,
                    ),
                    child: const Text('Create Room', style: TextStyle(color: AppColors.primaryColor),),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: cardWidth,
                  child: ElevatedButton(
                    onPressed: _joinRoom,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.accentColor,
                        side: const BorderSide(
                          color: AppColors.accentColor,
                          width: 2,
                        )
                    ),
                    child: const Text('Join Room'),
                  ),
                ),
              ),
            ],
          );
        },
      )
    );
  }

  Widget _buildTeamView() {
    return StreamBuilder<Room?>(
      stream: _roomStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _room != null) {
              setState(() {
                _room = null;
                _roomStream = null;
              });
            }
          });
          return _buildRoomActions();
        }

        _room = snapshot.data!;
        final room = _room!;
        final isLeader = room.leaderId == _currentUser?.uid;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SelectableText(
                'Room ID: ${room.id}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Expanded(child: _buildMembersList(room, isLeader)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: isLeader ? _deleteRoom : _exitRoom,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(isLeader ? 'Delete Room' : 'Exit Room', style: AppTextStyles.buttonText,),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMembersList(Room room, bool isLeader) {
    return ListView.builder(
      itemCount: room.members.length,
      itemBuilder: (context, index) {
        final memberId = room.members[index];
        final isCurrentUser = memberId == _currentUser?.uid;

        return FutureBuilder<UserModel?>(
          future: _userService.getUser(memberId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(title: Text("Loading...", style: TextStyle(color: Colors.white70)));
            }
            if (snapshot.hasError) {
              return ListTile(title: Text('Error loading member', style: TextStyle(color: Colors.red)));
            }
            if (snapshot.hasData) {
              final user = snapshot.data!;
              final skills = user.skills?.join(', ');

              return Card(
                color: AppColors.cardColor,
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: ListTile(
                  title: Text(user.name ?? user.email ?? memberId, style: const TextStyle(color: AppColors.textColor, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    skills != null && skills.isNotEmpty ? skills : 'No skills listed',
                    style: TextStyle(color: AppColors.listTileColor, fontStyle: skills != null && skills.isNotEmpty ? FontStyle.normal : FontStyle.italic),
                  ),
                  trailing: isLeader && !isCurrentUser
                      ? IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () => _removeMember(memberId),
                          tooltip: 'Remove member',
                        )
                      : null,
                ),
              );
            }
            return ListTile(title: Text(memberId)); // Fallback
          },
        );
      },
    );
  }
}
