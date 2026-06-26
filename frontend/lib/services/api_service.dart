import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:openwhen/config/env.dart';
import 'package:openwhen/models/capsule.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Dio get _dio => Dio(BaseOptions(baseUrl: apiBaseUrl));

  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.getIdToken();
  }

  Future<Options> _authOptions() async {
    final token = await _getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Map<String, dynamic>> verifyUser() async {
    final token = await _getToken();
    final res = await _dio.post('/auth/verify', data: {'id_token': token});
    return res.data as Map<String, dynamic>;
  }

  Future<List<Capsule>> getCapsules() async {
    final opts = await _authOptions();
    final res = await _dio.get('/capsules', options: opts);
    return (res.data as List).map((e) => Capsule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Capsule> createCapsule({
    String? title,
    required String content,
    required String mode,
    required DateTime openDate,
    String? notificationEmail,
    List<Map<String, dynamic>> answers = const [],
  }) async {
    final opts = await _authOptions();
    final res = await _dio.post('/capsules', options: opts, data: {
      'title': title,
      'content': content,
      'mode': mode,
      'open_date': openDate.toIso8601String().split('T').first,
      'notification_email': notificationEmail,
      'answers': answers,
    });
    return Capsule.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Capsule> getCapsule(String id) async {
    final opts = await _authOptions();
    final res = await _dio.get('/capsules/$id', options: opts);
    return Capsule.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Capsule> openCapsule(String id) async {
    final opts = await _authOptions();
    final res = await _dio.post('/capsules/$id/open', options: opts);
    return Capsule.fromJson(res.data as Map<String, dynamic>);
  }

  Future<String> generateLetter(List<Map<String, dynamic>> answers) async {
    final opts = await _authOptions();
    final res = await _dio.post('/ai/generate-letter', options: opts, data: {'answers': answers});
    return res.data['letter'] as String;
  }

  Future<List<String>> generateReflections(String letterContent) async {
    final opts = await _authOptions();
    final res = await _dio.post('/ai/generate-reflections', options: opts, data: {'letter_content': letterContent});
    return (res.data['questions'] as List).cast<String>();
  }

  Future<List<Reflection>> saveReflections(String capsuleId, List<Reflection> reflections) async {
    final opts = await _authOptions();
    final res = await _dio.post('/capsules/$capsuleId/reflections', options: opts, data: {
      'reflections': reflections.map((r) => {'question_text': r.questionText, 'answer_text': r.answerText}).toList(),
    });
    return (res.data as List).map((e) => Reflection.fromJson(e as Map<String, dynamic>)).toList();
  }
}
