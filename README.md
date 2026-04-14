# Panal App

Aplicación móvil para la gestión de tareas, proyectos y servicios, desarrollada con Flutter.

## 🚀 Características Principales

- **Autenticación Segura**: Registro e inicio de sesión con correo electrónico y contraseña.
- **Gestión de Espacios de Trabajo**:
  - Creación y unión a espacios de trabajo mediante códigos.
  - Invitación de usuarios a espacios de trabajo.
  - Soporte para planes Gratuito y Premium.
- **Gestión de Tareas**:
  - Creación, edición y eliminación de tareas.
  - Categorización y priorización de tareas.
  - Asignación de tareas a usuarios.
  - Subtareas para un mejor seguimiento.
- **Gestión de Proyectos**:
  - Creación y gestión de proyectos con estados (Activo, En Pausa, Finalizado).
  - Asignación de tareas a proyectos.
- **Servicios**:
  - Gestión de servicios con estados (Pendiente, En Proceso, Finalizado).
  - Adjuntar fotos a los servicios.
- **Notificaciones**:
  - Notificaciones push para nuevas tareas y actualizaciones de estado.
- **IA Integrada**:
  - Agente de IA para la generación de planes y tareas.
  - Confirmación de tickets generados por IA.

## 🛠️ Tecnologías Utilizadas

- **Framework**: Flutter
- **Lenguaje**: Dart
- **Backend**: Firebase (Firestore, Authentication)
- **Notificaciones**: Firebase Cloud Messaging (FCM)
- **Almacenamiento Local**: shared_preferences
- **Manejo de Imágenes**: image_picker
- **Lanzamiento de URLs**: url_launcher

## 📦 Instalación y Configuración

### Requisitos Previos

- Flutter SDK instalado (versión 3.0.0 o superior).
- Android Studio o VS Code con extensiones de Flutter.
- Firebase CLI configurada.

### Pasos de Instalación

1. **Clonar el repositorio**:
   ```bash
   git clone <url-del-repositorio>
   cd panal-flutter-app
   ```

2. **Obtener dependencias**:
   ```bash
   flutter pub get
   ```

3. **Configurar Firebase**:
   - Asegúrate de tener un proyecto de Firebase configurado.
   - Ejecuta el siguiente comando para conectar la app con Firebase:
     ```bash
     flutterfire configure
     ```
   - Sigue las instrucciones para seleccionar las plataformas (Android, iOS) y los servicios de Firebase a habilitar.

4. **Configurar variables de entorno** (si aplica):
   - Crea un archivo `.env` en la raíz del proyecto (si existe un `.env.example`, cópialo).
   - Configura las variables necesarias.

5. **Ejecutar la aplicación**:
   ```bash
   flutter run
   ```

## 📂 Estructura del Proyecto

```
panal-flutter-app/
├── lib/
│   ├── main.dart              # Punto de entrada de la aplicación
│   ├── controllers/           # Controladores de la lógica de negocio
│   │   ├── app_controllers.dart
│   │   ├── auth_controller.dart
│   │   ├── tasks_controller.dart
│   │   ├── projects_controller.dart
│   │   ├── services_controller.dart
│   │   ├── tickets_controller.dart
│   │   ├── notifications_controller.dart
│   │   └── workspaces_controller.dart
│   ├── models/                # Modelos de datos
│   │   ├── models.dart
│   │   ├── task.dart
│   │   ├── project.dart
│   │   ├── service.dart
│   │   ├── ticket.dart
│   │   ├── workspace.dart
│   │   └── user.dart
│   ├── utils/                 # Utilidades y constantes
│   │   ├── app_colors.dart
│   │   ├── app_theme.dart
│   │   ├── app_toast.dart
│   │   └── app_constants.dart
│   ├── views/                 # Vistas de la aplicación
│   │   ├── auth/              # Vistas de autenticación
│   │   ├── home/              # Pantalla principal y chat con IA
│   │   ├── tasks/             # Gestión de tareas
│   │   ├── projects/          # Gestión de proyectos
│   │   ├── services/          # Gestión de servicios
│   │   ├── warehouse/         # Gestión de almacén
│   │   └── settings/          # Configuración
│   └── widgets/               # Widgets reutilizables
├── test/                      # Pruebas unitarias y de widgets
├── pubspec.yaml               # Dependencias y configuración del proyecto
└── README.md                  # Este archivo
```

## 📝 Notas de Desarrollo

### Manejo de Estados
La aplicación utiliza `setState` para el manejo de estados locales en los widgets. Para operaciones asíncronas, se utilizan `try-catch` blocks para manejar errores y `mounted` checks para evitar errores de UI.

### Notificaciones Push
Las notificaciones push están configuradas para funcionar con Firebase Cloud Messaging. Se requiere un archivo `google-services.json` (Android) y `GoogleService-Info.plist` (iOS) en las carpetas correspondientes para que funcionen correctamente.

### Variables de Entorno
Se recomienda el uso de variables de entorno para manejar configuraciones sensibles como claves de API y URLs base. Puedes usar paquetes como `flutter_dotenv` para gestionar estas variables.

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, sigue estos pasos:

1. Crea una rama para tu feature (`git checkout -b feature/NuevaFuncionalidad`).
2. Realiza tus cambios.
3. Commitea tus cambios (`git commit -m 'feat: Agregar nueva funcionalidad'`).
4. Haz push a la rama (`git push origin feature/NuevaFuncionalidad`).
5. Abre un Pull Request.

## 📄 Licencia

Este proyecto es de código cerrado y pertenece a Panal Organization. Para uso comercial o distribución, por favor contacta a los propietarios.