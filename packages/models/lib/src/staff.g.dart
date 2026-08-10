// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StaffImpl _$$StaffImplFromJson(Map<String, dynamic> json) => _$StaffImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      username: json['username'] as String,
      role: $enumDecode(_$StaffRoleEnumMap, json['role']),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$StaffImplToJson(_$StaffImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'full_name': instance.fullName,
      'email': instance.email,
      'phone_number': instance.phoneNumber,
      'username': instance.username,
      'role': _$StaffRoleEnumMap[instance.role]!,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$StaffRoleEnumMap = {
  StaffRole.owner: 'owner',
  StaffRole.manager: 'manager',
  StaffRole.waiter: 'waiter',
  StaffRole.chef: 'chef',
  StaffRole.cashier: 'cashier',
  StaffRole.deliveryStaff: 'delivery_staff',
};
