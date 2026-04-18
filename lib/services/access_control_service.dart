import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccessControlService {
  // Mengambil roles dari .env di root
  static List<String> get availableRoles =>
      dotenv.env['APP_ROLES']?.split(',') ?? [];

  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  // Matrix perizinan yang tetap fleksibel
  static Map<String, List<String>> get rolePermissions
  {
    final roles = availableRoles;
    Map<String, List<String>> result = {};
    for (var role in roles) {
      final key = 'ROLE_$role';
      final permissions = dotenv.env[key];
      if (permissions != null) {
        result[role] =
            permissions.split(',').map((e) => e.trim()).toList();
      } else {
        result[role] = [];
      }
    }
    return result;
  }

  static bool canPerform(String role, String action, {bool isOwner = false}) {
    final permissions = rolePermissions[role] ?? [];
    bool hasBasicPermission = permissions.contains(action);

    // Logic khusus kepemilikan data (Owner-based RBAC)
    if (role == 'Anggota' &&
        (action == actionUpdate || action == actionDelete)) {
      return isOwner;
    }

    return hasBasicPermission;
  }
}