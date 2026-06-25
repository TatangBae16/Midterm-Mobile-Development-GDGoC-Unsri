import 'package:local_auth/local_auth.dart';

class BiometricHelper {
  final LocalAuthentication _auth = LocalAuthentication();

  // Mengecek apakah HP mendukung biometrik
  Future<bool> hasBiometrics() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  // Memunculkan pop-up sidik jari (Versi Paling Kompatibel)
  Future<bool> authenticate() async {
    final isAvailable = await hasBiometrics();
    if (!isAvailable) return false;

    try {
      return await _auth.authenticate(
        localizedReason: 'Gunakan sidik jari untuk masuk ke GearShift',
      );
    } catch (e) {
      return false;
    }
  }
}