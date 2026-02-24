class LoginController 
{
  final Map<String, String> _users = {
    "admin": "123",
    "alda": "456",
  };

  bool login(String username, String password) {
    if (_users.containsKey(username))
    {
      return _users[username] == password;
    }
    return false;
  }
}
