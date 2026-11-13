import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ChatMessage {
  final String text;
  final String sender; // 'user' or 'ai'
  final DateTime timestamp;
  final bool isLiveAi;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isLiveAi = false,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'sender': sender,
  };
}

class AiProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isScanning = false;
  bool _isChatting = false;
  String? _errorMessage;

  final List<ChatMessage> _messages = [];
  List<String> _quickSuggestions = [
    'Analisis kondisi keuanganku bulan ini',
    'Pos pengeluaran mana yang paling boros?',
    'Berapa sisa uang aman yang bisa kupakai?',
    'Bagaimana cara mencapai target tabungan lebih cepat?',
  ];

  bool get isScanning => _isScanning;
  bool get isChatting => _isChatting;
  String? get errorMessage => _errorMessage;
  List<ChatMessage> get messages => _messages;
  List<String> get quickSuggestions => _quickSuggestions;

  // 1. Scan Receipt with AI Vision
  Future<Map<String, dynamic>?> scanReceipt(XFile imageFile) async {
    _isScanning = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = imageFile.mimeType ?? 'image/jpeg';

      final res = await _api.post('/ai/scan-receipt', {
        'image': base64Image,
        'mime_type': mimeType,
      });

      if (res['success'] == true && res['data'] != null) {
        _isScanning = false;
        notifyListeners();
        return Map<String, dynamic>.from(res['data']);
      }
      throw Exception('Gagal mengekstrak data struk');
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isScanning = false;
      notifyListeners();
      return null;
    }
  }

  // 2. Chat with Financial Copilot
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Add user message immediately
    _messages.add(ChatMessage(
      text: trimmed,
      sender: 'user',
      timestamp: DateTime.now(),
    ));

    _isChatting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final historyPayload = _messages.map((m) => m.toJson()).toList();

      final res = await _api.post('/ai/chat', {
        'message': trimmed,
        'history': historyPayload,
      });

      if (res['success'] == true && res['reply'] != null) {
        _messages.add(ChatMessage(
          text: res['reply'],
          sender: 'ai',
          timestamp: DateTime.now(),
          isLiveAi: res['is_ai_live'] ?? false,
        ));

        if (res['quick_suggestions'] != null && res['quick_suggestions'] is List) {
          _quickSuggestions = List<String>.from(res['quick_suggestions']);
        }
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _messages.add(ChatMessage(
        text: 'Maaf, terjadi kendala saat menganalisis: $_errorMessage',
        sender: 'ai',
        timestamp: DateTime.now(),
      ));
    } finally {
      _isChatting = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}

