import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omr_mobile_app/core/database/local_database.dart';

/// Background Worker that synchronizes offline scan results & outbox emails when online.
class OutboxSyncWorker {
  final LocalOMRDatabase localDb;
  final SupabaseClient? supabaseClient;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  OutboxSyncWorker({
    required this.localDb,
    this.supabaseClient,
  });

  /// Starts listening for internet reconnection
  void startMonitoring() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        syncPendingOutbox();
      }
    });
  }

  /// Manually or automatically trigger synchronization of pending items
  Future<int> syncPendingOutbox() async {
    if (_isSyncing) return 0;
    _isSyncing = true;

    int syncedCount = 0;
    try {
      final pendingList = await localDb.getPendingEmails();
      if (pendingList.isEmpty) {
        _isSyncing = false;
        return 0;
      }

      final client = supabaseClient ??
          (Supabase.instance.isInitialized ? Supabase.instance.client : null);
      if (client == null) {
        _isSyncing = false;
        return 0;
      }

      final db = await localDb.database;

      for (final item in pendingList) {
        final id = item['id'] as String;
        final recipient = item['recipient_email'] as String;
        final studentName = item['student_name'] as String;
        final scanResultId = item['scan_result_id'] as String;

        try {
          // Invoke Supabase Edge Function to send email
          await client.functions.invoke(
            'send-report-email',
            body: {
              'recipient_email': recipient,
              'student_name': studentName,
              'scan_result_id': scanResultId,
            },
          );

          // Update status to SENT
          await db.update(
            'email_outbox',
            {'status': 'SENT'},
            where: 'id = ?',
            whereArgs: [id],
          );
          syncedCount++;
        } catch (e) {
          // Increment retry count
          await db.rawUpdate(
            'UPDATE email_outbox SET retry_count = retry_count + 1 WHERE id = ?',
            [id],
          );
        }
      }
    } catch (_) {
      // Ignore background sync errors
    } finally {
      _isSyncing = false;
    }

    return syncedCount;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
