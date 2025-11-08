import 'dart:convert';
import 'package:assistantforu/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  final String _apiKey = 'AIzaSyDaaTqDtwEUEWoUcWlKJGcJM1AbvnAlLr0';

  Future<List<Map<String, dynamic>>> generateSubtasks(
    String taskTitle, 
    String taskDescription, 
    List<UserModel> members
  ) async {
    final model = GenerativeModel(model: 'models/gemini-2.5-pro', apiKey: _apiKey);

    final prompt = _constructPrompt(taskTitle, taskDescription, members);

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final jsonString = response.text;
      
      if (jsonString != null) {
        // Clean the string to remove markdown and trim whitespace
        final cleanedJsonString = jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
        
        try {
          final decodedJson = json.decode(cleanedJsonString);
          if (decodedJson['subtasks'] is List) {
            return List<Map<String, dynamic>>.from(decodedJson['subtasks']);
          }
        } catch (e) {
          debugPrint('Error decoding JSON: ${e.toString()}');
          debugPrint('Cleaned response from AI: $cleanedJsonString');
        }
      }
    } catch (e) {
      debugPrint('Error calling Gemini API: ${e.toString()}');
    }
    return [];
  }

  String _constructPrompt(String title, String description, List<UserModel> members) {
    final membersJson = members.map((m) => '{\n      "uid": "${m.uid}",\n      "name": "${m.name ?? 'N/A'}",\n      "skills": ${json.encode(m.skills ?? [])}\n    }').join(',\n');

    return '''
    As a project manager, your task is to break down the following main task into smaller, actionable subtasks and assign them to the most suitable team member based on their skills.

    **Main Task Title:** $title
    **Main Task Description:** $description

    **Team Members and Their Skills:**
    [
    $membersJson
    ]

    Based on the information above, please generate a list of subtasks. For each subtask, provide a clear title, a detailed description, and the UID of the team member it should be assigned to.

    Your response **MUST** be a valid JSON object with the following structure:
    {
      "subtasks": [
        {
          "title": "Subtask Title",
          "description": "A detailed description of what needs to be done for this subtask.",
          "assignedTo": "uid_of_the_assigned_member"
        }
      ]
    }
    ''';
  }
}
