import 'package:cloud_firestore/cloud_firestore.dart';

void debugUserRoles() async {
  final db = FirebaseFirestore.instance;
  final roles = ['recruiter', 'Recruiter', 'job seeker', 'Job Seeker', 'admin', 'Admin'];
  
  for (final role in roles) {
    final count = await db.collection('users').where('role', isEqualTo: role).count().get();
    print('Role: $role | Count: ${count.count}');
  }
}
