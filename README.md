# 🚚 Repartidor App (Driver) - SIGLO-F

**Una solución integral para la gestión logística de repartidores, ventas en campo y liquidaciones.**

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

## 📖 Descripción General

La aplicación **App Driver** es una herramienta móvil desarrollada en **Flutter** diseñada para optimizar el flujo de trabajo de los repartidores y agentes de campo. Permite la gestión eficiente de rutas, realización de ventas, liquidación de productos y seguimiento en tiempo real.

Esta aplicación es el componente móvil del ecosistema logístico **SIGLO-F**, conectando a los repartidores con el sistema central para una operación fluida y sincronizada.

---

## ✨ Características Principales

### 🔐 Autenticación y Seguridad
*   **Inicio de Sesión Seguro:** Acceso restringido mediante credenciales validadas por API.
*   **Gestión de Sesiones:** Manejo automático de tokens y expiración de sesión para mayor seguridad.
*   **Perfil de Usuario:** Visualización y actualización de foto de perfil (Cámara/Galería).

### 🚛 Gestión de Rutas y Logística
*   **Control de Rutas:** Apertura y cierre de rutas de reparto diario.
*   **Inventario en Ruta:** Visualización del stock disponible en el vehículo.
*   **Mapa Interactivo:** Navegación y geolocalización utilizando **OpenStreetMap** (via `flutter_map`).
*   **Seguimiento en Vivo:** Envío de ubicación en segundo plano para monitoreo central.

### 💰 Ventas y Liquidación
*   **Ventas en Campo:** Registro ágil de ventas a clientes.
*   **Escáner QR:** Identificación rápida de clientes mediante códigos QR (`mobile_scanner`).
*   **Liquidación Diaria:** Proceso simplificado para liquidar ventas y devoluciones al finalizar la ruta.
*   **Historial:** Consulta detallada de liquidaciones y movimientos pasados.

### 🔄 Sistema de Actualizaciones (OTA)
*   **Auto-Update:** Sistema integrado para verificar versiones nuevas desde GitHub Releases.
*   **Instalación Directa:** Descarga e instalación automática de actualizaciones (APKs) sin depender de tiendas de aplicaciones.
*   **Notas de Versión:** Visualización de novedades y cambios en cada actualización.

---

## 🛠️ Stack Tecnológico

El proyecto está construido utilizando tecnologías modernas y robustas:

*   **Framework:** [Flutter](https://flutter.dev/) (SDK >=3.3.4)
*   **Lenguaje:** [Dart](https://dart.dev/)
*   **Gestión de Estado:** [Provider](https://pub.dev/packages/provider) (MVVM Architecture)
*   **Cliente HTTP:** [Dio](https://pub.dev/packages/dio) con interceptores para manejo de errores y auth.
*   **Mapas:** [Flutter Map](https://pub.dev/packages/flutter_map) & [LatLong2](https://pub.dev/packages/latlong2).
*   **Almacenamiento Local:** [Shared Preferences](https://pub.dev/packages/shared_preferences).
*   **Otros:** 
    *   `permission_handler` (Gestión de permisos Android)
    *   `geolocator` (Ubicación GPS)
    *   `mobile_scanner` (Lectura de QR)
    *   `path_provider` & `open_file_plus` (Gestión de archivos para updates).

---

## 📂 Estructura del Proyecto

La arquitectura sigue una separación clara de responsabilidades:

```
lib/
├── config/         # Configuraciones globales (Temas, Constantes)
├── core/           # Utilidades base y helpers
├── models/         # Modelos de datos (Entidades, DTOs)
├── providers/      # Lógica de negocio y Estado (ViewModels)
├── screens/        # Vistas y Pantallas de la UI
├── services/       # Comunicación con APIs y Servicios externos
├── widgets/        # Componentes UI reutilizables
└── main.dart       # Punto de entrada de la aplicación
```

---

## 🚀 Instalación y Configuración

### Prerrequisitos
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado y configurado.
*   Un dispositivo Android o Emulador.
*   Git.

### Pasos de Instalación

1.  **Clonar el repositorio:**
    ```bash
    git clone <url-del-repositorio>
    cd app_driver
    ```

2.  **Instalar dependencias:**
    ```bash
    flutter pub get
    ```

3.  **Configuración de Entorno:**
    *   Verificar el archivo `lib/config/constants.dart` para asegurar que la `BASE_URL` apunte al servidor backend correcto (Desarrollo/Producción).

4.  **Ejecutar la aplicación:**
    ```bash
    flutter run
    ```

---

## 📦 Generación de Versiones (Build)

Para generar el instalable (APK) para distribución:

```bash
flutter build apk --release
```
El archivo generado se encontrará en: `build/app/outputs/flutter-apk/app-release.apk`.

### Versionado
El proyecto utiliza un archivo `version.json` y el `pubspec.yaml` para gestionar las versiones.
*   Incrementar la versión en `pubspec.yaml`.
*   Actualizar `version.json` si se despliega una nueva Release en GitHub para activar la actualización OTA en los dispositivos clientes.

---

## 🤝 Contribución

1.  Hacer un Fork del proyecto.
2.  Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`).
3.  Commit de tus cambios (`git commit -m 'Add some AmazingFeature'`).
4.  Push a la rama (`git push origin feature/AmazingFeature`).
5.  Abrir un Pull Request.

---

© 2026 SIGLO-F Logistics. Todos los derechos reservados.
