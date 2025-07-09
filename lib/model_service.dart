class LoginResponse {
  final bool status;
  final String message;
  final LoginData? data;

  LoginResponse({required this.status, required this.message, this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }
}

class LoginData {
  final String name;
  final String email;
  final String role;
  final String employeeId;
  final String staffid;
  final String id;

  LoginData({
    required this.name,
    required this.email,
    required this.role,
    required this.employeeId,
    required this.staffid,
    required this.id

  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      employeeId: json['employeeId'] ?? '',
      staffid:json['staffid'] ?? '',
      id:json['id'] ?? '',

    );
  }
}

class AttendanceRecord {
  final String date;
  final String staffId;
  final String location;
  final String? inTime;
  final String? outTime;
  final String? status;
  final String? remark;

  AttendanceRecord({
    required this.date,
    required this.staffId,
    required this.location,
    this.inTime,
    this.outTime,
    this.status,
    this.remark,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: json['date'] ?? '',
      staffId: json['staff_id'] ?? '',
      location: json['location'] ?? '',
      inTime: json['In_Time'],
      outTime: json['Out_Time'],
      status: json['status'],
      remark: json['remark'],
    );
  }
}


class AttendanceHistoryModel {
  final String date;
  final String? inTime;
  final String? outTime;
  final String? location;
  final String status; // Changed to non-nullable as it will always have a mapped status
  final String? remark;

  AttendanceHistoryModel({
    required this.date,
    this.inTime,
    this.outTime,
    this.location,
    required this.status, // Now required
    this.remark,
  });

  factory AttendanceHistoryModel.fromJson(Map<String, dynamic> json) {
    // Map the status string from the backend to ensure consistency
    String mappedStatus = json['status'] ?? 'Unknown';

    // Handle cases where in_time/out_time might be "00:00:00" or empty,
    // and if the status is not explicitly "Absent", mark it as "Absent"
    // if in_time and out_time are effectively empty/zero.
    // This logic should ideally be handled more robustly by your backend
    // but we can add a fallback here.
    if (mappedStatus == 'Present' && (json['in_time'] == null || json['in_time'] == "00:00:00" || json['in_time'].isEmpty)) {
      mappedStatus = 'Absent';
    }


    return AttendanceHistoryModel(
      date: json['date'] ?? '',
      inTime: json['in_time'], // Ensure these keys match your PHP output
      outTime: json['out_time'], // Ensure these keys match your PHP output
      location: json['location'],
      status: mappedStatus,
      remark: json['remark'],
    );
  }
}