import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final currentSessionProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(currentSessionProvider);
  return authState.value?.session?.user ??
      Supabase.instance.client.auth.currentUser;
});

/// Current Active Organization ID state provider
final currentOrganizationIdProvider = StateProvider<String?>((ref) {
  return '22222222-2222-2222-2222-222222222222'; // Default seeded demo org
});
