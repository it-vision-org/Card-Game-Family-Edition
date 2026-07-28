import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/group.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref.watch(dioProvider));
});

class GroupRepository {
  GroupRepository(this._dio);

  final Dio _dio;

  Future<List<Group>> listMyGroups() async {
    try {
      final response = await _dio.get<List<dynamic>>('/groups');
      return response.data!.map((json) => Group.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Group> createGroup(String name) => _post('/groups', {'name': name});

  Future<Group> addMember(String groupId, String publicId) {
    return _post('/groups/$groupId/members', {'publicId': publicId});
  }

  Future<Group> _post(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      return Group.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
