class AuthResponse {
  final User user;
  final Token token;
  final String expiresIn;

  AuthResponse({
    required this.user,
    required this.token,
    required this.expiresIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user']),
      token: Token.fromJson(json['token']),
      expiresIn: json['expiresIn'],
    );
  }
}

class User {
  final String id;
  final String nombre;
  final String correo;
  final String rolId;
  final String? planId;
  final bool estatus;
  final String? foto;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rolId,
    this.planId,
    required this.estatus,
    this.foto,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      nombre: json['nombre'],
      correo: json['correo'],
      rolId: json['rol_id'],
      planId: json['plan_id'],
      estatus: json['estatus'],
      foto: json['foto'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'correo': correo,
      'rol_id': rolId,
      'estatus': estatus,
    };
  }
}

class Token {
  final String token;
  final String expires;

  Token({required this.token, required this.expires});

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(token: json['token'], expires: json['expires']);
  }
}
