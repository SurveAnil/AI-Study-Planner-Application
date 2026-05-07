import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service responsible for pushing local SQLite data to Cloud Firestore.
/// Matches the schema mapping between local tables and cloud collections.
class FirebaseSyncService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseSyncService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Pushes a single sync queue entry to the cloud.
  Future<void> pushRecord(Map<String, dynamic> syncEntry) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to sync data');
    }

    final tableName = syncEntry['table_name'] as String;
    final recordId = syncEntry['record_id'] as String;
    final operation = syncEntry['operation'] as String;
    final payload = syncEntry['payload'] as Map<String, dynamic>;

    // Map table names to Firestore collection names
    final collectionName = _getCollectionName(tableName);
    
    // We store user data in a subcollection under the user's UID for security
    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection(collectionName)
        .doc(recordId);

    if (operation == 'delete') {
      await docRef.delete();
    } else {
      // For 'insert' and 'update', we use set with merge: true
      await docRef.set(
        {
          ...payload,
          'last_synced_at': FieldValue.serverTimestamp(),
          'sync_status': 'synced',
        },
        SetOptions(merge: true),
      );
    }
  }

  /// Map SQLite table names to Firestore collection names.
  String _getCollectionName(String tableName) {
    switch (tableName) {
      case 'users':
        return 'profile';
      case 'study_plans':
        return 'plans';
      case 'tasks':
        return 'tasks';
      case 'study_sessions':
        return 'sessions';
      case 'revision_tasks':
        return 'revisions';
      case 'performance_data':
        return 'analytics';
      default:
        return tableName;
    }
  }
}
