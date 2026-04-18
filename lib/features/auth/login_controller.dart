import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginController 
{
  Map<String, dynamic>? login(String username, String password) 
  {
    final usersRaw = dotenv.env['USERS'] ?? '';
    final usersList = usersRaw.split(',');
    for (var user in usersList) {
      final parts = user.trim().split(':');
      if (parts.length == 5) {
        final u = parts[0];
        final p = parts[1];
        final role = parts[2];
        final uid = parts[3];
        final teamId = parts[4];
        if (u == username && p == password) {
          return {
            "username": u,
            "role": role,
            "uid": uid,
            "teamId": teamId,
          };
        }
      }
    }
    return null;
  }
}
