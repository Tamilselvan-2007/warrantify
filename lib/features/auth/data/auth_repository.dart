import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String role, // 'customer' or 'merchant'
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'role': role},
    );
  }
  Future<AuthResponse> verifySignupOtp({
  required String email,
  required String token,
}) async {
  return await _client.auth.verifyOTP(
    email: email,
    token: token,
    type: OtpType.signup,
  );
}

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  Future<void> signInWithGoogle() async {
  await _client.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: 'io.supabase.warrantify://login-callback/',
    queryParams: {
      'prompt': 'select_account',
    },
  );
}
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<String> signWarrantyQr(String cardId) async {
  final response = await _client.functions.invoke(
    'sign-warranty-qr',
    body: {'cardId': cardId},
  );

  if (response.status != 200) {
    throw Exception('Failed to sign QR: ${response.data}');
  }

  return response.data['qrHash'] as String;
}
  Future<Map<String, dynamic>> verifyWarrantyQr(String qrHash) async {
  final response = await _client.functions.invoke(
    'verify-warranty-qr',
    body: {'qrHash': qrHash},
  );
  return response.data as Map<String, dynamic>;
}
}