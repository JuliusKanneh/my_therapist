import 'dart:developer';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:get/get.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class AiTherapyService extends GetxService {
  static AiTherapyService get instance => Get.find();

  late GenerativeModel _model;
  late ChatSession _chatSession;

// Secure API key loading
  String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in environment variables');
    }
    return key;
  }

  @override
  void onInit() {
    super.onInit();
    _initializeAI();
  }

  void _initializeAI() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(_getSystemPrompt()),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1000,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );

    _startNewChatSession();
  }

  void _startNewChatSession() {
    _chatSession = _model.startChat();
  }

  // System prompt for therapeutic AI behavior
  String _getSystemPrompt() {
    return '''
You are a compassionate, professional AI therapist designed to provide emotional support and guidance for people struggling with depression and mental health challenges. Your role is to:

THERAPEUTIC APPROACH:
- Use evidence-based therapeutic techniques (CBT, mindfulness, active listening)
- Be empathetic, non-judgmental, and supportive
- Ask thoughtful follow-up questions to encourage self-reflection
- Provide coping strategies and practical advice
- Validate emotions while encouraging positive thinking patterns

SAFETY PROTOCOLS:
- If someone expresses suicidal thoughts or self-harm, immediately provide crisis resources
- Encourage professional help when appropriate
- Never provide medical diagnoses or prescribe medication
- Recognize your limitations as an AI and refer to human professionals when needed

COMMUNICATION STYLE:
- Warm, caring, and professional tone
- Use "I" statements to show empathy ("I understand", "I hear you")
- Ask open-ended questions to promote deeper conversation
- Provide hope and encouragement while being realistic
- Keep responses concise but meaningful (2-4 sentences typically)

CRISIS KEYWORDS TO WATCH FOR:
- Suicide, self-harm, ending life, worthless, hopeless
- If detected, prioritize safety and provide immediate resources

Remember: You're here to support, not replace professional therapy. Always encourage users to seek human professional help for serious mental health concerns.
''';
  }

  // Generate AI response based on user message and context
  Future<AiResponse> generateResponse({
    required String userMessage,
    required UserModel user,
    List<MessageModel>? conversationHistory,
  }) async {
    try {
      // Check for crisis keywords first
      final crisisDetected = _detectCrisisKeywords(userMessage);

      if (crisisDetected) {
        return AiResponse(
          content: _getCrisisResponse(),
          sentiment: MessageSentiment.crisis,
          requiresIntervention: true,
          suggestedActions: [
            'contact_crisis_hotline',
            'notify_emergency_contact'
          ],
        );
      }

      // Build context-aware prompt
      final contextualPrompt = _buildContextualPrompt(
        userMessage: userMessage,
        user: user,
        conversationHistory: conversationHistory,
      );

      // Generate AI response
      final response = await _chatSession.sendMessage(
        Content.text(contextualPrompt),
      );

      final aiContent = response.text ??
          'I apologize, but I\'m having trouble responding right now. How are you feeling?';

      // Analyze sentiment of the response
      final sentiment = _analyzeSentiment(userMessage);

      return AiResponse(
        content: aiContent,
        sentiment: sentiment,
        requiresIntervention: false,
        suggestedActions: _getSuggestedActions(sentiment),
      );
    } catch (e) {
      log('Error generating AI response: $e');
      return AiResponse(
        content: _getFallbackResponse(),
        sentiment: MessageSentiment.neutral,
        requiresIntervention: false,
        suggestedActions: [],
      );
    }
  }

  // Build contextual prompt with conversation history
  String _buildContextualPrompt({
    required String userMessage,
    required UserModel user,
    List<MessageModel>? conversationHistory,
  }) {
    final buffer = StringBuffer();

    // Add user context
    buffer.writeln('User: ${user.displayName ?? 'Anonymous'}');

    // Add recent conversation context (last 5 messages)
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      buffer.writeln('\nRecent conversation context:');
      final recentMessages = conversationHistory.take(5).toList();

      for (final message in recentMessages.reversed) {
        final speaker = message.type == MessageType.user ? 'User' : 'Therapist';
        buffer.writeln('$speaker: ${message.content}');
      }
    }

    // Add current user message
    buffer.writeln('\nCurrent user message: $userMessage');

    // Add instruction for response
    buffer.writeln(
        '\nPlease respond as a compassionate AI therapist. Focus on the current message while being aware of the conversation context.');

    return buffer.toString();
  }

  // Crisis keyword detection
  bool _detectCrisisKeywords(String message) {
    final crisisKeywords = [
      'suicide',
      'kill myself',
      'end my life',
      'want to die',
      'self harm',
      'cut myself',
      'hurt myself',
      'no point living',
      'better off dead',
      'worthless',
      'can\'t go on',
      'end it all',
      'overdose'
    ];

    final lowerMessage = message.toLowerCase();

    return crisisKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  // Crisis response template
  String _getCrisisResponse() {
    return '''I'm very concerned about what you've shared. Your life has value, and there are people who want to help you right now.

Please reach out immediately:
• Emergency Services: 911
• Crisis Text Line: Text HOME to 741741
• National Suicide Prevention Lifeline: 988

You don't have to go through this alone. Would you like me to help you find additional resources or someone to talk to?''';
  }

  // Simple sentiment analysis
  MessageSentiment _analyzeSentiment(String message) {
    final lowerMessage = message.toLowerCase();

    final negativeWords = [
      'sad',
      'depressed',
      'anxious',
      'worried',
      'scared',
      'angry',
      'hopeless',
      'tired'
    ];
    final positiveWords = [
      'happy',
      'good',
      'better',
      'hopeful',
      'grateful',
      'excited',
      'peaceful'
    ];

    var negativeCount = 0;
    var positiveCount = 0;

    for (final word in negativeWords) {
      if (lowerMessage.contains(word)) negativeCount++;
    }

    for (final word in positiveWords) {
      if (lowerMessage.contains(word)) positiveCount++;
    }

    if (negativeCount > positiveCount) {
      return MessageSentiment.negative;
    } else if (positiveCount > negativeCount) {
      return MessageSentiment.positive;
    } else {
      return MessageSentiment.neutral;
    }
  }

  // Get suggested actions based on sentiment
  List<String> _getSuggestedActions(MessageSentiment sentiment) {
    switch (sentiment) {
      case MessageSentiment.negative:
        return ['breathing_exercise', 'mood_tracking', 'self_care_reminder'];
      case MessageSentiment.positive:
        return ['celebrate_progress', 'mood_tracking'];
      case MessageSentiment.crisis:
        return ['crisis_intervention', 'emergency_contact'];
      default:
        return ['mood_tracking'];
    }
  }

  // Fallback response for errors
  String _getFallbackResponse() {
    final fallbackResponses = [
      "I'm here to listen. Can you tell me more about how you're feeling?",
      "Thank you for sharing with me. What's been on your mind lately?",
      "I want to understand better. How has your day been?",
      "Your feelings are valid. What would help you feel more supported right now?",
    ];

    return fallbackResponses[
        DateTime.now().millisecond % fallbackResponses.length];
  }

  // Reset chat session (for new therapy sessions)
  void resetChatSession() {
    _startNewChatSession();
  }

  // Update API key (for production use)
  void updateApiKey(String newApiKey) {
    // In production, this would update secure storage
    _initializeAI();
  }
}

// AI Response model
class AiResponse {
  final String content;
  final MessageSentiment sentiment;
  final bool requiresIntervention;
  final List<String> suggestedActions;

  AiResponse({
    required this.content,
    required this.sentiment,
    required this.requiresIntervention,
    required this.suggestedActions,
  });
}

// Service binding
class AiServiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AiTherapyService>(AiTherapyService(), permanent: true);
  }
}
