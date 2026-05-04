// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage;

  AuthService(this._storage);

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ✅ Register dengan Email
  Future<bool> register(String username, String password, String email) async {
    try {
      // Cek apakah username atau email sudah ada
      for (var key in _storage.userBox.keys) {
        final user = _storage.userBox.get(key);
        if (user['username'] == username || user['email'] == email) {
          return false; // User/Email sudah terdaftar
        }
      }
      
      final passwordHash = hashPassword(password);
      await _storage.saveUser(username, passwordHash, email);
      return true;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final user = _storage.getUser(username);
      if (user == null) return false;

      final passwordHash = hashPassword(password);
      if (user['password'] != passwordHash) return false;

      await _storage.saveSession(username);
      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearSession();
  }

  bool hasActiveSession() => _storage.isLoggedIn();
  String? getCurrentUsername() => _storage.getUsername();
}