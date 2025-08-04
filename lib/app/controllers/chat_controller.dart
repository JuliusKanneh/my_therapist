// lib/app/controllers/chat_controller.dart
import 'dart:math';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../data/models/message_model.dart';
import '../data/models/therapy_session_model.dart';
import '../data/services/ai_therapy_service.dart'; // Add this import
import '../controllers/auth_controller.dart';

class ChatController extends GetxController {
  static ChatController get instance => Get.find();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reactive variables
  final RxList<MessageModel> _messages = <MessageModel>[].obs;
  final Rx<TherapySessionModel?> _currentSession =
      Rx<TherapySessionModel?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isTyping = false.obs;
  final RxBool _isAiResponding = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<MessageModel> get messages => _messages.reversed.toList();
  TherapySessionModel? get currentSession => _currentSession.value;
  bool get isLoading => _isLoading.value;
  bool get isTyping => _isTyping.value;
  bool get isAiResponding => _isAiResponding.value;
  String get errorMessage => _errorMessage.value;
  bool get hasActiveSession => _currentSession.value?.isActive ?? false;

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  StreamSubscription<DocumentSnapshot>? _sessionSubscription;

  @override
  void onInit() {
    super.onInit();
    developer.log('');
    developer.log('🚀 ========== CHAT CONTROLLER INIT ==========');
    developer.log('⏰ Time: ${DateTime.now()}');

    // DETAILED SERVICE CHECK
    developer.log('📊 CURRENT SERVICE STATUS:');
    developer.log(
        '🔍 AuthController registered? ${Get.isRegistered<AuthController>()}');
    developer.log(
        '🔍 AiTherapyService registered? ${Get.isRegistered<AiTherapyService>()}');

    // Try to access services
    try {
      final authController = Get.find<AuthController>();
      developer.log('✅ AuthController accessible: ${authController.hashCode}');
    } catch (e) {
      developer.log('❌ AuthController not accessible: $e');
    }

    try {
      final aiService = Get.find<AiTherapyService>();
      developer.log('✅ AiTherapyService accessible: ${aiService.hashCode}');
    } catch (e) {
      developer.log('❌ AiTherapyService not accessible: $e');
      developer.log('⚠️ Will register AI service directly...');

      try {
        Get.put<AiTherapyService>(AiTherapyService(), permanent: true);
        developer.log('✅ AI service registered directly in ChatController');

        // Verify registration
        final newService = Get.find<AiTherapyService>();
        developer.log('✅ AI service now accessible: ${newService.hashCode}');
      } catch (createError) {
        developer.log('❌ Failed to register AI service: $createError');
      }
    }

    _initializeChat();

    // Force initialization if user is already logged in
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      developer.log('👤 User already logged in, loading session...');
      Future.delayed(Duration(milliseconds: 100), () {
        _loadOrCreateSession();
      });
    }

    developer.log('🏁 ========== CHAT CONTROLLER INIT COMPLETE ==========');
    developer.log('');
  }

  @override
  void onClose() {
    _messagesSubscription?.cancel();
    _sessionSubscription?.cancel();
    super.onClose();
  }

  // Initialize chat functionality
  void _initializeChat() {
    // Listen to auth state changes
    ever(AuthController.instance.firebaseUserStream, (User? user) {
      developer.log('🔄 Auth state changed. User: ${user?.uid ?? 'null'}');
      if (user != null) {
        _loadOrCreateSession();
      } else {
        _clearChat();
      }
    });
  }

  // Load existing session or create new one
  Future<void> _loadOrCreateSession() async {
    final user = _auth.currentUser;
    if (user == null) {
      developer.log('❌ No authenticated user found');
      return;
    }

    try {
      _setLoading(true);
      developer.log('🔍 Loading session for user: ${user.uid}');

      // Try to find an active session
      final activeSessionQuery = await _firestore
          .collection('therapy_sessions')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: SessionStatus.active.name)
          .limit(1)
          .get();

      developer
          .log('📊 Found ${activeSessionQuery.docs.length} active sessions');

      if (activeSessionQuery.docs.isNotEmpty) {
        // Load existing active session
        final sessionDoc = activeSessionQuery.docs.first;
        _currentSession.value = TherapySessionModel.fromDocument(sessionDoc);
        developer.log('✅ Loaded existing session: ${sessionDoc.id}');

        _startListeningToSession(sessionDoc.id);
        _startListeningToMessages(sessionDoc.id);
      } else {
        // Create new session
        developer.log('🆕 Creating new session...');
        await _createNewSession();
      }
    } catch (e) {
      developer.log('❌ Error loading session: $e');
      _setError('Error loading chat session: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create new therapy session
  Future<void> _createNewSession() async {
    final user = _auth.currentUser;
    if (user == null) {
      developer.log('❌ No user for session creation');
      return;
    }

    try {
      developer.log('🆕 Creating new session for user: ${user.uid}');

      final newSession = TherapySessionModel(
        id: '', // Will be set by Firestore
        userId: user.uid,
        startTime: DateTime.now(),
        status: SessionStatus.active,
        topics: [],
      );

      final docRef = await _firestore
          .collection('therapy_sessions')
          .add(newSession.toDocument());

      developer.log('✅ Session created with ID: ${docRef.id}');

      // Create updated session with the actual ID
      _currentSession.value = TherapySessionModel(
        id: docRef.id,
        userId: user.uid,
        startTime: DateTime.now(),
        status: SessionStatus.active,
        topics: [],
      );

      _startListeningToSession(docRef.id);
      _startListeningToMessages(docRef.id);

      // Send welcome message
      await _sendWelcomeMessage();

      developer.log('🎉 Session setup complete!');
    } catch (e) {
      developer.log('❌ Error creating session: $e');
      _setError('Error creating new session: $e');
    }
  }

  // Start listening to session updates
  void _startListeningToSession(String sessionId) {
    _sessionSubscription?.cancel();
    _sessionSubscription = _firestore
        .collection('therapy_sessions')
        .doc(sessionId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        _currentSession.value = TherapySessionModel.fromDocument(doc);
      }
    });
  }

  // Start listening to messages
  void _startListeningToMessages(String sessionId) {
    developer.log('👂 Starting to listen to messages for session: $sessionId');
    _messagesSubscription?.cancel();

    try {
      _messagesSubscription = _firestore
          .collection('messages')
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .listen(
        (snapshot) {
          developer.log('📬 Received ${snapshot.docs.length} messages');
          _messages.value = snapshot.docs
              .map((doc) => MessageModel.fromDocument(doc))
              .toList();
          developer.log('💬 Messages updated in controller');
        },
        onError: (error) {
          developer.log('❌ Error listening to messages: $error');
          _setError('Error loading messages: $error');
        },
      );
    } catch (e) {
      developer.log('❌ Error setting up message listener: $e');
      _setError('Error setting up message listener: $e');
    }
  }

  // Send user message
  Future<void> sendMessage(String content) async {
    developer.log('📤 Attempting to send message: "$content"');
    developer.log('👤 Current User: ${_auth.currentUser?.uid ?? 'null'}');
    developer.log('💬 Current Session: ${_currentSession.value?.id ?? 'null'}');

    if (content.trim().isEmpty) {
      developer.log('❌ Message is empty');
      return;
    }

    if (_currentSession.value == null) {
      developer.log('❌ No current session, attempting to create one...');
      await _loadOrCreateSession();

      // Wait a moment for session creation
      await Future.delayed(Duration(milliseconds: 500));

      if (_currentSession.value == null) {
        developer.log('❌ Still no session after creation attempt');
        _setError('Unable to create chat session. Please try again.');
        return;
      }
    }

    final user = _auth.currentUser;
    if (user == null) {
      developer.log('❌ No authenticated user');
      return;
    }

    try {
      developer
          .log('✅ Sending message to session: ${_currentSession.value!.id}');

      // Create user message
      final userMessage = MessageModel(
        id: '', // Will be set by Firestore
        userId: user.uid,
        sessionId: _currentSession.value!.id,
        content: content.trim(),
        type: MessageType.user,
        timestamp: DateTime.now(),
      );

      // Add message to Firestore
      final docRef =
          await _firestore.collection('messages').add(userMessage.toDocument());
      developer.log('✅ Message sent with ID: ${docRef.id}');

      // Update session message count
      await _updateSessionMessageCount();

      // Generate AI response
      await _generateAiResponse(content);

      // Update user's last active
      AuthController.instance.updateLastActive();
    } catch (e) {
      developer.log('❌ Error sending message: $e');
      _setError('Error sending message: $e');
    }
  }

  // Generate AI response using real AI service
  Future<void> _generateAiResponse(String userMessage) async {
    if (_currentSession.value == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _setAiResponding(true);
      developer.log('🤖 Generating AI response for: "$userMessage"');

      // Get user model for context
      final userModel = AuthController.instance.userModel;
      if (userModel == null) {
        developer.log('❌ No user model available');
        await _sendFallbackMessage();
        return;
      }

      // Check if AI service is available - with more detailed logging
      developer.log('🔍 Checking if AI service is registered...');
      developer.log(
          '🔍 Get.isRegistered<AiTherapyService>(): ${Get.isRegistered<AiTherapyService>()}');

      // Try to get the AI service instance directly
      AiTherapyService? aiService;
      try {
        aiService = Get.find<AiTherapyService>();
        developer.log('✅ AI service found successfully');
      } catch (e) {
        developer.log('❌ Failed to find AI service: $e');
        developer.log('🔧 Attempting to create AI service...');
        try {
          Get.put<AiTherapyService>(AiTherapyService(), permanent: true);
          aiService = Get.find<AiTherapyService>();
          developer.log('✅ AI service created and found');
        } catch (createError) {
          developer.log('❌ Failed to create AI service: $createError');
          await _sendFallbackMessage();
          return;
        }
      }

      developer.log('🚀 Calling generateResponse...');
      // Generate AI response using the therapy service
      final aiResponse = await aiService.generateResponse(
        userMessage: userMessage,
        user: userModel,
        conversationHistory:
            _messages.take(10).toList(), // Last 10 messages for context
      );

      developer.log('✅ AI response generated successfully!');
      developer.log(
          '📝 Response preview: ${aiResponse.content.substring(0, min(100, aiResponse.content.length))}...');
      developer.log('💭 Sentiment: ${aiResponse.sentiment}');
      developer
          .log('🚨 Requires intervention: ${aiResponse.requiresIntervention}');

      // Handle crisis intervention if needed
      if (aiResponse.requiresIntervention) {
        developer.log('🚨 Crisis intervention required');
        await _handleCrisisIntervention(aiResponse);
      }

      // Create AI message with sentiment analysis
      final aiMessage = MessageModel(
        id: '', // Will be set by Firestore
        userId: user.uid,
        sessionId: _currentSession.value!.id,
        content: aiResponse.content,
        type: MessageType.ai,
        timestamp: DateTime.now(),
        sentiment: aiResponse.sentiment,
        isProcessed: true,
        metadata: {
          'suggestedActions': aiResponse.suggestedActions,
          'requiresIntervention': aiResponse.requiresIntervention,
        },
      );

      developer.log('💾 Saving AI message to Firestore...');
      // Add AI message to Firestore
      await _firestore.collection('messages').add(aiMessage.toDocument());
      developer.log('✅ AI message saved to Firestore successfully');

      // Update session message count and topics
      await _updateSessionWithAiInsights(aiResponse);
    } catch (e, stackTrace) {
      developer.log('❌ Error in AI response generation: $e');
      developer.log('📍 Stack trace: $stackTrace');
      _setError('Error generating AI response: $e');

      // Send fallback message on error
      await _sendFallbackMessage();
    } finally {
      _setAiResponding(false);
    }
  }

  // Handle crisis intervention
  Future<void> _handleCrisisIntervention(AiResponse aiResponse) async {
    try {
      // Create crisis alert document
      final user = _auth.currentUser;
      if (user == null) return;

      final crisisAlert = {
        'userId': user.uid,
        'sessionId': _currentSession.value!.id,
        'timestamp': FieldValue.serverTimestamp(),
        'severity': 'high',
        'triggerMessage': _messages.isNotEmpty ? _messages.first.content : '',
        'aiResponse': aiResponse.content,
        'suggestedActions': aiResponse.suggestedActions,
        'status': 'active',
      };

      await _firestore.collection('crisis_alerts').add(crisisAlert);

      // Show crisis dialog to user
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.emergency, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Crisis Support'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'I\'m concerned about your wellbeing. Please know that help is available.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Text('Immediate Help:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Crisis Text Line: Text HOME to 741741'),
                    Text('National Suicide Prevention Lifeline: 988'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('I understand'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      developer.log('Error handling crisis intervention: $e');
    }
  }

  // Update session with AI insights
  Future<void> _updateSessionWithAiInsights(AiResponse aiResponse) async {
    if (_currentSession.value == null) return;

    try {
      final currentCount = _messages.length;
      final updateData = {
        'messageCount': currentCount,
        'lastActivity': FieldValue.serverTimestamp(),
      };

      // Add suggested topics based on AI analysis
      if (aiResponse.suggestedActions.isNotEmpty) {
        updateData['suggestedTopics'] =
            FieldValue.arrayUnion(aiResponse.suggestedActions);
      }

      await _firestore
          .collection('therapy_sessions')
          .doc(_currentSession.value!.id)
          .update(updateData);
    } catch (e) {
      developer.log('Error updating session with AI insights: $e');
    }
  }

  // Send fallback message when AI fails
  Future<void> _sendFallbackMessage() async {
    if (_currentSession.value == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final fallbackMessage = MessageModel(
      id: '',
      userId: user.uid,
      sessionId: _currentSession.value!.id,
      content:
          "I apologize, but I'm having some technical difficulties right now. Your wellbeing is important to me. How are you feeling at this moment?",
      type: MessageType.ai,
      timestamp: DateTime.now(),
      sentiment: MessageSentiment.neutral,
      isProcessed: true,
      metadata: {'isFallback': true},
    );

    await _firestore.collection('messages').add(fallbackMessage.toDocument());
  }

  // Send welcome message
  Future<void> _sendWelcomeMessage() async {
    if (_currentSession.value == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final welcomeMessage = MessageModel(
      id: '',
      userId: user.uid,
      sessionId: _currentSession.value!.id,
      content:
          "Hello! I'm here to listen and support you. How are you feeling today? Feel free to share whatever is on your mind.",
      type: MessageType.ai,
      timestamp: DateTime.now(),
      isProcessed: true,
    );

    await _firestore.collection('messages').add(welcomeMessage.toDocument());
  }

  // Update session message count
  Future<void> _updateSessionMessageCount() async {
    if (_currentSession.value == null) return;

    try {
      final currentCount = _messages.length;
      await _firestore
          .collection('therapy_sessions')
          .doc(_currentSession.value!.id)
          .update({'messageCount': currentCount});
    } catch (e) {
      developer.log('Error updating message count: $e');
    }
  }

  // End current session
  Future<void> endSession() async {
    if (_currentSession.value == null) return;

    try {
      _setLoading(true);

      final updatedSession = _currentSession.value!.copyWith(
        status: SessionStatus.completed,
        endTime: DateTime.now(),
      );

      await _firestore
          .collection('therapy_sessions')
          .doc(_currentSession.value!.id)
          .update(updatedSession.toDocument());

      Get.snackbar(
        'Session Ended',
        'Your therapy session has been completed',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Create new session for next conversation
      await _createNewSession();
    } catch (e) {
      _setError('Error ending session: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Clear chat data
  void _clearChat() {
    _messages.clear();
    _currentSession.value = null;
    _messagesSubscription?.cancel();
    _sessionSubscription?.cancel();
  }

  // Helper methods
  void _setLoading(bool value) => _isLoading.value = value;
  void _setAiResponding(bool value) => _isAiResponding.value = value;
  void _setError(String message) => _errorMessage.value = message;
  void _clearError() => _errorMessage.value = '';
}
