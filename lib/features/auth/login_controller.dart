class LoginController 
{
  final Map<String, Map<String, String>> _users = {
    "alda": {"password": "qwerty", "role": "Ketua"},
    "pujama": {"password": "asdfg", "role": "Anggota"},
  };
  
  String? currentUserId;
  String? currentUserRole;

  bool login(String username, String password) {
    if (_users.containsKey(username))
    {
      if (_users[username]!["password"] == password)
      {
        currentUserId = username;
        currentUserRole = _users[username]!["role"];
        return true;
      }
    }
    return false;
  }
}
