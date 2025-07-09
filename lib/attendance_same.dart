class AttendanceRecord {
  final String date;
  final String createdAt;
  final String staffId;
  final String staffAttendanceTypeId;
  final String location;
  final String? inTime;
  final String? outTime;
  final String? status;
  final String? remark;

  AttendanceRecord({
    required this.date,
    required this.createdAt,
    required this.staffId,
    required this.staffAttendanceTypeId,
    required this.location,
    this.inTime,
    this.outTime,
    this.status,
    this.remark,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: json['date'] ?? 'No Date',
      createdAt: json['created_at'] ?? 'No Created At',
      staffId: json['staff_id'] ?? 'No Staff ID',
      staffAttendanceTypeId: json['staff_attendance_type_id'] ?? 'No Type ID',
      location: json['location'] ?? 'No Location',
      inTime: json['In_Time'],
      outTime: json['Out_Time'],
      status: (json['status'] ?? 'Absent').isEmpty ? 'Absent' : json['status'],
      remark: json['remark'],
    );
  }
}