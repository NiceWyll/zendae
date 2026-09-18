# Mi Pendiente - Documentación Integral del Proyecto

> **Documento técnico consolidado para análisis y reestructuración arquitectónica**  
> **Fecha:** Septiembre 2026  
> **Tecnología:** Flutter (Dart)  
> **Objetivo del documento:** Exponer en detalle el estado actual, arquitectura, flujos, pantallas, dependencias, soluciones técnicas aplicadas y procesos de desarrollo de la aplicación móvil **"Mi Pendiente"**, de modo que un modelo de lenguaje avanzado (como Claude) pueda auditar, evaluar y proponer optimizaciones estructurales, de patrones de diseño, escalabilidad y buenas prácticas.

---

## 1. Resumen Ejecutivo de la Aplicación

**"Mi Pendiente"** es una aplicación móvil de gestión de tareas y organización personal con enfoque en la usabilidad rápida, visualización temporal flexible (diaria, semanal y mensual), estética moderna con curvas orgánicas degradadas y soporte nativo para temas claro y oscuro.

### Propuesta de Valor y Características Principales
* **Planificación Temporal en 3 Niveles:**
  * **Hoy:** Lista de foco diario con marcas cromáticas de prioridad y marcado rápido de tareas.
  * **Semana:** Vista de carga semanal, métricas de avance y acordeones desplegables para los 7 días.
  * **Mes:** Calendario mensual interactivo con indicadores cromáticos de prioridad (*dots*) debajo de los días con actividades.
* **Priorización Visual:** Tres niveles de prioridad identificables por color (Alta: Rojo `#FF3B30`, Media: Amarillo/Ámbar `#FF9500`, Baja: Azul `#007AFF`).
* **Selector de Hora Estilo Alarma:** Selector con ruedas duales sincronizadas (`CupertinoPicker`) para ajuste continuo de Horas (00–23) y Minutos (00–59) con vista previa digital en tiempo real, eliminando chips o valores predefinidos rígidos.
* **Motor de Alertas y Notificaciones Locales:** Canal Android de máxima prioridad (`Importance.max` y `Priority.high`) configurado para desplegar alertas emergentes en pantalla (*Heads-up notification* / "la nubecita"), sincronizadas con la fecha y hora elegidas y con cancelación automática al completar o borrar tareas.
* **Persistencia Local Offline-First:** Base de datos relacional SQLite embebida, compatible tanto con dispositivos móviles (Android/iOS) como con entornos de escritorio/pruebas locales (Windows/Linux con FFI).
* **Navegación Dual:** Menú lateral (*Navigation Drawer* interactivo de 3 rayitas) para resúmenes globales y accesos rápidos + *BottomNavigationBar* inferior de 4 secciones (*Pendientes*, *Calendario*, *Completados*, *Ajustes*).

---

## 2. Stack Tecnológico y Dependencias

* **Framework:** Flutter `>=3.24.0` / Dart `^3.5.0`
* **Gestión de Estado:** `flutter_riverpod: ^2.5.1` (Patrón StateNotifier)
* **Persistencia Local:**
  * `sqflite: ^2.3.3+1` (Base de datos relacional en Android e iOS)
  * `sqflite_common_ffi: ^2.3.3` (Soporte SQLite para Windows, Linux y tests unitarios)
  * `shared_preferences: ^2.3.2` (Preferencias de usuario: tema y switches de ajustes)
  * `path_provider: ^2.1.4` y `path: ^1.9.0`
* **Notificaciones y Zonas Horarias:**
  * `flutter_local_notifications: ^22.3.0`
  * `timezone: ^0.11.1`
* **UI, Tipografía e Internacionalización:**
  * `google_fonts: ^6.2.1` (Familia tipográfica *Inter*)
  * `intl: ^0.20.2` (Formateo de fechas y horas en español)
  * `flutter_localizations` (Soporte `es_ES` para Material, Widgets y Cupertino)
  * `uuid: ^4.5.1` (Generación de IDs únicos RFC4122 v4)
  * `flutter_svg: ^2.0.10+1`
* **Configuración Nativa Android:**
  * SDK Compile/Target: Android 14/15/16/17 (API 34–37)
  * Gradle: Kotlin DSL (`build.gradle.kts`)
  * Soporte Java 8+ Desugaring: `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` y `isCoreLibraryDesugaringEnabled = true` (indispensable para `java.time` utilizado por el plugin de notificaciones).

---

## 3. Arquitectura Actual del Proyecto (Clean Architecture + MVVM)

El proyecto sigue una adaptación modular de **Clean Architecture** estructurada en capas desacopladas:

```text
mi_pendiente/
├── android/                                    # Configuración de compilación, permisos y manifest
│   └── app/
│       ├── build.gradle.kts                    # Desugaring JDK libs habilitado
│       └── src/main/AndroidManifest.xml        # Permisos POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, SCHEDULE_EXACT_ALARM
├── assets/
│   └── icons/                                  # Recursos gráficos e iconos vectoriales
├── lib/
│   ├── main.dart                               # Punto de entrada, inicialización de SQLite FFI, notificaciones y MaterialApp
│   ├── core/                                   # Capa transversal compartida
│   │   ├── constants/
│   │   │   ├── app_colors.dart                 # Paleta de colores (Primary #1E60F0, Background, Prioridades, Bordes)
│   │   │   └── app_typography.dart             # Definiciones tipográficas Inter (h1, h2, body, captions)
│   │   ├── services/
│   │   │   └── notification_service.dart       # Singleton para inicialización, canales, permisos y programación de alarmas
│   │   ├── theme/
│   │   │   └── app_theme.dart                  # Temas Material 3 Claro y Oscuro completos
│   │   ├── utils/
│   │   │   └── date_time_utils.dart            # Formateadores en español (ej. "Hoy, 18 de septiembre", "10:30 AM")
│   │   └── widgets/
│   │       ├── priority_badge.dart             # Chip y dot indicador de prioridad
│   │       ├── segmented_view_tabs.dart        # Selector superior de pestañas (Hoy | Semana | Mes)
│   │       ├── task_card.dart                  # Tarjeta visual con indicador lateral de color, hora, título y checkbox
│   │       └── wave_background.dart            # CustomPainter con curvas y gradientes orgánicos para cabeceras/fondos
│   ├── domain/                                 # Reglas de negocio puras (sin dependencias de frameworks de UI o DB)
│   │   ├── entities/
│   │   │   ├── pendiente.dart                  # Entidad inmutable Pendiente (copyWith, getter fechaHoraCompleta)
│   │   │   └── prioridad.dart                  # Enum: alta, media, baja (con labels, colores y orden de severidad)
│   │   └── repositories/
│   │       └── pendiente_repository.dart       # Contrato abstracto del repositorio (CRUD y filtros)
│   ├── data/                                   # Implementación de datos y acceso a fuentes externas
│   │   ├── datasources/
│   │   │   └── app_database.dart               # Singleton gestor de SQLite, creación de tablas y sembrado inicial de datos
│   │   ├── models/
│   │   │   └── pendiente_model.dart            # Mapeo toMap() / fromMap() para persistencia SQLite
│   │   └── repositories/
│   │       └── pendiente_repository_impl.dart  # Implementación concreta de PendienteRepository contra AppDatabase
│   └── presentation/                           # Capa de interfaz de usuario y gestión de estado reactivo
│       ├── providers/
│       │   ├── ajustes_provider.dart           # StateNotifier para ThemeMode, Sonidos, Vibración y Notificaciones
│       │   └── pendientes_provider.dart        # StateNotifier para gestión reactiva de la lista de tareas y filtros
│       └── screens/
│           ├── splash_screen.dart              # Pantalla 1: Logo animado 3D, ondas y redirección automática
│           ├── home_shell_screen.dart          # Shell principal con Drawer lateral, AppBar con campana y BottomNav
│           ├── hoy_screen.dart                 # Pantalla 2: Vista de tareas del día de hoy
│           ├── semana_screen.dart              # Pantalla 3: Resumen semanal, métricas y días en acordeón
│           ├── mes_screen.dart                 # Pantalla 4: Calendario mensual interactivo con dots de prioridad
│           ├── nuevo_pendiente_screen.dart     # Pantalla 5: Formulario de creación/edición con selector de hora estilo alarma
│           ├── detalle_pendiente_screen.dart   # Pantalla 6: Ficha detallada con metadata y botones de acción
│           ├── completados_screen.dart         # Pantalla 7: Historial agrupado de tareas completadas y botón de restaurar
│           └── ajustes_screen.dart             # Pantalla 8: Configuración, switch de tema claro/oscuro y preferencias
└── test/
    ├── domain_and_repository_test.dart         # Pruebas unitarias de la entidad, conversiones de modelo y prioridad
    └── widget_test.dart                        # Pruebas de widgets: arranque de app y apertura del selector de alarma
```

---

## 4. Detalle de Capas y Componentes Implementados

### 4.1. Capa de Dominio (`lib/domain/`)
* **`Pendiente` (`entities/pendiente.dart`):**
  * Propiedades:
    * `String id`: Identificador único (UUID v4).
    * `String titulo`: Título de la tarea (obligatorio).
    * `String? descripcion`: Detalle opcional.
    * `DateTime fecha`: Fecha asignada (año, mes, día).
    * `TimeOfDay hora`: Hora programada.
    * `Prioridad prioridad`: Enum (`alta`, `media`, `baja`).
    * `bool tieneRecordatorio`: Si tiene alarma activada.
    * `int minutosAntes`: Antelación del aviso (por defecto 10 minutos).
    * `String repetir`: Frecuencia ('No repetir', 'Diario', 'Semanal', 'Mensual').
    * `bool estaCompletado`: Estado de finalización.
    * `DateTime? fechaCompletado`: Marca de tiempo de cuándo se completó.
  * Métodos: `copyWith(...)`, getter calculado `DateTime get fechaHoraCompleta`.
* **`Prioridad` (`entities/prioridad.dart`):**
  * Valores: `alta` (Rojo), `media` (Amarillo), `baja` (Azul).
  * Métodos auxiliares: `label`, `color`, `indexNumeric`.
* **`PendienteRepository` (`repositories/pendiente_repository.dart`):**
  * Métodos: `obtenerTodos()`, `obtenerPorId()`, `crear()`, `actualizar()`, `eliminar()`, `obtenerPorFecha()`, `obtenerCompletados()`.

### 4.2. Capa de Datos (`lib/data/`)
* **Esquema de Base de Datos SQLite (`AppDatabase`):**
  ```sql
  CREATE TABLE pendientes (
    id TEXT PRIMARY KEY,
    titulo TEXT NOT NULL,
    descripcion TEXT,
    fecha TEXT NOT NULL,
    hora TEXT NOT NULL,
    prioridad INTEGER NOT NULL,
    tieneRecordatorio INTEGER NOT NULL,
    minutosAntes INTEGER NOT NULL,
    repetir TEXT NOT NULL,
    estaCompletado INTEGER NOT NULL,
    fechaCompletado TEXT
  );
  ```
* **Mapeador (`PendienteModel`):**
  * `toMap()`: Serializa `DateTime` a cadenas ISO-8601, `TimeOfDay` a formato `"HH:mm"`, y booleanos a `0` o `1`.
  * `fromMap()`: Deserializa datos de SQLite hacia la entidad inmutable `Pendiente`.
* **Datos Semilla:** Si la tabla está vacía en la primera ejecución, se insertan tareas predeterminadas con diferentes prioridades y fechas para demostrar las vistas de hoy, semana y mes de inmediato.

### 4.3. Capa de Estado (`lib/presentation/providers/`)
* **`PendientesProvider` (`StateNotifier<PendientesState>`):**
  * Estado (`PendientesState`):
    * `List<Pendiente> pendientes`: Lista global de tareas en memoria.
    * `bool isLoading`: Indicador de carga.
    * `Prioridad? filtroPrioridad`: Filtro activo opcional.
    * `DateTime fechaSeleccionada`: Fecha actualmente activa para la vista mensual o diaria.
  * Operaciones:
    * `cargarPendientes()`: Lee de SQLite y actualiza estado.
    * `crearPendiente(Pendiente)`: Persiste en SQLite, programa recordatorio en `NotificationService` y actualiza lista.
    * `actualizarPendiente(Pendiente)`: Actualiza SQLite y reprograma la notificación.
    * `eliminarPendiente(String id)`: Elimina de SQLite y cancela la alarma del sistema.
    * `alternarCompletado(Pendiente)`: Conmuta `estaCompletado`. Si se completa, cancela la notificación; si se desmarca, la vuelve a programar.
    * `posponerParaManana(Pendiente)`: Incrementa en 1 día la fecha y actualiza la alarma.
* **`AjustesProvider` (`StateNotifier<AjustesState>`):**
  * Gestiona preferencias persistidas con `SharedPreferences`:
    * `ThemeMode themeMode` (Sistema / Claro / Oscuro).
    * `bool notificacionesHabilitadas`.
    * `bool sonidoHabilitado`.
    * `bool vibracionHabilitada`.

### 4.4. Capa de Servicios (`lib/core/services/`)
* **`NotificationService`:**
  * Patrón Singleton (`NotificationService.instance`).
  * Usa `flutter_local_notifications` y `timezone`.
  * Canal de notificación: `mi_pendiente_alarmas` con `Importance.max` y `Priority.high`.
  * Métodos principales:
    * `init()`: Registra zonas horarias, configuraciones de Android/iOS y crea el canal nativo.
    * `pedirPermisos()`: Solicita permiso en tiempo de ejecución en Android 13+ (`POST_NOTIFICATIONS`) y iOS.
    * `mostrarNotificacionInmediata(...)`: Dispara una alerta flotante al instante para pruebas o confirmación de eventos.
    * `programarRecordatorio(Pendiente)`: Calcula la fecha y hora restando `minutosAntes` y programa una alarma exacta mediante `zonedSchedule`.
    * `cancelarRecordatorio(String id)`: Cancela la alarma asociada usando un hash entero único derivado del UUID.
    * `cancelarTodas()`: Limpia todas las alertas pendientes.

---

## 5. Las 8 Pantallas de la Aplicación

| # | Pantalla | Archivo | Responsabilidad y Componentes Clave |
|---|---|---|---|
| **1** | **Splash** | [`splash_screen.dart`](file:///C:/Users/LENOVO/.gemini/antigravity-ide/scratch/mi_pendiente/lib/presentation/screens/splash_screen.dart) | Logo 3D con calendario y check, fondo con ondas degradadas, indicador circular de carga y navegación automática al Shell en 2.2 segundos. |
| **2** | **Hoy** | [`hoy_screen.dart`](file:///C:/Users/LENOVO/.gemini/antigravity-ide/scratch/mi_pendiente/lib/presentation/screens/hoy_screen.dart) | Lista de tareas del día en curso. Muestra cabecera dinámica ("Hoy, d de MMMM"), tarjetas con barra lateral cromática de prioridad, hora formateada y checkbox interactivo con feedback visual. |
| **3** | **Semana** | [`semana_screen.dart`](file:///C:/Users/LENOVO/.gemini/antigravity-ide/scratch/mi_pendiente/lib/presentation/screens/semana_screen.dart) | Vista panorámica de los 7 días. Incluye barra de progreso de cumplimiento semanal, mini gráfico de barras de carga y acordeones expandibles para cada día de la semana. |
| **4** | **Mes** | [`mes_screen.dart`](file:///C:/Users/LENOVO/.gemini/antigravity-ide/scratch/mi_pendiente/lib/presentation/screens/mes_screen.dart) | Calendario mensual navegable (`< Mes >`), cálculo de días del mes, resaltado del día seleccionado y *dots* cromáticos bajo los números indicando la prioridad de las tareas de cada fecha. Al tocar un día, despliega la lista inferior de tareas asociadas. |
| **5** | **Nuevo / Editar** | [`nuevo_pendiente_screen.dart`](file:///C:/Users/LENOVO/.gemini/antigravity-ide/scratch/mi_pendiente/lib/presentation/screens/nuevo_pendiente_screen.dart) | Formulario completo: campo de título, notas/descripción, selector de fecha con mini calendario visual, selector de prioridad, switch de recordatorio con opciones de antelación y repetición, y el **selector desplegable de hora estilo alarma**. |
| **6** | **Detalle** | [`detalle_pendiente_screen.dart`](file:///C:/Users/LENOVO/.gemini/antigravity-ide/scratch/mi_pendiente/lib/presentation/screens/detalle_pendiente_screen.dart) | Vista en profundidad de una tarea con badge de prioridad, fecha, hora, estado del recordatorio y notas. Botones de acción táctil: *Marcar como completado*, *Editar*, *Pasar para mañana* y *Eliminar*. |
| **7** | **Completados** | [`completados_screen.dart`](file:///C:/Users/LENOVO/.gemini/antigravity-ide/scratch/mi_pendiente/lib/presentation/screens/completados_screen.dart) | Historial de productividad con métrica de tareas completadas en la semana, agrupaciones temporales (*Hoy*, *Ayer*, *Esta semana*, *Anteriores*) y botón de acción para *Restaurar* una tarea completada a la lista activa. |
| **8** | **Ajustes** | [`ajustes_screen.dart`](file:///C:/Users/LENOVO/.gemini/antigravity-ide/scratch/mi_pendiente/lib/presentation/screens/ajustes_screen.dart) | Switcher gráfico Día/Noche con vista previa reactiva (Tema Claro / Oscuro), interruptores de notificaciones, sonido y vibración, estadísticas generales de tareas y modal informativo *Acerca de*. |

---

## 6. Historial de Procesos de Desarrollo y Soluciones Clave

Durante el ciclo de desarrollo se resolvieron varios requerimientos y desafíos técnicos específicos:

### 6.1. Menú Lateral (Drawer de las 3 Rayitas)
* **Problema:** En las primeras versiones el botón de menú de 3 rayitas de la esquina superior izquierda no desplegaba el panel lateral debido a conflictos con la clave de estado del `Scaffold`.
* **Solución:** Se implementó una `GlobalKey<ScaffoldState> _scaffoldKey` en `HomeShellScreen`, conectada al `IconButton(icon: Icons.menu)` mediante `_scaffoldKey.currentState?.openDrawer()`, integrando un menú lateral con cabecera de perfil, resumen de tareas pendientes y navegación directa a las secciones.

### 6.2. Rediseño del Selector de Hora: Selector Desplegable Estilo Alarma
* **Problema Inicial:** La hora se seleccionaba mediante cuadros fijos y chips rígidos (`08:00`, `09:00`, etc.), impidiendo seleccionar horas y minutos arbitrarios con comodidad.
* **Solución Implementada:**
  * Se eliminaron los botones fijos y se diseñó un componente modal basado en `CupertinoPicker` con dos ruedas giratorias sincronizadas:
    1. **Rueda de Horas:** Valores continuos del `00` al `23`.
    2. **Rueda de Minutos:** Valores continuos del `00` al `59`.
  * **Tarjeta Digital Interactiva en Vivo:** Muestra en grande `HH : MM` con formato de 12 horas (AM/PM) que se actualiza en tiempo real mientras el usuario gira cualquiera de las ruedas.
  * Botón **"Confirmar hora"** que guarda la selección y actualiza el formulario sin bloqueos.

### 6.3. Motor de Notificaciones Nativas y Alerta Flotante ("Nubecita")
* **Problema:** Las notificaciones no se mostraban como alerta emergente en pantalla (*heads-up / floating banner* o "nubecita") en versiones modernas de Android.
* **Solución Implementada:**
  * **Configuración del Canal:** Se registró el canal `mi_pendiente_alarmas` con `Importance.max` y `Priority.high`, activando vibración y sonido.
  * **Permisos en Android:** Se incluyeron `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED` y `VIBRATE` en el `AndroidManifest.xml`.
  * **Core Library Desugaring:** En `android/app/build.gradle.kts` se activó `isCoreLibraryDesugaringEnabled = true` junto con `desugar_jdk_libs:2.1.4`, habilitando el soporte de Java time requerido por `flutter_local_notifications`.
  * **Botón de Prueba Inmediata:** En el modal de recordatorios (tocando el ícono de la campanita 🔔 superior) se añadió el botón **"🔔 Probar notificación ("Ver nubecita")"** que ejecuta `NotificationService.instance.mostrarNotificacionInmediata(...)` para validar en caliente la aparición del banner flotante.
  * **Verificación:** Probado y confirmado mediante Android Logcat y `adb shell dumpsys notification` con nivel de interrupción `mIsInterruptive=true` e `importance=5`.

---

## 7. Estado de Calidad y Pruebas Automatizadas

El proyecto cuenta con validación técnica al 100%:

1. **Análisis Estático (`flutter analyze`):**
   * **0 errores de compilación.**
   * Código completamente tipado y compatible con Material 3.
2. **Suite de Pruebas Unitarias y de Widgets (`flutter test`):**
   * `domain_and_repository_test.dart`:
     * Prueba 1: Creación de entidad `Pendiente` y conversión bidireccional `toMap` / `fromMap`.
     * Prueba 2: Método `copyWith` preservando integridad de campos inmutables.
     * Prueba 3: Mapeo cromático y etiquetas del enum `Prioridad`.
   * `widget_test.dart`:
     * Prueba 4: Inicialización correcta del widget raíz `MiPendienteApp` y `SplashScreen`.
     * Prueba 5: Despliegue del selector desplegable estilo alarma y verificación de la eliminación de chips fijos.
   * **Resultado:** 5/5 pruebas aprobadas exitosamente (`All tests passed!`).

---

## 8. Guía para Claude: Áreas Sugeridas de Auditoría y Mejora

Al presentar este documento a Claude para análisis estructural, se sugiere solicitar su evaluación en las siguientes áreas estratégicas:

1. **Estructuración de Directorios y Modularidad:**
   * ¿Es conveniente migrar de una arquitectura por capas (*Layer-First*) hacia una arquitectura por características (*Feature-First*: `features/pendientes`, `features/calendario`, `features/ajustes`) para facilitar el escalado futuro?
2. **Gestión de Casos de Uso (Use Cases):**
   * Evaluar si se deben formalizar clases de casos de uso individuales en la capa de dominio (`ObtenerPendientesHoyUseCase`, `CrearPendienteUseCase`, `PosponerPendienteUseCase`) en lugar de llamar directamente a los métodos del repositorio desde el `StateNotifier`.
3. **Manejo de Errores y Estados de UI:**
   * Evaluar la conveniencia de introducir tipos de datos sellados (*Sealed Classes* o `AsyncValue`) para modelar estados complejos de UI (`Initial`, `Loading`, `Success(data)`, `Failure(error)`).
4. **Patrón Dependency Injection:**
   * Evaluar la inyección formal de dependencias a través de providers especializados de Riverpod para `AppDatabase`, `NotificationService` y `SharedPreferences`, eliminando singletons estáticos.
5. **Estrategia de Tests y Mocking:**
   * Ampliar la cobertura de pruebas unitarias implementando dobles de prueba (*mocks*) con `mockito` o `mocktail` para simular la persistencia y la programación de notificaciones sin depender de SQLite ni del canal nativo de Android.
