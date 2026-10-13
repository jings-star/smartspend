/// This is a FAKE auth service so the screens work right now.
/// Later, replace the inside of these functions with a real backend
/// (for example Firebase Auth). The screens will not need to change.
class AuthService {
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    // TODO: call your real sign-in here.
    // If it fails, throw an Exception('Wrong email or password').
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    // TODO: call your real sign-up here.
  }

  Future<void> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: add Google sign-in here.
  }

  Future<void> sendPasswordReset({required String email}) async {
    await Future.delayed(const Duration(seconds: 1));
    // TODO: ask your backend to email a reset link.
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: sign the user out of your backend.
  }
}
