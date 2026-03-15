import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiController {
  static const String baseUrl =
      'https://waggish-unsecludedly-jong.ngrok-free.dev/api';

  Future<List<T>> get<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$endpoint'));
      if (response.statusCode == 200) {
        final dynamic body = json.decode(response.body);
        if (body is List) {
          return body.map((e) => fromJson(e)).toList();
        } else if (body is Map<String, dynamic> && body['data'] is List) {
          // Handle wrapped responses if any
          return (body['data'] as List).map((e) => fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  Future<T?> getById<T>(
    String endpoint,
    String id,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$endpoint/$id'));
      if (response.statusCode == 200) {
        return fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching item: $e');
    }
  }

  Future<bool> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      throw Exception('Error creating data: $e');
    }
  }

  Future<bool> put(
    String endpoint,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating data: $e');
    }
  }

  Future<bool> delete(String endpoint, String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$endpoint/$id'));
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting data: $e');
    }
  }

  Future<bool> patchMultipart(
    String endpoint,
    String id,
    String fieldName,
    String filePath,
  ) async {
    try {
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/$endpoint/$id'),
      );
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  Future<bool> postMultipart(
    String endpoint,
    String fieldName,
    String filePath, {
    Map<String, String>? fields,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/$endpoint');

      var request = http.MultipartRequest('POST', uri);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final respStr = await response.stream.bytesToString();
        print("ERROR UPLOAD PHOTO: $respStr");
        return false;
      }
    } catch (e) {
      print("Multipart error: $e");
      return false;
    }
  }

  Future<bool> putMultipart(
    String endpoint,
    String id,
    String fieldName,
    String filePath, {
    Map<String, String>? fields,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/$endpoint/$id');

      var request = http.MultipartRequest('PUT', uri);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      var response = await request.send();

      if (response.statusCode == 200) {
        return true;
      } else {
        final respStr = await response.stream.bytesToString();
        print("ERROR UPDATE PHOTO: $respStr");
        return false;
      }
    } catch (e) {
      print("Multipart error: $e");
      return false;
    }
  }
}

// Specific Controllers

class EstadoTicketsController extends ApiController {
  final String endpoint = 'estado-tickets';

  Future<List<EstadoTickets>> getAll() =>
      get<EstadoTickets>(endpoint, EstadoTickets.fromJson);
  Future<EstadoTickets?> getOne(String id) =>
      getById<EstadoTickets>(endpoint, id, EstadoTickets.fromJson);
  Future<bool> create(EstadoTickets item) => post(endpoint, item.toJson());
  Future<bool> update(String id, EstadoTickets item) =>
      put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);
}

class EstadoOrdenController extends ApiController {
  final String endpoint = 'estado-orden';

  Future<List<EstadoOrden>> getAll() =>
      get<EstadoOrden>(endpoint, EstadoOrden.fromJson);
  Future<EstadoOrden?> getOne(String id) =>
      getById<EstadoOrden>(endpoint, id, EstadoOrden.fromJson);
  Future<bool> create(EstadoOrden item) => post(endpoint, item.toJson());
  Future<bool> update(String id, EstadoOrden item) =>
      put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);
}

class TicketsController extends ApiController {
  final String endpoint = 'tickets';

  Future<List<Tickets>> getAll() => get<Tickets>(endpoint, Tickets.fromJson);
  Future<List<Tickets>> getByWorkspace(String workspaceId) =>
      get<Tickets>('$endpoint?workspace_id=$workspaceId', Tickets.fromJson);
  Future<Tickets?> getOne(String id) =>
      getById<Tickets>(endpoint, id, Tickets.fromJson);
  Future<bool> create(Tickets item) => post(endpoint, item.toJson());
  Future<bool> update(String id, Tickets item) =>
      put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);

  Future<bool> uploadPhoto(String ticketId, String usuarioId, String filePath) async {
    final url = await uploadPhotoOnly(usuarioId, filePath);
    if (url != null) {
      return await update(ticketId, Tickets(foto: url));
    }
    return false;
  }

  Future<String?> uploadPhotoOnly(String usuarioId, String filePath) async {
    try {
      var uri = Uri.parse('${ApiController.baseUrl}/upload');
      var request = http.MultipartRequest('POST', uri);
      request.fields.addAll({'usuario_id': usuarioId, 'tipo': 'documento'});
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respStr = await response.stream.bytesToString();
        final body = json.decode(respStr);
        return body['archivo']['url'];
      } else {
        final respStr = await response.stream.bytesToString();
        print("ERROR UPLOAD PHOTO: $respStr");
        return null;
      }
    } catch (e) {
      print("Multipart error: $e");
      return null;
    }
  }

  Future<bool> deletePhoto(String ticketId) async {
    return await update(ticketId, Tickets(foto: ''));
  }
}

class UsuariosController extends ApiController {
  final String endpoint = 'usuarios';

  Future<List<Usuarios>> getAll() => get<Usuarios>(endpoint, Usuarios.fromJson);
  Future<Usuarios?> getOne(String id) =>
      getById<Usuarios>(endpoint, id, Usuarios.fromJson);
  Future<bool> create(Usuarios item) => post(endpoint, item.toJson());
  Future<bool> update(String id, Usuarios item) =>
      put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);

  Future<bool> uploadPhoto(String id, String filePath) => postMultipart(
    'upload',
    'file',
    filePath,
    fields: {'usuario_id': id, 'tipo': 'perfil'},
  );

  Future<bool> updatePhoto(String id, String filePath) => putMultipart(
    'upload',
    id,
    'file',
    filePath,
    fields: {'usuario_id': id, 'tipo': 'perfil'},
  );

  Future<bool> deletePhoto(String id) => delete('upload', id);
}

class RolesController extends ApiController {
  final String endpoint = 'roles';

  Future<List<Roles>> getAll() => get<Roles>(endpoint, Roles.fromJson);
  Future<Roles?> getOne(String id) =>
      getById<Roles>(endpoint, id, Roles.fromJson);
  Future<bool> create(Roles item) => post(endpoint, item.toJson());
  Future<bool> update(String id, Roles item) =>
      put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);
}

class ModulosController extends ApiController {
  final String endpoint = 'modulos';

  Future<List<Modulos>> getAll() => get<Modulos>(endpoint, Modulos.fromJson);
  Future<Modulos?> getOne(String id) =>
      getById<Modulos>(endpoint, id, Modulos.fromJson);
  Future<bool> create(Modulos item) => post(endpoint, item.toJson());
  Future<bool> update(String id, Modulos item) =>
      put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);
}

class WorkspacesController extends ApiController {
  final String endpoint = 'workspaces';

  Future<List<Workspaces>> getAll() =>
      get<Workspaces>(endpoint, Workspaces.fromJson);
  Future<Workspaces?> getOne(String id) =>
      getById<Workspaces>(endpoint, id, Workspaces.fromJson);
  Future<bool> create(Workspaces item) => post(endpoint, item.toJson());
  Future<bool> update(String id, Workspaces item) =>
      put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);
}

class PlanController extends ApiController {
  final String endpoint = 'plan';

  Future<List<Plan>> getAll() => get<Plan>(endpoint, Plan.fromJson);
  Future<Plan?> getOne(String id) => getById<Plan>(endpoint, id, Plan.fromJson);
  Future<bool> create(Plan item) => post(endpoint, item.toJson());
  Future<bool> update(String id, Plan item) => put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);
}

class TipoOrdenesController extends ApiController {
  final String endpoint = 'tipo-ordenes';

  Future<List<TipoOrdenes>> getAll() =>
      get<TipoOrdenes>(endpoint, TipoOrdenes.fromJson);
  Future<TipoOrdenes?> getOne(String id) =>
      getById<TipoOrdenes>(endpoint, id, TipoOrdenes.fromJson);
  Future<bool> create(TipoOrdenes item) => post(endpoint, item.toJson());
  Future<bool> update(String id, TipoOrdenes item) =>
      put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);
}

class OrdenesServicioController extends ApiController {
  final String endpoint = 'ordenes-servicio';

  Future<List<OrdenesServicio>> getAll() =>
      get<OrdenesServicio>(endpoint, OrdenesServicio.fromJson);
  Future<List<OrdenesServicio>> getByWorkspace(String workspaceId) =>
      get<OrdenesServicio>('$endpoint?workspace_id=$workspaceId', OrdenesServicio.fromJson);
  Future<OrdenesServicio?> getOne(String id) =>
      getById<OrdenesServicio>(endpoint, id, OrdenesServicio.fromJson);
  Future<bool> create(OrdenesServicio item) => post(endpoint, item.toJson());
  Future<bool> update(String id, OrdenesServicio item) =>
      put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);
}

class AlmacenController extends ApiController {
  final String endpoint = 'almacen';

  Future<List<Almacen>> getAll() => get<Almacen>(endpoint, Almacen.fromJson);
  Future<Almacen?> getOne(String id) =>
      getById<Almacen>(endpoint, id, Almacen.fromJson);
  Future<bool> create(Almacen item) => post(endpoint, item.toJson());
  Future<bool> update(String id, Almacen item) =>
      put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);
}

class ArticulosController extends ApiController {
  final String endpoint = 'articulos';

  Future<List<Articulos>> getAll() =>
      get<Articulos>(endpoint, Articulos.fromJson);
  Future<Articulos?> getOne(String id) =>
      getById<Articulos>(endpoint, id, Articulos.fromJson);
  Future<bool> create(Articulos item) => post(endpoint, item.toJson());
  Future<bool> update(String id, Articulos item) =>
      put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);
}

class PropiedadesController extends ApiController {
  final String endpoint = 'propiedades';

  Future<List<Propiedades>> getAll() =>
      get<Propiedades>(endpoint, Propiedades.fromJson);
  Future<Propiedades?> getOne(String id) =>
      getById<Propiedades>(endpoint, id, Propiedades.fromJson);
  Future<bool> create(Propiedades item) => post(endpoint, item.toJson());
  Future<bool> update(String id, Propiedades item) =>
      put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);
}

class PlantillasController extends ApiController {
  final String endpoint = 'plantillas';

  Future<List<Plantillas>> getAll() =>
      get<Plantillas>(endpoint, Plantillas.fromJson);
  Future<Plantillas?> getOne(String id) =>
      getById<Plantillas>(endpoint, id, Plantillas.fromJson);
  Future<bool> create(Plantillas item) => post(endpoint, item.toJson());
  Future<bool> update(String id, Plantillas item) =>
      put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);
}

class WorkspacesUsuariosController extends ApiController {
  final String endpoint = 'workspaces-usuarios';

  Future<List<WorkspacesUsuarios>> getAll() =>
      get<WorkspacesUsuarios>(endpoint, WorkspacesUsuarios.fromJson);

  Future<List<WorkspacesUsuarios>> getByUserId(String userId) =>
      get<WorkspacesUsuarios>(
        '$endpoint?usuario_id=$userId&populate=workspace_id,usuario_id',
        WorkspacesUsuarios.fromJson,
      );
  Future<WorkspacesUsuarios?> getOne(String id) =>
      getById<WorkspacesUsuarios>(endpoint, id, WorkspacesUsuarios.fromJson);
  Future<bool> create(WorkspacesUsuarios item) => post(endpoint, item.toJson());
  Future<bool> update(String id, WorkspacesUsuarios item) =>
      put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);
}

class ArticulosPropiedadesController extends ApiController {
  final String endpoint = 'articulos-propiedades';

  Future<List<ArticulosPropiedades>> getAll() =>
      get<ArticulosPropiedades>(endpoint, ArticulosPropiedades.fromJson);
  Future<ArticulosPropiedades?> getOne(String id) =>
      getById<ArticulosPropiedades>(
        endpoint,
        id,
        ArticulosPropiedades.fromJson,
      );
  Future<bool> create(ArticulosPropiedades item) =>
      post(endpoint, item.toJson());
  Future<bool> update(String id, ArticulosPropiedades item) =>
      put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);
}

class PlantillaPropiedadesController extends ApiController {
  final String endpoint = 'plantilla-propiedades';

  Future<List<PlantillaPropiedades>> getAll() =>
      get<PlantillaPropiedades>(endpoint, PlantillaPropiedades.fromJson);
  Future<PlantillaPropiedades?> getOne(String id) =>
      getById<PlantillaPropiedades>(
        endpoint,
        id,
        PlantillaPropiedades.fromJson,
      );
  Future<bool> create(PlantillaPropiedades item) =>
      post(endpoint, item.toJson());
  Future<bool> update(String id, PlantillaPropiedades item) =>
      put(endpoint, id, item.toJson());
  Future<bool> remove(String id) => delete(endpoint, id);
}
