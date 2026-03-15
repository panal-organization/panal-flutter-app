class EstadoTickets {
  String? id;
  String? nombre;

  EstadoTickets({this.id, this.nombre});

  factory EstadoTickets.fromJson(Map<String, dynamic> json) {
    return EstadoTickets(id: json['_id'], nombre: json['nombre']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'_id': id, 'nombre': nombre};
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class EstadoOrden {
  String? id;
  String? nombre;

  EstadoOrden({this.id, this.nombre});

  factory EstadoOrden.fromJson(Map<String, dynamic> json) {
    return EstadoOrden(id: json['_id'], nombre: json['nombre']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'_id': id, 'nombre': nombre};
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class Comentario {
  String? usuarioId;
  String? comentario;
  String? fecha;

  Comentario({this.usuarioId, this.comentario, this.fecha});

  factory Comentario.fromJson(Map<String, dynamic> json) {
    dynamic uId = json['usuario'];
    String? finalUId;
    if (uId is Map<String, dynamic>) {
        finalUId = uId['_id'];
    } else if (uId is String) {
        finalUId = uId;
    }

    return Comentario(
      usuarioId: finalUId,
      comentario: json['comentario'],
      fecha: json['fecha'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'usuario': usuarioId,
      'comentario': comentario,
      'fecha': fecha,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class Tickets {
  String? id;
  String? titulo;
  String? foto;
  String? descripcion;
  String? estado;
  String? prioridad;
  String? categoria;
  String? createdBy;
  String? createdAt;
  String? updatedAt;
  bool? isDeleted;
  String? workspaceId;
  List<Comentario>? comentarios;

  Tickets({
    this.id,
    this.titulo,
    this.foto,
    this.descripcion,
    this.estado,
    this.prioridad,
    this.categoria,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.isDeleted,
    this.workspaceId,
    this.comentarios,
  });

  factory Tickets.fromJson(Map<String, dynamic> json) {
    List<Comentario>? comentariosList;
    if (json['comentarios'] != null) {
      comentariosList = [];
      for (var v in json['comentarios']) {
        comentariosList.add(Comentario.fromJson(v));
      }
    }

    return Tickets(
      id: json['_id'],
      titulo: json['titulo'],
      foto: json['foto'],
      descripcion: json['descripcion'],
      estado: json['estado'] ?? json['estado_id'], // fallback gracefully
      prioridad: json['prioridad'],
      categoria: json['categoria'],
      createdBy: json['created_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isDeleted: json['is_deleted'],
      workspaceId: json['workspace_id'],
      comentarios: comentariosList,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'titulo': titulo,
      'foto': foto,
      'descripcion': descripcion,
      'estado': estado,
      'prioridad': prioridad,
      'categoria': categoria,
      'created_by': createdBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted,
      'workspace_id': workspaceId,
    };
    if (comentarios != null) {
      data['comentarios'] = comentarios!.map((v) => v.toJson()).toList();
    }
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class Usuarios {
  String? id;
  String? nombre;
  String? correo;
  String? contrasena;
  bool? estatus;
  String? rolId;
  String? foto;
  String? createdAt;
  String? updatedAt;
  String? planId;

  bool get isPremium {
    return planId == '69a3df3381a5be4cb1bd8bc3';
  }

  bool get isGratuito {
    return planId == '69a3de4281a5be4cb1bd8bc0';
  }

  Usuarios({
    this.id,
    this.nombre,
    this.correo,
    this.contrasena,
    this.estatus,
    this.rolId,
    this.foto,
    this.createdAt,
    this.updatedAt,
    this.planId,
  });

  factory Usuarios.fromJson(Map<String, dynamic> json) {
    return Usuarios(
      id: json['_id'],
      nombre: json['nombre'],
      correo: json['correo'],
      contrasena: json['contrasena'],
      estatus: json['estatus'],
      rolId: json['rol_id'],
      foto: json['foto'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      planId: json['plan_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'nombre': nombre,
      'correo': correo,
      'contrasena': contrasena,
      'estatus': estatus,
      'rol_id': rolId,
      'foto': foto,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'plan_id': planId,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class Roles {
  String? id;
  String? nombre;
  String? codigo;
  String? nivel;

  Roles({this.id, this.nombre, this.codigo, this.nivel});

  factory Roles.fromJson(Map<String, dynamic> json) {
    return Roles(
      id: json['_id'],
      nombre: json['nombre'],
      codigo: json['codigo'],
      nivel: json['nivel'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'nombre': nombre,
      'codigo': codigo,
      'nivel': nivel,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class Modulos {
  String? id;
  String? nombre;
  String? ruta;
  String? icono;
  bool? estatus;

  Modulos({this.id, this.nombre, this.ruta, this.icono, this.estatus});

  factory Modulos.fromJson(Map<String, dynamic> json) {
    return Modulos(
      id: json['_id'],
      nombre: json['nombre'],
      ruta: json['ruta'],
      icono: json['icono'],
      estatus: json['estatus'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'nombre': nombre,
      'ruta': ruta,
      'icono': icono,
      'estatus': estatus,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class Workspaces {
  String? id;
  String? nombre;
  String? codigo;
  String? adminId;
  String? createdAt;
  bool? isDeleted;

  Workspaces({
    this.id,
    this.nombre,
    this.codigo,
    this.adminId,
    this.createdAt,
    this.isDeleted,
  });

  factory Workspaces.fromJson(Map<String, dynamic> json) {
    return Workspaces(
      id: json['_id'],
      nombre: json['nombre'],
      codigo: json['codigo'],
      adminId: json['admin_id'],
      createdAt: json['created_at'],
      isDeleted: json['is_deleted'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'nombre': nombre,
      'codigo': codigo,
      'admin_id': adminId,
      'created_at': createdAt,
      'is_deleted': isDeleted,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class Plan {
  String? id;
  String? nombre;
  String? descripcion;

  Plan({this.id, this.nombre, this.descripcion});

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['_id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'nombre': nombre,
      'descripcion': descripcion,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class TipoOrdenes {
  String? id;
  String? nombre;

  TipoOrdenes({this.id, this.nombre});

  factory TipoOrdenes.fromJson(Map<String, dynamic> json) {
    return TipoOrdenes(id: json['_id'], nombre: json['nombre']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'_id': id, 'nombre': nombre};
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class OrdenesServicio {
  String? id;
  String? descripcion;
  String? estadoId;
  String? createdBy;
  String? articuloId;
  String? tipoId;
  String? createdAt;
  String? updatedAt;
  bool? isDeleted;
  String? workspaceId;

  OrdenesServicio({
    this.id,
    this.descripcion,
    this.estadoId,
    this.createdBy,
    this.articuloId,
    this.tipoId,
    this.createdAt,
    this.updatedAt,
    this.isDeleted,
    this.workspaceId,
  });

  factory OrdenesServicio.fromJson(Map<String, dynamic> json) {
    return OrdenesServicio(
      id: json['_id'],
      descripcion: json['descripcion'],
      estadoId: json['estado_id'],
      createdBy: json['created_by'],
      articuloId: json['articulo_id'],
      tipoId: json['tipo_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isDeleted: json['is_deleted'],
      workspaceId: json['workspace_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'descripcion': descripcion,
      'estado_id': estadoId,
      'created_by': createdBy,
      'articulo_id': articuloId,
      'tipo_id': tipoId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted,
      'workspace_id': workspaceId,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class Almacen {
  String? id;
  String? nombre;
  String? icono;
  num? registros;
  String? workspaceId;

  Almacen({this.id, this.nombre, this.icono, this.registros, this.workspaceId});

  factory Almacen.fromJson(Map<String, dynamic> json) {
    return Almacen(
      id: json['_id'],
      nombre: json['nombre'],
      icono: json['icono'],
      registros: json['registros'],
      workspaceId: json['workspace_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'nombre': nombre,
      'icono': icono,
      'registros': registros,
      'workspace_id': workspaceId,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class Articulos {
  String? id;
  String? nombre;
  String? workspaceId;

  Articulos({this.id, this.nombre, this.workspaceId});

  factory Articulos.fromJson(Map<String, dynamic> json) {
    return Articulos(
      id: json['_id'],
      nombre: json['nombre'],
      workspaceId: json['workspace_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'nombre': nombre,
      'workspace_id': workspaceId,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class Propiedades {
  String? id;
  String? nombre;
  String? descripcion;
  String? workspaceId;

  Propiedades({this.id, this.nombre, this.descripcion, this.workspaceId});

  factory Propiedades.fromJson(Map<String, dynamic> json) {
    return Propiedades(
      id: json['_id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      workspaceId: json['workspace_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'workspace_id': workspaceId,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class Plantillas {
  String? id;
  String? nombre;
  String? descripcion;
  String? workspaceId;

  Plantillas({this.id, this.nombre, this.descripcion, this.workspaceId});

  factory Plantillas.fromJson(Map<String, dynamic> json) {
    return Plantillas(
      id: json['_id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      workspaceId: json['workspace_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'workspace_id': workspaceId,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class WorkspacesUsuarios {
  String? id;
  String? workspaceId;
  Workspaces? workspace;
  String? usuarioId;
  Usuarios? usuario;

  WorkspacesUsuarios({
    this.id,
    this.workspaceId,
    this.workspace,
    this.usuarioId,
    this.usuario,
  });

  factory WorkspacesUsuarios.fromJson(Map<String, dynamic> json) {
    dynamic wId = json['workspace_id'];
    String? finalWorkspaceId;
    Workspaces? workspaceObj;
    if (wId is Map<String, dynamic>) {
      finalWorkspaceId = wId['_id'];
      workspaceObj = Workspaces.fromJson(wId);
    } else if (wId is String) {
      finalWorkspaceId = wId;
    }

    dynamic uId = json['usuario_id'];
    String? finalUsuarioId;
    Usuarios? usuarioObj;
    if (uId is Map<String, dynamic>) {
      finalUsuarioId = uId['_id'];
      usuarioObj = Usuarios.fromJson(uId);
    } else if (uId is String) {
      finalUsuarioId = uId;
    }

    return WorkspacesUsuarios(
      id: json['_id'],
      workspaceId: finalWorkspaceId,
      workspace: workspaceObj,
      usuarioId: finalUsuarioId,
      usuario: usuarioObj,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'workspace_id': workspaceId,
      'usuario_id': usuarioId,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class ArticulosPropiedades {
  String? id;
  String? articuloId;
  String? propiedadId;

  ArticulosPropiedades({this.id, this.articuloId, this.propiedadId});

  factory ArticulosPropiedades.fromJson(Map<String, dynamic> json) {
    return ArticulosPropiedades(
      id: json['_id'],
      articuloId: json['articulo_id'],
      propiedadId: json['propiedad_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'articulo_id': articuloId,
      'propiedad_id': propiedadId,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

class PlantillaPropiedades {
  String? id;
  String? plantillaId;
  String? propiedadId;

  PlantillaPropiedades({this.id, this.plantillaId, this.propiedadId});

  factory PlantillaPropiedades.fromJson(Map<String, dynamic> json) {
    return PlantillaPropiedades(
      id: json['_id'],
      plantillaId: json['plantilla_id'],
      propiedadId: json['propiedad_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'plantilla_id': plantillaId,
      'propiedad_id': propiedadId,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}
