import 'package:assistantforu/models/message_model.dart';
import 'package:assistantforu/models/room_model.dart';
import 'package:assistantforu/models/user_model.dart';
import 'package:assistantforu/services/chat_service.dart';
import 'package:assistantforu/services/user_service.dart';
import 'package:assistantforu/utils/AppStyles.dart';
import 'package:assistantforu/views/widgets/gradient_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final Room room;

  const ChatPage({super.key, required this.room});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final UserService _userService = UserService();
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() async {
    if (_currentUser != null) {
      final user = await _userService.getUser(_currentUser!.uid);
      if (mounted) {
        setState(() {
          _userModel = user;
        });
      }
    }
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty && _userModel != null) {
      final message = Message(
        senderId: _currentUser!.uid,
        senderName: _userModel!.name ?? _userModel!.email ?? 'Unknown User',
        text: _messageController.text,
        timestamp: Timestamp.now(),
      );
      _chatService.sendMessage(widget.room.id, message);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text('Room Chat', style: AppTextStyles.heading),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(widget.room.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accentColor));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No messages yet.', style: AppTextStyles.subtitleStyle));
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUser!.uid;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        color: isMe ? AppColors.accentColor : AppColors.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.senderName,
                style: TextStyle(
                  fontWeight: FontWeight.bold, color: isMe ? AppColors.primaryColor : AppColors.accentColor,
                  fontSize: 12,
                )
              ),
              const SizedBox(height: 4),
              Text(
                message.text,
                style: TextStyle(
                  color: isMe ? AppColors.primaryColor : AppColors.textColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: AppColors.textColor),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: AppColors.listTileColor),
                filled: true,
                fillColor: AppColors.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.accentColor),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
