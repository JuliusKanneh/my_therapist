// lib/app/controllers/chat_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../data/models/message_model.dart';
import '../data/models/therapy_session_model.dart';
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
    _initializeChat();
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
    if (user == null) return;

    try {
      _setLoading(true);

      // Try to find an active session
      final activeSessionQuery = await _firestore
          .collection('therapy_sessions')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: SessionStatus.active.name)
          .limit(1)
          .get();

      if (activeSessionQuery.docs.isNotEmpty) {
        // Load existing active session
        final sessionDoc = activeSessionQuery.docs.first;
        _currentSession.value = TherapySessionModel.fromDocument(sessionDoc);
        _startListeningToSession(sessionDoc.id);
        _startListeningToMessages(sessionDoc.id);
      } else {
        // Create new session
        await _createNewSession();
      }
    } catch (e) {
      _setError('Error loading chat session: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create new therapy session
  Future<void> _createNewSession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
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

      _currentSession.value = newSession.copyWith();
      // Update the ID after creation
      _currentSession.value = _currentSession.value!.copyWith();

      _startListeningToSession(docRef.id);
      _startListeningToMessages(docRef.id);

      // Send welcome message
      await _sendWelcomeMessage();
    } catch (e) {
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
    _messagesSubscription?.cancel();
    _messagesSubscription = _firestore
        .collection('messages')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      _messages.value =
          snapshot.docs.map((doc) => MessageModel.fromDocument(doc)).toList();
    });
  }

  // Send user message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _currentSession.value == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
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
      await _firestore.collection('messages').add(userMessage.toDocument());

      // Update session message count
      await _updateSessionMessageCount();

      // Generate AI response
      await _generateAiResponse(content);

      // Update user's last active
      AuthController.instance.updateLastActive();
    } catch (e) {
      _setError('Error sending message: $e');
    }
  }

  // Generate AI response (placeholder for now)
  Future<void> _generateAiResponse(String userMessage) async {
    if (_currentSession.value == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _setAiResponding(true);

      // Simulate AI processing delay
      await Future.delayed(Duration(seconds: 2));

      // Placeholder AI response - we'll integrate real AI later
      String aiResponse = _generatePlaceholderResponse(userMessage);

      // Create AI message
      final aiMessage = MessageModel(
        id: '', // Will be set by Firestore
        userId: user.uid,
        sessionId: _currentSession.value!.id,
        content: aiResponse,
        type: MessageType.ai,
        timestamp: DateTime.now(),
        isProcessed: true,
      );

      // Add AI message to Firestore
      await _firestore.collection('messages').add(aiMessage.toDocument());

      // Update session message count
      await _updateSessionMessageCount();
    } catch (e) {
      _setError('Error generating AI response: $e');
    } finally {
      _setAiResponding(false);
    }
  }

  // Placeholder AI response generator
  String _generatePlaceholderResponse(String userMessage) {
    final responses = [
      "I understand how you're feeling. Can you tell me more about what's been on your mind lately?",
      "Thank you for sharing that with me. It sounds like you're going through a challenging time. How are you coping with these feelings?",
      "Your feelings are completely valid. Many people experience similar thoughts. What would help you feel more supported right now?",
      "I hear you, and I want you to know that you're not alone in this. What activities or thoughts usually bring you comfort?",
      "That's a difficult situation to navigate. How do you usually handle stress or overwhelming emotions?",
    ];

    // Simple keyword-based responses (we'll replace with real AI)
    if (userMessage.toLowerCase().contains('sad') ||
        userMessage.toLowerCase().contains('depressed')) {
      return "I'm sorry you're feeling this way. Depression can be overwhelming, but remember that these feelings are temporary. What small step could you take today to care for yourself?";
    }

    if (userMessage.toLowerCase().contains('anxious') ||
        userMessage.toLowerCase().contains('worried')) {
      return "Anxiety can feel consuming. Let's try to ground ourselves in the present moment. Can you name three things you can see around you right now?";
    }

    // Return random supportive response
    return responses[DateTime.now().millisecond % responses.length];
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
      print('Error updating message count: $e');
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
