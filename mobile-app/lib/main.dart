import 'package:flutter/material.dart';

// ============ AUTH SCREENS ============
import 'screens/auth/splash_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/student_login_screen.dart';
import 'screens/auth/teacher_login_screen.dart';
import 'screens/auth/principal_login_screen.dart';
import 'screens/auth/accountant_login_screen.dart';

// ============ STUDENT SCREENS ============
import 'screens/student/student_dashboard.dart';
import 'screens/student/student_attendance.dart';
import 'screens/student/student_fees.dart';
import 'screens/student/student_homework.dart';
import 'screens/student/student_results.dart';
import 'screens/student/student_timetable.dart';
import 'screens/student/student_leave.dart';
import 'screens/student/student_notifications.dart';
import 'screens/student/student_profile.dart';
import 'screens/student/student_events.dart';
import 'screens/student/student_academic_calendar.dart';
import 'screens/student/student_exam_schedule.dart';
import 'screens/student/student_attendance_calendar.dart';
import 'screens/student/student_homework_calendar.dart';

// ============ TEACHER SCREENS ============
import 'screens/teacher/teacher_dashboard.dart';
import 'screens/teacher/teacher_mark_attendance.dart';
import 'screens/teacher/teacher_approve_leaves.dart';
import 'screens/teacher/teacher_homework.dart';
import 'screens/teacher/teacher_my_classes.dart';
import 'screens/teacher/teacher_today_classes.dart';
import 'screens/teacher/teacher_student_view.dart';
import 'screens/teacher/teacher_notifications.dart';
import 'screens/teacher/teacher_profile.dart';
import 'screens/teacher/teacher_documents.dart';
import 'screens/teacher/teacher_attendance.dart';
import 'screens/teacher/teacher_class_detail.dart';
import 'screens/teacher/teacher_apply_leave.dart';
import 'screens/teacher/teacher_attendance_calendar.dart';
import 'screens/teacher/teacher_homework_calendar.dart';
import 'screens/teacher/teacher_events.dart';

// ============ PRINCIPAL SCREENS ============
import 'screens/principal/principal_dashboard.dart';
import 'screens/principal/principal_classes.dart';
import 'screens/principal/principal_class_detail.dart';
import 'screens/principal/principal_teachers.dart';
import 'screens/principal/principal_teacher_profile.dart';
import 'screens/principal/principal_student_profile.dart';
import 'screens/principal/principal_teacher_leaves.dart';
import 'screens/principal/principal_approvals.dart';
import 'screens/principal/principal_analytics.dart';
import 'screens/principal/principal_reports.dart';
import 'screens/principal/principal_notifications.dart';
import 'screens/principal/principal_profile.dart';
import 'screens/principal/principal_events.dart';
import 'screens/principal/principal_add_event.dart';

// ============ ACCOUNTANT SCREENS ============
import 'screens/accountant/accountant_dashboard.dart';
import 'screens/accountant/accountant_students.dart';
import 'screens/accountant/accountant_student_detail.dart';
import 'screens/accountant/accountant_add_student.dart';
import 'screens/accountant/accountant_edit_student.dart';
import 'screens/accountant/accountant_teachers.dart';
import 'screens/accountant/accountant_add_teacher.dart';
import 'screens/accountant/accountant_edit_teacher.dart';
import 'screens/accountant/accountant_teacher_detail.dart';
import 'screens/accountant/accountant_record_payment.dart';
import 'screens/accountant/accountant_pending_dues.dart';
import 'screens/accountant/accountant_fee_structure.dart';
import 'screens/accountant/accountant_apply_leave.dart';
import 'screens/accountant/accountant_reports.dart';
import 'screens/accountant/accountant_notifications.dart';
import 'screens/accountant/accountant_profile.dart';

void main() {
  runApp(const SGHPSApp());
}

class SGHPSApp extends StatelessWidget {
  const SGHPSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SGHPS App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: false,
      ),
      home: const SplashScreen(),
      routes: {
        // ============================================
        // AUTH ROUTES
        // ============================================
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/student-login': (context) => const StudentLoginScreen(),
        '/teacher-login': (context) => const TeacherLoginScreen(),
        '/principal-login': (context) => const PrincipalLoginScreen(),
        '/accountant-login': (context) => const AccountantLoginScreen(),

        // ============================================
        // STUDENT ROUTES
        // ============================================
        '/student-dashboard': (context) => const StudentDashboard(),
        '/student-attendance': (context) => const StudentAttendance(),
        '/student-fees': (context) => const StudentFees(),
        '/student-homework': (context) => const StudentHomework(),
        '/student-results': (context) => const StudentResults(),
        '/student-timetable': (context) => const StudentTimetable(),
        '/student-leave': (context) => const StudentLeave(),
        '/student-notifications': (context) => const StudentNotifications(),
        '/student-profile': (context) => const StudentProfile(),
        '/student-events': (context) => const StudentEvents(),
        '/student-academic-calendar': (context) =>
            const StudentAcademicCalendar(),
        '/student-exam-schedule': (context) => const StudentExamSchedule(),
        '/student-attendance-calendar': (context) =>
            const StudentAttendanceCalendar(),
        '/student-homework-calendar': (context) =>
            const StudentHomeworkCalendar(),

        // ============================================
        // TEACHER ROUTES
        // ============================================
        '/teacher-dashboard': (context) => const TeacherDashboard(),
        '/teacher-mark-attendance': (context) => const TeacherMarkAttendance(),
        '/teacher-approve-leaves': (context) => const TeacherApproveLeaves(),
        '/teacher-homework': (context) => const TeacherHomework(),
        '/teacher-my-classes': (context) => const TeacherMyClasses(),
        '/teacher-today-classes': (context) => const TeacherTodayClasses(),
        '/teacher-student-view': (context) => const TeacherStudentView(),
        '/teacher-notifications': (context) => const TeacherNotifications(),
        '/teacher-profile': (context) => const TeacherProfile(),
        '/teacher-documents': (context) => const TeacherDocuments(),
        '/teacher-attendance': (context) => const TeacherAttendance(),
        '/teacher-class-detail': (context) => const TeacherClassDetail(),
        '/teacher-apply-leave': (context) => const TeacherApplyLeave(),
        '/teacher-attendance-calendar': (context) =>
            const TeacherAttendanceCalendar(),
        '/teacher-homework-calendar': (context) =>
            const TeacherHomeworkCalendar(),
        '/teacher-events': (context) => const TeacherEvents(),

        // ============================================
        // PRINCIPAL ROUTES
        // ============================================
        '/principal-dashboard': (context) => const PrincipalDashboard(),
        '/principal-classes': (context) => const PrincipalClasses(),
        '/principal-class-detail': (context) => const PrincipalClassDetail(),
        '/principal-teachers': (context) => const PrincipalTeachers(),
        '/principal-teacher-profile': (context) =>
            const PrincipalTeacherProfile(),
        '/principal-student-profile': (context) =>
            const PrincipalStudentProfile(),
        '/principal-teacher-leaves': (context) =>
            const PrincipalTeacherLeaves(),
        '/principal-approvals': (context) => const PrincipalApprovals(),
        '/principal-analytics': (context) => const PrincipalAnalytics(),
        '/principal-reports': (context) => const PrincipalReports(),
        '/principal-notifications': (context) => const PrincipalNotifications(),
        '/principal-profile': (context) => const PrincipalProfile(),
        '/principal-events': (context) => const PrincipalEvents(),
        '/principal-add-event': (context) => const PrincipalAddEvent(),

        // ============================================
        // ACCOUNTANT ROUTES
        // ============================================
        '/accountant-dashboard': (context) => const AccountantDashboard(),
        '/accountant-students': (context) => const AccountantStudents(),
        '/accountant-student-detail': (context) =>
            const AccountantStudentDetail(),
        '/accountant-add-student': (context) => const AccountantAddStudent(),
        '/accountant-edit-student': (context) => const AccountantEditStudent(),
        '/accountant-teachers': (context) => const AccountantTeachers(),
        '/accountant-add-teacher': (context) => const AccountantAddTeacher(),
        '/accountant-edit-teacher': (context) => const AccountantEditTeacher(),
        '/accountant-teacher-detail': (context) =>
            const AccountantTeacherDetail(),
        '/accountant-record-payment': (context) =>
            const AccountantRecordPayment(),
        '/accountant-pending-dues': (context) => const AccountantPendingDues(),
        '/accountant-fee-structure': (context) =>
            const AccountantFeeStructure(),
        '/accountant-apply-leave': (context) => const AccountantApplyLeave(),
        '/accountant-reports': (context) => const AccountantReports(),
        '/accountant-notifications': (context) =>
            const AccountantNotifications(),
        '/accountant-profile': (context) => const AccountantProfile(),
      },
    );
  }
}
