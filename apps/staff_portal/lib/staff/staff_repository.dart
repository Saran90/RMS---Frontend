import 'package:api_client/api_client.dart';
import 'package:models/models.dart';

/// A shift scheduled for a specific staff member on a specific date.
class StaffShift {
  const StaffShift({
    required this.id,
    required this.staffId,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
  });

  final String id;
  final String staffId;
  final String shiftDate; // YYYY-MM-DD format
  final String startTime; // HH:MM format (24-hour)
  final String endTime; // HH:MM format (24-hour)
  final DateTime createdAt;

  factory StaffShift.fromJson(Map<String, dynamic> j) => StaffShift(
        id: j['id'] as String,
        staffId: j['staff_id'] as String,
        shiftDate: j['shift_date'] as String,
        startTime: j['start_time'] as String,
        endTime: j['end_time'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'staff_id': staffId,
        'shift_date': shiftDate,
        'start_time': startTime,
        'end_time': endTime,
      };

  /// Returns the day of week (0 = Monday, 6 = Sunday) for this shift's date.
  int get dayOfWeek {
    final date = DateTime.parse(shiftDate);
    return date.weekday - 1; // Convert 1-7 to 0-6
  }

  /// Returns a DateTime object for the shift date.
  DateTime get date => DateTime.parse(shiftDate);
}

/// Requirements: 12.1–12.10
class StaffRepository {
  const StaffRepository({required ApiClient apiClient}) : _client = apiClient;
  final ApiClient _client;

  Future<List<Staff>> getStaff() async {
    final data =
        await _client.get<Map<String, dynamic>>('/api/v1/tenant/staff');
    final staff = data['staff'] as List<dynamic>? ?? [];
    return staff.map((e) => Staff.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> inviteStaff(
      {required String email, required String role}) async {
    await _client.post<dynamic>('/api/v1/tenant/staff/invite',
        body: {'email': email, 'role': role});
  }

  Future<Staff> updateStaffRole(String id, String role) async {
    final data = await _client.patch<Map<String, dynamic>>(
        '/api/v1/tenant/staff/$id',
        body: {'role': role});
    return Staff.fromJson(data);
  }

  Future<Staff> deactivateStaff(String id) async {
    final data = await _client
        .post<Map<String, dynamic>>('/api/v1/tenant/staff/$id/deactivate');
    return Staff.fromJson(data);
  }

  Future<List<StaffShift>> getShifts() async {
    final data =
        await _client.get<Map<String, dynamic>>('/api/v1/tenant/staff/shifts');
    final shifts = data['shifts'] as List<dynamic>? ?? [];
    return shifts
        .map((e) => StaffShift.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StaffShift> saveShift(Map<String, dynamic> payload) async {
    final isUpdate = payload.containsKey('id');
    final id = payload['id'] as String?;

    if (isUpdate && id != null) {
      // Remove id from payload for PATCH request
      final updatePayload = Map<String, dynamic>.from(payload)..remove('id');
      final data = await _client.patch<Map<String, dynamic>>(
        '/api/v1/tenant/staff/shifts/$id',
        body: updatePayload,
      );
      return StaffShift.fromJson(data);
    } else {
      // Create new shift
      final data = await _client.post<Map<String, dynamic>>(
        '/api/v1/tenant/staff/shifts',
        body: payload,
      );
      return StaffShift.fromJson(data);
    }
  }

  Future<void> deleteShift(String id) async {
    await _client.delete('/api/v1/tenant/staff/shifts/$id');
  }
}
