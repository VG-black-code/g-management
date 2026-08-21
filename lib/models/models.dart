import 'package:flutter/material.dart';

class Issue {
  final int? id;
  final String? complaintId; 
  final String? userId; 
  final String? userName;
  final String? usn; 
  final String? department; 
  final String? course; 
  final String? year; 
  final String? section; 
  final String? category; 
  final String? problemType; 
  final String? description;
  final String? location;
  final String? photoUrl;
  final String? status; 
  final String? priority; 
  final String? currentAuthorityId; 
  final String? currentAuthorityRole; 
  final String? assignedTo;
  final String? createdAt;
  final String? updatedAt;
  final String? processingAt;
  final String? resolvedAt;

  Issue({
    this.id,
    this.complaintId,
    this.userId,
    this.userName,
    this.usn,
    this.department,
    this.course,
    this.year,
    this.section,
    this.category,
    this.problemType,
    this.description,
    this.location,
    this.photoUrl,
    this.status,
    this.priority,
    this.currentAuthorityId,
    this.currentAuthorityRole,
    this.assignedTo,
    this.createdAt,
    this.updatedAt,
    this.processingAt,
    this.resolvedAt,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'],
      complaintId: (json['complaint_id'] ?? json['ComplaintID'])?.toString(),
      userId: (json['user_id'] ?? json['UserID'])?.toString(),
      userName: (json['user_name'] ?? json['UserName'] ?? json['FullName'])?.toString(),
      usn: (json['usn'] ?? json['USN'] ?? json['StudentID'])?.toString(),
      department: (json['department'] ?? json['Department'])?.toString(),
      course: (json['course'] ?? json['Course'])?.toString(),
      year: (json['year'] ?? json['Year'])?.toString(),
      section: (json['section'] ?? json['Section'])?.toString(),
      category: (json['category'] ?? json['Category'])?.toString(),
      problemType: (json['problem_type'] ?? json['ProblemType'] ?? json['IssueType'])?.toString(),
      description: (json['description'] ?? json['Description'])?.toString(),
      location: (json['location'] ?? json['Location'])?.toString(),
      photoUrl: (json['photo_url'] ?? json['PhotoUrl'] ?? json['PhotoURL'])?.toString(),
      status: (json['status'] ?? json['Status'])?.toString(),
      priority: (json['priority'] ?? json['Priority'])?.toString(),
      currentAuthorityId: (json['current_authority_id'] ?? json['CurrentAuthorityID'])?.toString(),
      currentAuthorityRole: (json['current_authority_role'] ?? json['CurrentAuthorityRole'] ?? json['current_author'])?.toString(),
      assignedTo: (json['assigned_to'] ?? json['AssignedTo'] ?? json['assigned_staff'])?.toString(),
      createdAt: (json['created_at'] ?? json['CreatedAt'])?.toString(),
      updatedAt: (json['updated_at'] ?? json['UpdatedAt'])?.toString(),
      processingAt: (json['processing_at'] ?? json['ProcessingAt'])?.toString(),
      resolvedAt: (json['resolved_at'] ?? json['ResolvedAt'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (complaintId != null) 'complaint_id': complaintId,
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (usn != null) 'usn': usn,
      if (department != null) 'department': department,
      if (course != null) 'course': course,
      if (year != null) 'year': year,
      if (section != null) 'section': section,
      if (category != null) 'category': category,
      if (problemType != null) 'problem_type': problemType,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (currentAuthorityId != null) 'current_authority_id': currentAuthorityId,
      if (currentAuthorityRole != null) 'current_authority_role': currentAuthorityRole,
      if (assignedTo != null) 'assigned_to': assignedTo,
    };
  }
}

class ComplaintHistory {
  final int? id;
  final int? issueId;
  final String? performedByName;
  final String? performedByRole;
  final String? toAuthorityRole;
  final String? action; 
  final String? status;
  final String? comment;
  final String? createdAt;

  ComplaintHistory({
    this.id,
    this.issueId,
    this.performedByName,
    this.performedByRole,
    this.toAuthorityRole,
    this.action,
    this.status,
    this.comment,
    this.createdAt,
  });

  factory ComplaintHistory.fromJson(Map<String, dynamic> json) {
    return ComplaintHistory(
      id: json['id'],
      issueId: json['issue_id'] ?? json['IssueID'],
      performedByName: (json['performed_by_name'] ?? json['PerformedByName'])?.toString(),
      performedByRole: (json['performed_by_role'] ?? json['PerformedByRole'])?.toString(),
      toAuthorityRole: (json['to_authority_role'] ?? json['ToAuthorityRole'])?.toString(),
      action: (json['action'] ?? json['Action'])?.toString(),
      status: (json['status'] ?? json['Status'])?.toString(),
      comment: (json['comment'] ?? json['Comment'])?.toString(),
      createdAt: (json['created_at'] ?? json['CreatedAt'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'issue_id': issueId,
      if (performedByName != null) 'performed_by_name': performedByName,
      if (performedByRole != null) 'performed_by_role': performedByRole,
      if (toAuthorityRole != null) 'to_authority_role': toAuthorityRole,
      'action': action,
      'status': status,
      'comment': comment,
    };
  }
}

class UserProfile {
  final String id;
  final String? fullName;
  final String? emailId;
  final String? mobileNumber;
  final String? gender;
  final String? userRole; 
  final String? studentId;
  final String? facultyId;
  final String? department; 
  final String? course;
  final String? program;
  final String? year; 
  final String? section; 
  final String? semester;
  final String? collegeName;
  final String? dob;
  final String? adminId;
  final String? position;
  final String? designation;
  final String? profileImage;
  final String? joiningDate;
  final bool isApproved;
  final bool isActive;
  final List<String>? assignedDepartments; 

  UserProfile({
    required this.id,
    this.fullName,
    this.emailId,
    this.mobileNumber,
    this.gender,
    this.userRole,
    this.studentId,
    this.facultyId,
    this.department,
    this.course,
    this.program,
    this.year,
    this.section,
    this.semester,
    this.collegeName,
    this.dob,
    this.adminId,
    this.position,
    this.designation,
    this.profileImage,
    this.joiningDate,
    this.isApproved = false,
    this.isActive = true,
    this.assignedDepartments,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      fullName: (json['full_name'] ?? json['FullName'] ?? json['name'])?.toString(),
      emailId: (json['email_id'] ?? json['Email'] ?? json['email'])?.toString(),
      mobileNumber: (json['mobile_number'] ?? json['MobileNumber'] ?? json['phone'])?.toString(),
      gender: (json['gender'] ?? json['Gender'] ?? json['sex'])?.toString(),
      userRole: (json['user_role'] ?? json['role'] ?? json['Role'])?.toString(),
      studentId: (json['student_id'] ?? json['StudentID'])?.toString(),
      facultyId: (json['faculty_id'] ?? json['FacultyID'] ?? json['EmployeeID'])?.toString(),
      department: (json['department'] ?? json['Department'])?.toString(),
      course: (json['course'] ?? json['Course'])?.toString(),
      program: (json['program'] ?? json['Program'])?.toString(),
      year: (json['year'] ?? json['Year'])?.toString(),
      section: (json['section'] ?? json['Section'])?.toString(),
      semester: (json['semester'] ?? json['Semester'])?.toString(),
      collegeName: (json['college_name'] ?? json['CollegeName'])?.toString(),
      dob: (json['dob'] ?? json['DOB'] ?? json['date_of_birth'])?.toString(),
      adminId: (json['admin_id'] ?? json['AdminID'])?.toString(),
      position: (json['position'] ?? json['Position'])?.toString(),
      designation: (json['designation'] ?? json['Designation'])?.toString(),
      profileImage: (json['profile_image'] ?? json['ProfileImage'])?.toString(),
      joiningDate: (json['joining_date'] ?? json['JoiningDate'])?.toString(),
      isApproved: json['is_approved'] == true || json['is_approved'] == 1 || json['is_approved']?.toString().toLowerCase() == 'true' || json['IsApproved'] == true,
      isActive: json['is_active'] != false && json['is_active'] != 0 && json['is_active']?.toString().toLowerCase() != 'false' && json['IsActive'] != false,
      assignedDepartments: json['assigned_departments'] != null 
          ? List<String>.from(json['assigned_departments']) 
          : (json['AssignedDepartments'] != null ? List<String>.from(json['AssignedDepartments']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email_id': emailId,
      'mobile_number': mobileNumber,
      'gender': gender,
      'user_role': userRole,
      'is_approved': isApproved,
      'is_active': isActive,
      if (studentId != null) 'student_id': studentId,
      if (facultyId != null) 'faculty_id': facultyId,
      if (department != null) 'department': department,
      if (course != null) 'course': course,
      if (program != null) 'program': program,
      if (year != null) 'year': year,
      if (section != null) 'section': section,
      if (semester != null) 'semester': semester,
      if (collegeName != null) 'college_name': collegeName,
      if (dob != null) 'dob': dob,
      if (adminId != null) 'admin_id': adminId,
      if (position != null) 'position': position,
      if (designation != null) 'designation': designation,
      if (profileImage != null) 'profile_image': profileImage,
      if (joiningDate != null) 'joining_date': joiningDate,
      if (assignedDepartments != null) 'assigned_departments': assignedDepartments,
    };
  }
}

class AppNotification {
  final int? id;
  final String? userName;
  final String? title;
  final String? message;
  final bool isRead;
  final String? createdAt;
  final int? issueId;
  final String? changes;

  AppNotification({
    this.id,
    this.userName,
    this.title,
    this.message,
    this.isRead = false,
    this.createdAt,
    this.issueId,
    this.changes,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userName: (json['user_name'] ?? json['UserName'])?.toString(),
      title: (json['title'] ?? json['Title'])?.toString(),
      message: (json['message'] ?? json['Message'])?.toString(),
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read']?.toString().toLowerCase() == 'true',
      createdAt: (json['created_at'] ?? json['CreatedAt'])?.toString(),
      issueId: json['issue_id'] ?? json['IssueID'],
      changes: (json['changes'] ?? json['Changes'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_name': userName,
      'title': title,
      'message': message,
      'is_read': isRead,
      if (issueId != null) 'issue_id': issueId,
      if (changes != null) 'changes': changes,
    };
  }
}

class Constants {
  static const List<String> categories = ['Academic', 'General'];
  static const List<String> departments = ['BCA', 'BBA', 'BA', 'BCOM', 'MCA', 'MCOM', 'BHM'];
  static const List<String> roles = ['Student', 'Teacher', 'HOD', 'Dean', 'Principal', 'Admin'];
  
  static const List<String> locations = [
    'Main Building',
    'Science Block',
    'Arts Block',
    'Library',
    'Hostel A',
    'Hostel B',
    'Cafeteria',
    'Sports Complex',
    'Parking Area'
  ];

  static const Map<String, List<String>> academicProblems = {
    'Academic': [
      'Syllabus Pending', 'Syllabus Not Completed', 'Not Proper Teacher', 
      'Can\'t Understand Classes', 'Teaching Quality', 'Teacher Absence', 
      'Teacher Behavior', 'Subject Problem', 'Assignment Problem', 
      'Exam Problem', 'Timetable Problem', 'Other Academic Issue'
    ]
  };

  static const Map<String, List<String>> generalProblems = {
    'General': [
      'Broken Bench', 'Broken Desk', 'Water Problem', 'Washroom Problem', 
      'Cleanliness', 'Electricity Problem', 'Fan Problem', 'Light Problem', 
      'Classroom Infrastructure', 'Maintenance', 'Security', 'Campus Facility', 'Other'
    ]
  };

  static const Map<String, List<String>> problemTypes = {
    'Academic': [
      'Syllabus Pending', 'Syllabus Not Completed', 'Not Proper Teacher', 
      'Can\'t Understand Classes', 'Teaching Quality', 'Teacher Absence', 
      'Teacher Behavior', 'Subject Problem', 'Assignment Problem', 
      'Exam Problem', 'Timetable Problem', 'Other Academic Issue'
    ],
    'General': [
      'Broken Bench', 'Broken Desk', 'Water Problem', 'Washroom Problem', 
      'Cleanliness', 'Electricity Problem', 'Fan Problem', 'Light Problem', 
      'Classroom Infrastructure', 'Maintenance', 'Security', 'Campus Facility', 'Other'
    ]
  };
}
