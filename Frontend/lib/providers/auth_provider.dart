// Credenciales mock temporales — reemplazar al integrar Supabase real.
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;

  bool get isLoggedIn => _currentUser != null;
  UserModel? get currentUser => _currentUser;

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final normalized = email.trim().toLowerCase();

    if (password != '123456') return false;

    UserModel? user;
    switch (normalized) {
      case 'comprador@baratito.ec':
        user = const UserModel(
          id: 'mock-buyer-001',
          name: 'Comprador Demo',
          email: 'comprador@baratito.ec',
          role: UserRole.buyer,
        );
      case 'vendedor@baratito.ec':
        user = const UserModel(
          id: 'mock-seller-001',
          name: 'Vendedor Demo',
          email: 'vendedor@baratito.ec',
          role: UserRole.seller,
        );
      case 'admin@baratito.ec':
        user = const UserModel(
          id: 'mock-admin-001',
          name: 'Admin Baratito',
          email: 'admin@baratito.ec',
          role: UserRole.admin,
        );
    }

    if (user == null) return false;

    _currentUser = user;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
