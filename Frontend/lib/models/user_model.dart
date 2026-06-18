/// Modelo de usuario para Baratito.
enum UserRole { buyer, seller, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  // TODO: factory fromJson cuando se conecte con Supabase/backend
}
