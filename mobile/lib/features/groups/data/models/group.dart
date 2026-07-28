class GroupMember {
  const GroupMember({
    required this.userId,
    required this.publicId,
    required this.displayName,
    required this.turnPosition,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId'] as String,
      publicId: json['publicId'] as String,
      displayName: json['displayName'] as String,
      turnPosition: json['turnPosition'] as int?,
    );
  }

  final String userId;
  final String publicId;
  final String displayName;
  final int? turnPosition;
}

class Group {
  const Group({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['ownerId'] as String,
      members: (json['members'] as List<dynamic>)
          .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String name;
  final String ownerId;
  final List<GroupMember> members;
}
