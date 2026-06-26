import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openwhen/models/capsule.dart';
import 'package:openwhen/services/api_service.dart';

final capsulesProvider = FutureProvider<List<Capsule>>((ref) async {
  return ApiService().getCapsules();
});

final capsuleDetailProvider = FutureProvider.family<Capsule, String>((ref, id) async {
  return ApiService().getCapsule(id);
});
