# 🧭 MI PENDIENTE — DOCUMENTO MAESTRO DE REFACTORIZACIÓN

> **Este documento es la BIBLIA del refactor.**
> Antes de mover un solo archivo, lee **TODO el Bloque 1**.
> Regla de oro del proyecto (aplica a **Bloque 2, Fases 0–7**): **la UI y el diseño NO se tocan.** Ninguna de esas fases cambia un color, un padding, una animación ni el comportamiento visible de la app. Si un cambio obliga a modificar cómo se ve o se siente la app, ese cambio está mal planteado.
>
> ⚠️ **Excepción explícita:** el **Bloque 3** (Fases 8–11) es justamente lo contrario: ahí se agregan funcionalidades nuevas (racha, chatbox con IA, temas de color) y se rediseña la app a propósito. Cuando trabajes esas fases con una IA, no le pegues la regla de "no tocar el diseño" — dile que estás en el Bloque 3.

**Proyecto:** Mi Pendiente (Flutter / Dart)
**Arquitectura alcanzada:** Clean Architecture *Feature-First* + Casos de Uso + Riverpod como contenedor de DI (100% Implementada y Verificada)
**Estado del proyecto:** ✅ Fases 0 a 11 Completadas con éxito (83/83 tests pasando, 0 advertencias en flutter analyze)
**Fecha de finalización:** Septiembre 2026

---

# ═══════════════════════════════════════════════
# BLOQUE 1: CONTEXTO OBLIGATORIO
# ═══════════════════════════════════════════════

> [!CAUTION]
> **INSTRUCCIÓN PARA LA IA**: Este bloque define la arquitectura objetivo, la estructura de carpetas, las convenciones de nombres y las reglas del refactor. Todo el código que generes DEBE seguirlas. No improvises nombres de archivos, no cambies la paleta de colores, no rediseñes pantallas, no reemplaces widgets existentes. El objetivo es **mover y desacoplar código que ya funciona**, no reescribir la app.

---

## 1. DIAGNÓSTICO DEL ESTADO ACTUAL

El proyecto está sano. `flutter analyze` en 0 errores, 5/5 tests pasando, capas separadas y un contrato de repositorio ya definido. Eso es una base mucho mejor que la de la mayoría de proyectos de este tamaño. Lo que sigue **no son errores**, son fricciones que aparecen cuando el proyecto crece o cuando se quiere testear sin emulador.

### 1.1. Lo que ya está bien y NO se debe tocar

| Acierto | Por qué conservarlo |
|---|---|
| `PendienteRepository` como contrato abstracto | Ya tienes la inversión de dependencias hecha. Todo el plan se apoya en esto. |
| Entidad `Pendiente` inmutable con `copyWith` | Correcto. Solo se le quita una dependencia de Flutter (§1.2.A). |
| Separación `PendienteModel` / `Pendiente` | Mapeo explícito, sin acoplar la entidad al esquema SQL. Excelente. |
| `core/widgets/` (task_card, wave_background, priority_badge…) | Se mueven de carpeta, no se modifican por dentro. |
| `app_theme`, `app_colors`, `app_typography` | Intocables **durante el refactor (Fases 0–7)**. A partir del Bloque 3 se amplían para soportar varios temas de color — ver Fase 10. |
| Esquema SQLite | Se conserva. Solo se añade **una** columna opcional en la Fase 3. |

### 1.2. Fricciones detectadas (ordenadas por impacto)

**A. El dominio depende de Flutter.**
`Pendiente.hora` es un `TimeOfDay` y `Prioridad.color` devuelve un `Color`. Ambos vienen de `package:flutter/material.dart`. Eso significa que tu capa de "reglas de negocio puras" en realidad **no es pura**: no puede compilarse en un test de Dart plano, no puede reutilizarse en un backend o CLI, y arrastra el framework de UI hacia el centro de la arquitectura. Es la violación más profunda que tiene el proyecto y, paradójicamente, la más barata de arreglar.

**B. Singletons estáticos globales.**
`NotificationService.instance` y `AppDatabase` como singleton son invisibles para el sistema de tipos: cualquier clase puede invocarlos sin declararlo, y en un test no hay forma de sustituirlos. Por eso hoy los tests solo cubren entidad y mapeo — todo lo que toca notificaciones o DB es intesteable sin dispositivo.

**C. El `StateNotifier` hace de caso de uso.**
`posponerParaManana`, `alternarCompletado` y `crearPendiente` contienen reglas de negocio reales (sumar un día, cancelar/reprogramar alarma según el estado). Esa lógica vive hoy en la capa de presentación. Si mañana quieres posponer desde el Drawer, desde una acción de notificación o desde un swipe, terminas duplicándola.

**D. Estado de carga/error a medias.**
`PendientesState` tiene `isLoading` pero **no tiene campo de error**. Si SQLite falla, la excepción se propaga o se traga en silencio; la UI no tiene forma de mostrar un estado de fallo. Es la típica bomba de relojería que aparece el día de la demo.

**E. Una lista global filtrada en la UI.**
Todas las pantallas (Hoy, Semana, Mes, Completados) reciben `List<Pendiente> pendientes` completa y filtran dentro del `build`. Con 30 tareas no se nota; con 2000 y un calendario que reconstruye 42 celdas, sí. Además dispersa la lógica de filtrado por cuatro archivos.

**F. ID de notificación derivado por hash del UUID.**
`id.hashCode` sobre un UUID no es estable entre ejecuciones en Dart (el hash de String sí lo es dentro de una misma versión del runtime, pero el contrato no lo garantiza) y **puede colisionar** al truncarse a 32 bits. Si dos tareas colisionan, cancelar una cancela la alarma de la otra. Se resuelve guardando el ID entero en la tabla.

**G. Base de datos sin estrategia de migración.**
`AppDatabase` crea las tablas en `onCreate`, pero no hay `onUpgrade`. En el momento en que cambies el esquema, cualquier usuario con la app instalada obtiene un crash o una tabla sin la columna nueva.

**H. Detalles menores.**
- `repetir` es un `String` libre ('No repetir', 'Diario'…). Un typo compila y rompe en runtime; debería ser un `enum`.
- Los **datos semilla** viven en `AppDatabase`. Es una decisión de producto dentro de la capa de infraestructura.
- `uuid` se genera probablemente en el provider o la pantalla; debería generarse en un único punto controlado (caso de uso + servicio inyectable) para que los tests sean deterministas.

---

## 2. ARQUITECTURA OBJETIVO

### 2.1. ¿Feature-First o Layer-First? — Recomendación

**Sí, migra a Feature-First, pero híbrido.** Razones concretas para tu caso:

- Tienes **un solo agregado de negocio** (`Pendiente`) y **dos módulos de estado** (pendientes, ajustes). Un Feature-First purista con 6 features sería sobre-ingeniería.
- Pero tienes **8 pantallas** y las vistas Hoy/Semana/Mes comparten dominio y difieren solo en presentación. Agruparlas por feature hace que abrir una carpeta te dé el contexto completo.
- El beneficio real aparece cuando entra otra persona al proyecto (como en NovaMart): cada quien toma una carpeta `features/x/` y no pisa al otro.

La forma híbrida que propongo: **3 features reales + un `core` transversal fuerte.**

```
features/
├── pendientes/   ← el corazón: entidad, repo, casos de uso, Hoy, Semana, Mes, Nuevo, Detalle
├── completados/  ← solo presentación; reutiliza el dominio de pendientes
└── ajustes/      ← preferencias, tema, switches
```

> [!NOTE]
> **No** crees `features/calendario/` separado. Mes/Semana/Hoy son tres vistas del mismo agregado; separarlas duplicaría providers y casos de uso. Son `presentation/screens/` dentro de `pendientes`.

### 2.2. Flujo de datos objetivo

```
USUARIO toca el checkbox de una tarea
    ↓
WIDGET (ConsumerWidget) llama al método del Notifier
    ↓
NOTIFIER (AsyncNotifier) invoca el UseCase — no contiene reglas
    ↓
USE CASE ejecuta la regla de negocio (alternar estado + decidir la alarma)
    ↓
REPOSITORY persiste en SQLite  +  NOTIFICATION SCHEDULER programa/cancela
    ↓
REPOSITORY devuelve Result<T> (Exito | Fallo) — nunca lanza al Notifier
    ↓
NOTIFIER emite AsyncData / AsyncError
    ↓
WIDGET observa con .when(data:, loading:, error:) → UI reacciona
```

**Reglas no negociables:**
1. Un `Widget` **nunca** llama a `AppDatabase`, `NotificationService` ni al repositorio directamente.
2. Un `Notifier` **nunca** contiene una regla de negocio. Solo orquesta casos de uso y traduce a estado de UI.
3. `domain/` **nunca** importa `package:flutter/*`, `sqflite`, `shared_preferences` ni `flutter_local_notifications`. Solo Dart puro.
4. `data/` implementa contratos de `domain/`. Jamás al revés.
5. Toda dependencia se obtiene por **provider de Riverpod**, nunca por `.instance`.

---

## 3. ESTRUCTURA DE CARPETAS OBJETIVO

```
lib/
├── main.dart                                   # bootstrap + ProviderScope con overrides
├── app.dart                                    # MiPendienteApp (MaterialApp, temas, rutas, locales)
│
├── core/                                       # Transversal — sin lógica de negocio
│   ├── constants/
│   │   ├── app_colors.dart                     # ⛔ NO MODIFICAR
│   │   └── app_typography.dart                 # ⛔ NO MODIFICAR
│   ├── theme/
│   │   └── app_theme.dart                      # ⛔ NO MODIFICAR
│   ├── error/
│   │   ├── failure.dart                        # sealed class Failure (+ subtipos)
│   │   └── result.dart                         # sealed class Result<T> = Exito | Fallo
│   ├── providers/                              # 🔌 Contenedor de DI
│   │   ├── database_providers.dart             # databaseProvider (override en main)
│   │   ├── preferences_providers.dart          # sharedPreferencesProvider (override en main)
│   │   ├── notification_providers.dart         # notificationSchedulerProvider
│   │   └── clock_providers.dart                # relojProvider, uuidProvider (tests deterministas)
│   ├── services/
│   │   ├── notification_service.dart           # impl. concreta de NotificationScheduler
│   │   └── reloj.dart                          # Reloj / RelojDelSistema
│   ├── utils/
│   │   └── date_time_utils.dart                # formateadores es_ES (presentación)
│   └── widgets/                                # Widgets compartidos entre features
│       ├── priority_badge.dart                 # ⛔ interior intacto
│       ├── segmented_view_tabs.dart            # ⛔ interior intacto
│       ├── task_card.dart                      # ⛔ interior intacto
│       └── wave_background.dart                # ⛔ interior intacto
│
├── features/
│   ├── pendientes/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── pendiente.dart              # Dart puro — sin TimeOfDay
│   │   │   │   ├── prioridad.dart              # enum sin Color
│   │   │   │   ├── hora_del_dia.dart           # value object (hora, minuto)
│   │   │   │   └── repeticion.dart             # enum: noRepetir, diario, semanal, mensual
│   │   │   ├── repositories/
│   │   │   │   └── pendiente_repository.dart   # contrato → devuelve Result<T>
│   │   │   ├── services/
│   │   │   │   └── notification_scheduler.dart # contrato abstracto de alarmas
│   │   │   └── usecases/
│   │   │       ├── obtener_pendientes.dart
│   │   │       ├── crear_pendiente.dart
│   │   │       ├── actualizar_pendiente.dart
│   │   │       ├── eliminar_pendiente.dart
│   │   │       ├── alternar_completado.dart
│   │   │       └── posponer_para_manana.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── app_database.dart           # gestor SQLite (ya no singleton)
│   │   │   │   └── pendiente_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── pendiente_model.dart        # toMap / fromMap
│   │   │   └── repositories/
│   │   │       └── pendiente_repository_impl.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── pendientes_notifier.dart    # AsyncNotifier<List<Pendiente>>
│   │       │   ├── pendientes_derivados.dart   # providers de Hoy / Semana / Mes / filtros
│   │       │   └── usecase_providers.dart      # providers de cada caso de uso
│   │       ├── screens/
│   │       │   ├── hoy_screen.dart             # ⛔ UI intacta
│   │       │   ├── semana_screen.dart          # ⛔ UI intacta
│   │       │   ├── mes_screen.dart             # ⛔ UI intacta
│   │       │   ├── nuevo_pendiente_screen.dart # ⛔ UI intacta
│   │       │   └── detalle_pendiente_screen.dart
│   │       └── mappers/
│   │           └── prioridad_ui.dart           # extension Prioridad → Color / label
│   │
│   ├── completados/
│   │   └── presentation/
│   │       ├── providers/completados_providers.dart
│   │       └── screens/completados_screen.dart
│   │
│   ├── ajustes/
│   │   ├── domain/
│   │   │   └── repositories/ajustes_repository.dart
│   │   ├── data/
│   │   │   └── repositories/ajustes_repository_impl.dart  # SharedPreferences
│   │   └── presentation/
│   │       ├── providers/ajustes_notifier.dart
│   │       └── screens/ajustes_screen.dart
│   │
│   ├── racha/                                  # 🆕 Bloque 4 — Fase 8
│   │   ├── domain/
│   │   │   ├── entities/racha.dart
│   │   │   ├── entities/hito_racha.dart
│   │   │   ├── repositories/racha_repository.dart
│   │   │   └── usecases/actualizar_racha.dart
│   │   ├── data/repositories/racha_repository_impl.dart
│   │   └── presentation/
│   │       ├── providers/racha_provider.dart
│   │       ├── screens/mis_logros_screen.dart
│   │       └── widgets/banner_racha.dart
│   │
│   └── asistente/                              # 🆕 Bloque 4 — Fase 9
│       ├── domain/
│       │   ├── entities/mensaje_chat.dart
│       │   ├── entities/limite_chat.dart
│       │   ├── repositories/asistente_repository.dart
│       │   └── usecases/
│       │       ├── interpretar_mensaje.dart
│       │       └── verificar_limite_chat.dart
│       ├── data/
│       │   ├── datasources/ia_datasource.dart
│       │   └── repositories/asistente_repository_impl.dart
│       └── presentation/
│           ├── providers/chat_notifier.dart
│           ├── screens/chat_screen.dart
│           └── widgets/
│               ├── burbuja_mensaje.dart
│               └── boton_microfono.dart
│
└── shell/
    ├── splash_screen.dart
    └── home_shell_screen.dart                  # Drawer + BottomNav + banner de racha
```

### 3.1. Mapa de migración (archivo por archivo)

| Archivo actual | Destino |
|---|---|
| `domain/entities/pendiente.dart` | `features/pendientes/domain/entities/pendiente.dart` |
| `domain/entities/prioridad.dart` | `features/pendientes/domain/entities/prioridad.dart` |
| `domain/repositories/pendiente_repository.dart` | `features/pendientes/domain/repositories/` |
| `data/datasources/app_database.dart` | `features/pendientes/data/datasources/` |
| `data/models/pendiente_model.dart` | `features/pendientes/data/models/` |
| `data/repositories/pendiente_repository_impl.dart` | `features/pendientes/data/repositories/` |
| `presentation/providers/pendientes_provider.dart` | `features/pendientes/presentation/providers/pendientes_notifier.dart` |
| `presentation/providers/ajustes_provider.dart` | `features/ajustes/presentation/providers/ajustes_notifier.dart` |
| `presentation/screens/hoy·semana·mes·nuevo·detalle` | `features/pendientes/presentation/screens/` |
| `presentation/screens/completados_screen.dart` | `features/completados/presentation/screens/` |
| `presentation/screens/ajustes_screen.dart` | `features/ajustes/presentation/screens/` |
| `presentation/screens/splash·home_shell` | `shell/` |
| `core/*` | `core/*` (sin cambios de contenido) |

> [!IMPORTANT]
> Mueve los archivos con **Refactor → Move** del IDE (VS Code o Android Studio), nunca arrastrando en el explorador. El IDE reescribe todos los `import` automáticamente. Mover a mano en un proyecto de 25 archivos garantiza una tarde perdida.

---

## 4. CONVENCIONES DE CÓDIGO PARA EL REFACTOR

| Elemento | Convención | Ejemplo |
|---|---|---|
| Caso de uso | Clase con un único método público `call()` | `class CrearPendiente { Future<Result<void>> call(Pendiente p) }` |
| Provider de caso de uso | `Provider<T>` de solo lectura | `final crearPendienteProvider = Provider(...)` |
| Notifier de lista | `AsyncNotifierProvider` | `pendientesProvider` |
| Provider derivado | `Provider` que observa a otro | `pendientesDeHoyProvider` |
| Contrato abstracto | Nombre sin sufijo | `PendienteRepository` |
| Implementación | Sufijo `Impl` | `PendienteRepositoryImpl` |
| Archivos | `snake_case.dart` | `posponer_para_manana.dart` |
| Idioma del código | Español para dominio y negocio (ya es tu convención), inglés solo para términos técnicos estándar | `obtenerPorFecha`, `AsyncValue` |

---

# ═══════════════════════════════════════════════
# BLOQUE 2: FASES DE EJECUCIÓN
# ═══════════════════════════════════════════════

Siete fases, cada una **independiente y desplegable**. Al terminar cualquiera de ellas la app compila, pasa los tests y se ve exactamente igual. Si te quedas sin tiempo en la Fase 4, tienes 4 fases de valor real y ninguna a medias.

**Orden recomendado y por qué:** primero se limpia el dominio (Fase 1), luego se inyectan dependencias (Fase 2) — ambas cosas son prerrequisito de los casos de uso (Fase 4). La mudanza de carpetas (Fase 5) va **después** de que los contratos estén estables, para mover una sola vez. Los tests (Fase 7) van al final porque recién ahí todo es mockeable.

---

## 🟦 FASE 0: Red de seguridad
**Duración:** 30 minutos. **Riesgo:** nulo. **No la saltes.**

### Objetivo
Garantizar que puedes volver atrás y que sabrás si rompiste algo.

### Tareas
1. Rama dedicada: `git checkout -b refactor/arquitectura`
2. Commit limpio del estado actual (`flutter analyze` en 0, 5/5 tests).
3. Captura de pantalla de las 8 pantallas en tema claro y oscuro → carpeta `docs/baseline/`. Esta es tu referencia visual: al final de cada fase comparas.
4. Añadir a `test/` un *smoke test* por pantalla que solo verifique que renderiza sin excepción.
5. Etiquetar: `git tag pre-refactor`

### Criterio de completado ✅
- [x] Rama creada y commit base hecho
- [x] 16 capturas de referencia guardadas
- [x] Smoke tests de las 8 pantallas pasando

---

## 🟦 FASE 1: Dominio puro (quitar Flutter del centro)
**Duración:** 2–3 horas. **Riesgo:** bajo. **Impacto:** alto.

### Objetivo
Que `features/pendientes/domain/` compile sin importar una sola línea de Flutter.

### Cambios

**1. `HoraDelDia` reemplaza a `TimeOfDay` en la entidad.**

```dart
// domain/entities/hora_del_dia.dart  — Dart puro
class HoraDelDia implements Comparable<HoraDelDia> {
  final int hora;    // 0–23
  final int minuto;  // 0–59

  const HoraDelDia({required this.hora, required this.minuto})
      : assert(hora >= 0 && hora <= 23),
        assert(minuto >= 0 && minuto <= 59);

  /// Formato de persistencia: "HH:mm" — idéntico al actual, sin migración de DB.
  factory HoraDelDia.desdeTexto(String texto) {
    final partes = texto.split(':');
    return HoraDelDia(
      hora: int.parse(partes[0]),
      minuto: int.parse(partes[1]),
    );
  }

  String get comoTexto =>
      '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';

  @override
  int compareTo(HoraDelDia otra) =>
      (hora * 60 + minuto).compareTo(otra.hora * 60 + otra.minuto);

  @override
  bool operator ==(Object other) =>
      other is HoraDelDia && other.hora == hora && other.minuto == minuto;

  @override
  int get hashCode => Object.hash(hora, minuto);
}
```

Y el puente hacia la UI, **en presentación**:

```dart
// presentation/mappers/hora_ui.dart
import 'package:flutter/material.dart';

extension HoraDelDiaUI on HoraDelDia {
  TimeOfDay get comoTimeOfDay => TimeOfDay(hour: hora, minute: minuto);
}

extension TimeOfDayDominio on TimeOfDay {
  HoraDelDia get comoHoraDelDia => HoraDelDia(hora: hour, minuto: minute);
}
```

El `CupertinoPicker` de la pantalla Nuevo sigue funcionando igual: solo cambia el tipo en el que guardas el valor confirmado.

**2. `Prioridad` sin `Color`.**

```dart
// domain/entities/prioridad.dart — Dart puro
enum Prioridad {
  alta(severidad: 3),
  media(severidad: 2),
  baja(severidad: 1);

  const Prioridad({required this.severidad});
  final int severidad;
}
```

```dart
// presentation/mappers/prioridad_ui.dart
extension PrioridadUI on Prioridad {
  String get label => switch (this) {
        Prioridad.alta => 'Alta',
        Prioridad.media => 'Media',
        Prioridad.baja => 'Baja',
      };

  Color get color => switch (this) {
        Prioridad.alta => AppColors.prioridadAlta,   // #FF3B30
        Prioridad.media => AppColors.prioridadMedia, // #FF9500
        Prioridad.baja => AppColors.prioridadBaja,   // #007AFF
      };
}
```

> Los colores **siguen siendo exactamente los mismos**, solo cambian de carpeta. Verifica contra las capturas de la Fase 0.

**3. `Repeticion` como enum** con `desdeTexto`/`comoTexto` para no tocar el esquema SQL (la columna sigue siendo `TEXT` con los mismos valores).

**4. `Failure` y `Result`.**

```dart
// core/error/failure.dart
sealed class Failure {
  const Failure(this.mensaje);
  final String mensaje;
}

class FallaBaseDeDatos extends Failure {
  const FallaBaseDeDatos([super.mensaje = 'No se pudieron cargar tus pendientes']);
}

class FallaNotificaciones extends Failure {
  const FallaNotificaciones([super.mensaje = 'No se pudo programar el recordatorio']);
}

class FallaPermisos extends Failure {
  const FallaPermisos([super.mensaje = 'Activa los permisos de notificación en Ajustes']);
}

class FallaNoEncontrado extends Failure {
  const FallaNoEncontrado([super.mensaje = 'Ese pendiente ya no existe']);
}
```

```dart
// core/error/result.dart
sealed class Result<T> {
  const Result();
}

class Exito<T> extends Result<T> {
  const Exito(this.valor);
  final T valor;
}

class Fallo<T> extends Result<T> {
  const Fallo(this.failure);
  final Failure failure;
}
```

> Los mensajes van en español y **orientados al usuario**, no al programador. Nada de "SqfliteDatabaseException: no such column". Ese texto termina en un `SnackBar`.

### Criterio de completado ✅
- [x] Ningún archivo bajo `domain/` importa `package:flutter/*`
- [x] `HoraDelDia` serializa a `"HH:mm"` idéntico al formato actual
- [x] Los 3 colores de prioridad se ven idénticos a las capturas base
- [x] `flutter analyze` en 0, tests existentes adaptados y pasando

### Prompt sugerido para la IA
```
Proyecto Mi Pendiente (Flutter). Estoy en la FASE 1 del refactor: purificar el dominio.
[PEGAR BLOQUE 1 COMPLETO]

Tarea:
1. Crear HoraDelDia (Dart puro) y reemplazar TimeOfDay en la entidad Pendiente.
   Persistencia sigue siendo "HH:mm" — NO cambiar el esquema SQLite.
2. Quitar Color y label del enum Prioridad; moverlos a extensions en presentación
   usando EXACTAMENTE los colores actuales (#FF3B30, #FF9500, #007AFF).
3. Convertir 'repetir' de String a enum Repeticion, conservando los mismos
   valores de texto en la base de datos.
4. Crear core/error/failure.dart y core/error/result.dart según el Bloque 1.
5. Actualizar PendienteModel.toMap/fromMap y los archivos de UI afectados,
   sin modificar ningún widget visualmente.

Muéstrame los archivos completos y una lista de los imports que hay que ajustar.
```

---

## 🟦 FASE 2: Inyección de dependencias (matar los singletons)
**Duración:** 2 horas. **Riesgo:** medio (toca `main.dart`). **Impacto:** alto — desbloquea todos los tests.

### Objetivo
Que `AppDatabase`, `NotificationService` y `SharedPreferences` se obtengan por provider y puedan sustituirse en tests.

### Patrón: *provider que explota si no se sobreescribe*

```dart
// core/providers/preferences_providers.dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Debe sobreescribirse en main()');
});
```

```dart
// main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final prefs = await SharedPreferences.getInstance();
  final db = await AppDatabase.abrir();
  final notificaciones = NotificationServiceImpl();
  await notificaciones.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        notificationSchedulerProvider.overrideWithValue(notificaciones),
      ],
      child: const MiPendienteApp(),
    ),
  );
}
```

**Contrato abstracto de notificaciones** (esto es lo que permite testear sin Android):

```dart
// domain/services/notification_scheduler.dart — Dart puro
abstract interface class NotificationScheduler {
  Future<void> programarRecordatorio({
    required int notificacionId,
    required String titulo,
    required String cuerpo,
    required DateTime cuando,
  });

  Future<void> cancelarRecordatorio(int notificacionId);
  Future<void> cancelarTodas();
  Future<bool> pedirPermisos();
}
```

`NotificationService` actual pasa a llamarse `NotificationServiceImpl`, implementa esta interfaz y **su lógica interna no cambia** (mismo canal `mi_pendiente_alarmas`, misma `Importance.max`, mismo `zonedSchedule`). Solo deja de ser singleton y deja de recibir un `Pendiente` (recibe primitivos, para no acoplar el servicio al dominio).

**Reloj y UUID inyectables** — el truco que hace tests deterministas:

```dart
// core/providers/clock_providers.dart
final relojProvider = Provider<Reloj>((ref) => const RelojDelSistema());
final uuidProvider = Provider<String Function()>((ref) => () => const Uuid().v4());
```

Ahora `posponerParaManana` y "Hoy" se pueden testear congelando la fecha, sin depender del día real.

### Criterio de completado ✅
- [x] Cero apariciones de `NotificationService.instance` en el proyecto
- [x] `AppDatabase` ya no expone constructor estático singleton
- [x] La app arranca, muestra el splash y carga los pendientes igual que antes
- [x] El botón "🔔 Probar notificación" sigue mostrando la nubecita

### Prompt sugerido para la IA
```
Proyecto Mi Pendiente (Flutter). FASE 2 del refactor: inyección de dependencias con Riverpod.
[PEGAR BLOQUE 1 COMPLETO]
La FASE 1 ya está hecha: el dominio es Dart puro y existen Result/Failure.

Tarea:
1. Crear los providers de core/providers/ según el Bloque 1, con el patrón
   de UnimplementedError + override en main().
2. Definir el contrato NotificationScheduler en el dominio y convertir el
   NotificationService actual en NotificationServiceImpl, conservando EXACTAMENTE
   el canal 'mi_pendiente_alarmas', Importance.max, Priority.high y zonedSchedule.
3. Quitar el patrón singleton de AppDatabase; que main() la abra y la inyecte.
4. Crear Reloj/RelojDelSistema y el provider de uuid.
5. Reescribir main.dart con ProviderScope + overrides.

No cambies nada del comportamiento de notificaciones ni de la inicialización FFI.
```

---

## 🟦 FASE 3: Repositorio robusto, migraciones y ID de notificación
**Duración:** 2–3 horas. **Riesgo:** medio (toca el esquema). **Impacto:** alto — quita dos bombas de relojería.

### Objetivo
Que ningún error de SQLite escape hacia arriba como excepción cruda, y que las alarmas no colisionen.

### Cambios

**1. El contrato devuelve `Result<T>`:**

```dart
abstract interface class PendienteRepository {
  Future<Result<List<Pendiente>>> obtenerTodos();
  Future<Result<Pendiente>> obtenerPorId(String id);
  Future<Result<void>> crear(Pendiente pendiente);
  Future<Result<void>> actualizar(Pendiente pendiente);
  Future<Result<void>> eliminar(String id);
  Future<Result<List<Pendiente>>> obtenerPorFecha(DateTime fecha);
  Future<Result<List<Pendiente>>> obtenerCompletados();
}
```

```dart
// data/repositories/pendiente_repository_impl.dart
@override
Future<Result<List<Pendiente>>> obtenerTodos() async {
  try {
    final filas = await _db.query('pendientes', orderBy: 'fecha ASC, hora ASC');
    return Exito(filas.map(PendienteModel.fromMap).toList());
  } on DatabaseException catch (e, s) {
    _log.severe('obtenerTodos falló', e, s);
    return const Fallo(FallaBaseDeDatos());
  }
}
```

> El `try/catch` vive **solo aquí**, en el borde con la infraestructura. Ni el caso de uso ni el notifier vuelven a envolver nada en try/catch.

**2. Columna `notificacion_id` + migración real:**

```dart
static const _version = 2;

Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
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
      fechaCompletado TEXT,
      notificacion_id INTEGER
    );
  ''');
  await db.execute('CREATE INDEX idx_pendientes_fecha ON pendientes(fecha);');
  await db.execute(
      'CREATE INDEX idx_pendientes_completado ON pendientes(estaCompletado);');
}

Future<void> _onUpgrade(Database db, int desde, int hasta) async {
  if (desde < 2) {
    await db.execute('ALTER TABLE pendientes ADD COLUMN notificacion_id INTEGER;');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pendientes_fecha ON pendientes(fecha);');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_pendientes_completado ON pendientes(estaCompletado);');
  }
}
```

El `notificacion_id` se genera **una vez** al crear la tarea (`DateTime.now().microsecondsSinceEpoch.remainder(1 << 31)` o un contador persistido) y se guarda. Cancelar deja de depender de `id.hashCode`.

Los dos índices son gratis y aceleran directamente las vistas Hoy, Mes y Completados.

**3. Datos semilla fuera de `AppDatabase`:** muévelos a `data/datasources/seed_data.dart` y ejecútalos desde un `SembrarDatosIniciales` invocado en el bootstrap. Así puedes desactivarlos con un flag sin tocar la clase de base de datos.

### Criterio de completado ✅
- [x] Ningún método del repositorio lanza excepciones hacia arriba
- [x] Instalar la versión nueva sobre la anterior **no pierde datos** (probar con la app ya instalada, no en emulador limpio)
- [x] Cancelar el recordatorio de una tarea no afecta a ninguna otra
- [x] Crear/completar/eliminar/posponer siguen funcionando idénticamente

---

## 🟦 FASE 4: Casos de uso
**Duración:** 3–4 horas. **Riesgo:** bajo. **Impacto:** alto — es el corazón de tu pregunta.

### Objetivo
Sacar las reglas de negocio del `StateNotifier` y ponerlas donde pertenecen.

### ¿Vale la pena formalizarlos? — Sí, **en los 3 que tienen regla real**

Seré honesto contigo en esto, porque es donde más se sobre-ingeniería: un caso de uso que solo hace `return repo.eliminar(id)` **no aporta nada**, solo una capa de indirección y un archivo más. La prueba para decidir es: *¿hay una decisión de negocio aquí, o es un reenvío?*

| Caso de uso | ¿Tiene regla real? | Veredicto |
|---|---|---|
| `AlternarCompletado` | Sí: decide cancelar o reprogramar la alarma, y sella `fechaCompletado` | **Crear** |
| `PosponerParaManana` | Sí: suma un día, recalcula la alarma, valida que no esté completado | **Crear** |
| `CrearPendiente` | Sí: genera UUID + notificacionId, valida título no vacío, programa alarma si corresponde | **Crear** |
| `ActualizarPendiente` | Sí: reprograma o cancela según cambie el recordatorio | **Crear** |
| `EliminarPendiente` | Regla mínima: cancelar alarma + borrar | **Crear** (coordina 2 fuentes) |
| `ObtenerPendientes` | No: reenvío puro | **No crear** — el notifier llama al repo |

Ejemplo del más representativo:

```dart
// domain/usecases/alternar_completado.dart
class AlternarCompletado {
  const AlternarCompletado(this._repo, this._alarmas, this._reloj);

  final PendienteRepository _repo;
  final NotificationScheduler _alarmas;
  final Reloj _reloj;

  Future<Result<Pendiente>> call(Pendiente pendiente) async {
    final completandoAhora = !pendiente.estaCompletado;

    final actualizado = pendiente.copyWith(
      estaCompletado: completandoAhora,
      fechaCompletado: completandoAhora ? _reloj.ahora() : null,
      limpiarFechaCompletado: !completandoAhora,
    );

    final guardado = await _repo.actualizar(actualizado);
    if (guardado case Fallo(:final failure)) return Fallo(failure);

    // Regla: una tarea completada no debe sonar; al restaurarla, vuelve a sonar
    // solo si su hora sigue en el futuro.
    if (completandoAhora) {
      await _alarmas.cancelarRecordatorio(actualizado.notificacionId);
    } else if (actualizado.tieneRecordatorio &&
        actualizado.momentoDeAviso.isAfter(_reloj.ahora())) {
      await _alarmas.programarRecordatorio(
        notificacionId: actualizado.notificacionId,
        titulo: actualizado.titulo,
        cuerpo: actualizado.descripcion ?? 'Tienes un pendiente programado',
        cuando: actualizado.momentoDeAviso,
      );
    }

    return Exito(actualizado);
  }
}
```

Fíjate en el detalle de `isAfter(_reloj.ahora())`: hoy, si desmarcas una tarea de ayer, el código actual intenta programar una alarma en el pasado. Esa clase de bug aparece solo cuando la regla se escribe en un lugar donde se puede leer completa.

Providers correspondientes:

```dart
// presentation/providers/usecase_providers.dart
final alternarCompletadoProvider = Provider(
  (ref) => AlternarCompletado(
    ref.watch(pendienteRepositoryProvider),
    ref.watch(notificationSchedulerProvider),
    ref.watch(relojProvider),
  ),
);
```

### Criterio de completado ✅
- [x] `pendientes_notifier.dart` no contiene ningún `copyWith` de negocio ni cálculo de fechas
- [x] Los 5 casos de uso existen, cada uno con un único `call()`
- [x] Ningún caso de uso importa Flutter
- [x] Comportamiento idéntico verificado a mano en las 8 pantallas

---

## 🟦 FASE 5: Migración a Feature-First
**Duración:** 1–2 horas (mecánica). **Riesgo:** bajo si usas el IDE. **Impacto:** organizativo.

### Objetivo
Ejecutar el mapa de migración de §3.1.

### Procedimiento
1. Crea el árbol de carpetas vacío primero.
2. Mueve **una carpeta por commit**, en este orden: `domain` → `data` → `presentation` → `screens` → `shell`.
3. Tras cada movimiento: `flutter analyze` + `flutter test`. Si algo falla, el commit anterior está sano.
4. Extrae `MiPendienteApp` de `main.dart` a `app.dart` (deja `main.dart` solo con el bootstrap).
5. Al final, ningún archivo debe tener un import con `../../../`. Usa imports de paquete (`package:mi_pendiente/features/...`).

### Criterio de completado ✅
- [x] El árbol coincide con §3 exactamente
- [x] Cero imports relativos que salgan de su carpeta
- [x] `flutter analyze` en 0
- [x] Capturas comparadas contra la baseline: idénticas

---

## 🟦 FASE 6: Estados de UI con AsyncValue
**Duración:** 3–4 horas. **Riesgo:** medio (toca las pantallas). **Impacto:** alto en robustez.

### Objetivo
Modelar `Initial / Loading / Success / Failure` sin inventar nada: Riverpod ya te lo da hecho con `AsyncValue`.

> [!NOTE]
> **No crees una sealed class propia para el estado de UI.** Tu documento lo plantea como alternativa, pero `AsyncValue` de Riverpod ya es exactamente eso, con `.when()`, manejo de `isRefreshing` y preservación del dato anterior durante recargas. Escribir la tuya sería reimplementar peor algo que ya tienes en el proyecto.

```dart
// presentation/providers/pendientes_notifier.dart
class PendientesNotifier extends AsyncNotifier<List<Pendiente>> {
  @override
  Future<List<Pendiente>> build() async {
    final resultado = await ref.watch(pendienteRepositoryProvider).obtenerTodos();
    return switch (resultado) {
      Exito(:final valor) => valor,
      Fallo(:final failure) => throw failure,
    };
  }

  Future<void> alternarCompletado(Pendiente pendiente) async {
    final caso = ref.read(alternarCompletadoProvider);
    final resultado = await caso(pendiente);

    switch (resultado) {
      case Exito(:final valor):
        // Actualización local: sin golpear SQLite ni parpadeo del checkbox
        state = AsyncData([
          for (final p in state.valueOrNull ?? <Pendiente>[])
            if (p.id == valor.id) valor else p,
        ]);
      case Fallo(:final failure):
        ref.read(mensajeErrorProvider.notifier).state = failure.mensaje;
    }
  }
}

final pendientesProvider =
    AsyncNotifierProvider<PendientesNotifier, List<Pendiente>>(
        PendientesNotifier.new);
```

**Providers derivados — el cambio que más rendimiento te da:**

```dart
final pendientesDeHoyProvider = Provider<AsyncValue<List<Pendiente>>>((ref) {
  final hoy = ref.watch(relojProvider).ahora();
  return ref.watch(pendientesProvider).whenData(
        (lista) => lista
            .where((p) => !p.estaCompletado && esMismoDia(p.fecha, hoy))
            .sortedBy((p) => p.hora)
            .toList(),
      );
});

final pendientesPorFechaProvider =
    Provider.family<AsyncValue<List<Pendiente>>, DateTime>((ref, fecha) {
  return ref.watch(pendientesProvider).whenData(
        (lista) => lista.where((p) => esMismoDia(p.fecha, fecha)).toList(),
      );
});
```

`MesScreen` pasa de filtrar 42 veces dentro del `build` a leer un provider cacheado por fecha.

**En las pantallas, el cambio es mínimo y no afecta al diseño:**

```dart
ref.watch(pendientesDeHoyProvider).when(
  data: (tareas) => _listaActual(tareas),        // tu widget actual, sin cambios
  loading: () => const _SkeletonLista(),          // reemplaza al isLoading actual
  error: (e, _) => _EstadoError(                  // NUEVO: hoy no existe
    mensaje: e is Failure ? e.mensaje : 'Algo salió mal',
    onReintentar: () => ref.invalidate(pendientesProvider),
  ),
);
```

`_EstadoError` es el único widget nuevo del refactor completo. Diséñalo con los estilos de `app_typography` y `app_colors` ya existentes para que se sienta parte de la app.

### Criterio de completado ✅
- [x] `PendientesState` manual eliminado; todo pasa por `AsyncValue`
- [x] Ninguna pantalla filtra la lista completa dentro de `build`
- [x] Forzando un error de DB a propósito, la app muestra el estado de error con botón reintentar en vez de crashear
- [x] Marcar un checkbox no produce parpadeo ni recarga completa de la lista

---

## 🟦 FASE 7: Tests con dobles de prueba
**Duración:** 3–4 horas. **Impacto:** cierra el círculo del refactor.

### Objetivo
Pasar de 5 tests a una suite que cubra las reglas de negocio sin emulador.

Usa **`mocktail`** (no `mockito`): no requiere `build_runner`, no genera archivos, y en un proyecto de este tamaño la generación de código es puro costo.

```yaml
dev_dependencies:
  mocktail: ^1.0.4
  sqflite_common_ffi: ^2.3.3  # ya lo tienes
```

### Qué testear (por valor, no por cobertura)

| Test | Qué protege |
|---|---|
| `AlternarCompletado` cancela la alarma al completar | La regla más usada de la app |
| `AlternarCompletado` **no** reprograma si la hora ya pasó | El bug latente que encontramos en §Fase 4 |
| `PosponerParaManana` suma exactamente 1 día con reloj congelado | Cálculo de fechas |
| `CrearPendiente` rechaza título vacío | Validación |
| `PendienteRepositoryImpl` devuelve `Fallo(FallaBaseDeDatos)` ante excepción | Manejo de errores |
| Round-trip `toMap`/`fromMap` con `HoraDelDia` y `Repeticion` | La migración de la Fase 1 |
| `pendientesDeHoyProvider` filtra correctamente con reloj congelado | Lógica de las 3 vistas |
| Smoke tests de las 8 pantallas (ya los tienes de la Fase 0) | Regresión visual básica |

```dart
class MockRepo extends Mock implements PendienteRepository {}
class MockAlarmas extends Mock implements NotificationScheduler {}

test('completar una tarea cancela su recordatorio', () async {
  final repo = MockRepo();
  final alarmas = MockAlarmas();
  final reloj = RelojFijo(DateTime(2026, 9, 17, 10, 0));

  when(() => repo.actualizar(any())).thenAnswer((_) async => const Exito(null));
  when(() => alarmas.cancelarRecordatorio(any())).thenAnswer((_) async {});

  final caso = AlternarCompletado(repo, alarmas, reloj);
  await caso(unPendienteDePrueba(estaCompletado: false, notificacionId: 42));

  verify(() => alarmas.cancelarRecordatorio(42)).called(1);
  verifyNever(() => alarmas.programarRecordatorio(
      notificacionId: any(named: 'notificacionId'),
      titulo: any(named: 'titulo'),
      cuerpo: any(named: 'cuerpo'),
      cuando: any(named: 'cuando')));
});
```

Para el repositorio, usa SQLite **en memoria** con `sqflite_common_ffi` (`inMemoryDatabasePath`): tests reales contra SQL de verdad, sin emulador y sin archivos.

### Criterio de completado ✅
- [x] ≥ 20 tests, todos verdes (alcanzados 83 tests automatizados)
- [x] Ningún test requiere emulador Android
- [x] Los tests corren en menos de 10 segundos (~4 segundos reales)

---

# ═══════════════════════════════════════════════
# BLOQUE 3: NUEVAS FUNCIONALIDADES (racha, chat IA, temas, rediseño)
# ═══════════════════════════════════════════════

> [!CAUTION]
> **INSTRUCCIÓN PARA LA IA**: A partir de aquí la regla "no tocar el diseño" **ya no aplica**. Estas cuatro fases son features nuevas y un rediseño intencional. Sí deben respetar la arquitectura ya definida en el Bloque 1 (domain sin Flutter, casos de uso sin lógica en la UI, DI por Riverpod): lo único que cambia es que el diseño visual puede — y debe — moverse.

**Orden recomendado:** 8 → 9 → 10 → 11. La racha (8) va primero porque el chatbox (9) y los temas (10) dependen de sus hitos de desbloqueo (día 30 y día 50). El rediseño (11) va al final porque toca todas las pantallas, incluidas las nuevas.

---

## 🟦 FASE 8: Sistema de Racha 🔥 y Recompensas
**Duración:** 4–6 horas. **Impacto:** alto (retención).

### Objetivo
Calcular una racha de días consecutivos completando pendientes, mostrarla al iniciar sesión y desbloquear recompensas en hitos definidos (incluyendo día 30 y día 50, que otras fases usan).

### 8.1 Regla de negocio
- La racha sube **+1** cuando el usuario completa **al menos 1 pendiente** en el día natural (hora local) — completar varios el mismo día no suma más de una vez.
- Si pasa un día natural completo sin completar ningún pendiente, la racha se reinicia a 0.
- Se guarda por separado `mejorRacha` (récord histórico), que no se reinicia.

### 8.2 Modelo de dominio

```dart
// features/racha/domain/entities/racha.dart — Dart puro
class Racha {
  final int diasActuales;
  final int mejorRacha;
  final DateTime? ultimaFechaCompletado;
  final List<String> logrosDesbloqueados; // ids de HitoRacha

  const Racha({
    required this.diasActuales,
    required this.mejorRacha,
    required this.ultimaFechaCompletado,
    required this.logrosDesbloqueados,
  });
}
```

```dart
// features/racha/domain/entities/hito_racha.dart
enum RangoRacha {
  bronce(nombre: 'Bronce', icono: '🥉', diasMinimos: 0, nivel: 1),
  oro(nombre: 'Oro', icono: '🥇', diasMinimos: 30, nivel: 2),
  diamante(nombre: 'Diamante', icono: '💎', diasMinimos: 60, nivel: 3),
  leyenda(nombre: 'Leyenda', icono: '👑', diasMinimos: 90, nivel: 4);

  const RangoRacha({
    required this.nombre,
    required this.icono,
    required this.diasMinimos,
    required this.nivel,
  });

  final String nombre;
  final String icono;
  final int diasMinimos;
  final int nivel;
}

enum HitoRacha {
  // RANGO 1: BRONCE (1 a 30 días)
  dias3(dias: 3, recompensa: 'Insignia de bronce', titulo: 'Hábito Inicial', rango: RangoRacha.bronce),
  dias7(dias: 7, recompensa: 'Tema "Atardecer" desbloqueado', titulo: 'Primera Semana', rango: RangoRacha.bronce),
  dias10(dias: 10, recompensa: 'Icono especial + Comodín de racha', titulo: 'Constancia', rango: RangoRacha.bronce),
  dias15(dias: 15, recompensa: 'Asistente por voz desbloqueado 🎙️', titulo: 'Poder de la Voz', rango: RangoRacha.bronce),
  dias22(dias: 22, recompensa: 'Pack de sonidos + Insignia de Enfoque', titulo: 'Enfoque Imparable', rango: RangoRacha.bronce),
  dias30(dias: 30, recompensa: 'Tema "Aurora" + Estadísticas avanzadas', titulo: 'Maestría Mensual', rango: RangoRacha.bronce),

  // RANGO 2: ORO (31 a 60 días)
  dias37(dias: 37, recompensa: 'Insignia de Oro + Widget exclusivo', titulo: 'Impulso Dorado', rango: RangoRacha.oro),
  dias44(dias: 44, recompensa: 'Tema "Bosque" + Doble comodín', titulo: 'Disciplina Férrea', rango: RangoRacha.oro),
  dias51(dias: 51, recompensa: 'Modo Superproductivo + Sonidos Zen', titulo: 'Hábito de Acero', rango: RangoRacha.oro),
  dias58(dias: 58, recompensa: 'Insignia de Campeón + Respaldo prioritario', titulo: 'Respaldo de Campeón', rango: RangoRacha.oro),

  // RANGO 3: DIAMANTE (61 a 90 días)
  dias65(dias: 65, recompensa: 'Insignia Diamante + Filtro exclusivo', titulo: 'Mente Brillante', rango: RangoRacha.diamante),
  dias72(dias: 72, recompensa: 'Tema "Neón" + 3 Comodines de racha', titulo: 'Constancia Pura', rango: RangoRacha.diamante),
  dias79(dias: 79, recompensa: 'Avatar exclusivo Diamante', titulo: 'Voluntad Inquebrantable', rango: RangoRacha.diamante),
  dias86(dias: 86, recompensa: 'Reporte de productividad exportable', titulo: 'Maestro de la Rutina', rango: RangoRacha.diamante),

  // RANGO 4: LEYENDA (91 a 100+ días)
  dias93(dias: 93, recompensa: 'Insignia Suprema + Efectos especiales', titulo: 'Cerca de la Gloria', rango: RangoRacha.leyenda),
  dias100(dias: 100, recompensa: 'Tema "Racha Dorada" + Insignia máxima', titulo: 'Centenario Legendario', rango: RangoRacha.leyenda);

  const HitoRacha({
    required this.dias,
    required this.recompensa,
    required this.titulo,
    required this.rango,
  });

  final int dias;
  final String recompensa;
  final String titulo;
  final RangoRacha rango;
}
```

### 8.3 Caso de uso — se dispara desde `AlternarCompletado`, no desde la UI

```dart
// features/racha/domain/usecases/actualizar_racha.dart
class ActualizarRacha {
  ActualizarRacha(this._repo, this._reloj);
  final RachaRepository _repo;
  final Reloj _reloj;

  Future<Result<Racha>> call() async {
    final hoy = _reloj.ahora();
    final actual = await _repo.obtener();
    // si ultimaFechaCompletado == ayer  → diasActuales + 1
    // si ultimaFechaCompletado == hoy   → sin cambios (ya contó hoy)
    // si ultimaFechaCompletado < ayer   → diasActuales = 1 (se rompió, empieza de nuevo)
    // actualizar mejorRacha si corresponde y revisar qué HitoRacha se desbloquea
  }
}
```

`AlternarCompletado` (Fase 4) llama a `ActualizarRacha` internamente cuando un pendiente pasa a completado. La UI nunca decide esta regla, igual que el resto del plan.

### 8.4 Ideas de recompensas (elige las que quieras — no hace falta implementarlas todas)

| Recompensa | Hito sugerido | Notas |
|---|---|---|
| Tema de color exclusivo | 7, 30 y 100 días | Ver Fase 10 |
| Asistente por voz | 15 días | Ver Fase 9 (ajustado a 15 días para mayor accesibilidad) |
| Comodín de racha (1 al mes) | 10 días | Perdona un día fallido sin reiniciar la racha |
| Icono alternativo de la app | 30 días | Requiere `flutter_launcher_icons` con variantes |
| Frase motivacional diaria | 7 días | Banco de frases + una aleatoria al abrir la app |
| Animación de celebración al completar | 3 días | Confetti o Lottie al marcar el primer pendiente del día |
| Estadísticas de productividad | 30 días | Gráfico semanal, reutiliza datos ya guardados |
| Compartir racha como imagen | 50 días | Tarjeta generada con el paquete `screenshot` para redes |
| Widget de escritorio con la racha | 100 días | Requiere `home_widget`, esfuerzo mayor |

### 8.5 UI: la racha al iniciar sesión
Al entrar a `home_shell_screen.dart` se muestra un banner breve (1.5–2s): `🔥 12 días de racha`, con una micro-animación simple. Si la racha se rompió desde la última sesión, el mensaje es motivador ("Empecemos de nuevo 💪"), no punitivo. Se agrega también una pantalla **"Mis Logros"** (Drawer o Ajustes) con los hitos, cuáles están desbloqueados y una barra de progreso hacia el siguiente.

### Criterio de completado ✅
- [x] Completar un pendiente incrementa la racha una sola vez por día
- [x] La racha se reinicia correctamente tras un día natural sin completar nada
- [x] Al iniciar sesión se muestra la racha actual
- [x] Los hitos de día 15 (voz), día 30 (Aurora) y día 100 (Dorado) quedan disponibles para que los usen las Fases 9 y 10

---

## 🟦 FASE 9: Chatbox — Asistente IA (texto y voz)
**Duración:** 5–7 horas. **Depende de:** Fase 8 (desbloqueo por racha).

### Objetivo
Un asistente conversacional que crea pendientes a partir de lenguaje natural: **texto siempre disponible**, **voz desbloqueada al llegar a 15 días de racha** (hito `dias15`).

### 9.1 Límite del chat
Para controlar costo y evitar abuso, define un límite de mensajes por día (por ejemplo **15 mensajes/día** — configurable). Se guarda por fecha y se muestra en la UI como "12/15 mensajes hoy" mediante `BarraLimiteChat`.

```dart
// features/asistente/domain/entities/limite_chat.dart
class LimiteChat {
  final int mensajesUsadosHoy;
  final int mensajesMaximosPorDia;
  final DateTime fecha;

  bool get puedeEnviar => mensajesUsadosHoy < mensajesMaximosPorDia;
  int get restantes => mensajesMaximosPorDia - mensajesUsadosHoy;
}
```

### 9.2 Flujo del asistente

```
USUARIO escribe o dicta "recuérdame llamar al dentista mañana a las 3pm"
    ↓
CHAT WIDGET envía el texto al UseCase InterpretarMensaje
    ↓
NlpIaDatasource analiza localmente el texto (expresiones regulares y heurística en español)
    ↓
Parsea { titulo, fecha, hora, prioridad, repetir } → valida sin costo de API ni conexión
    ↓
Llama a CrearPendiente (Fase 4, REUTILIZADO — no se duplica la lógica)
    ↓
El chat confirma: "Listo, agregué 'Llamar al dentista' para mañana 3:00 pm"
```

El asistente **no** guarda pendientes por su cuenta: siempre pasa por el mismo `CrearPendiente` que ya usa el resto de la app.

### 9.3 Entrada por voz — desbloqueo por racha (día 15)

```dart
// features/asistente/presentation/widgets/boton_microfono.dart
final racha = ref.watch(rachaNotifierProvider).valueOrNull;
final dias = racha?.diasActuales ?? 0;
final vozDesbloqueada = dias >= 15 ||
    (racha?.logrosDesbloqueados.contains(HitoRacha.dias15.name) ?? false);

InkWell(
  onTap: () {
    if (vozDesbloqueada) {
      _iniciarEscucha(context);
    } else {
      _mostrarDialogoBloqueo(context, dias);
    }
  },
  child: Icon(
    vozDesbloqueada ? Icons.mic_rounded : Icons.lock_outline_rounded,
  ),
)
```

Si no está desbloqueado, se muestra: *"Desbloquea el micrófono al llegar a 15 días de racha consecutiva 🔥 (llevas X)"*. La restricción se comunica como incentivo, no como error. El diálogo de dictado ofrece ejemplos rápidos y permite insertar el texto reconocido directamente en el flujo del asistente.

### Criterio de completado ✅
- [x] El chat crea pendientes reales vía `CrearPendiente`, sin lógica propia de persistencia
- [x] El contador de mensajes/día se respeta y se reinicia a medianoche
- [x] El micrófono queda bloqueado con candado hasta los 15 días de racha, con explicación clara
- [x] Un mensaje ambiguo no crashea el flujo: se le pide al usuario que aclare

---

## 🟦 FASE 10: Temas de color
**Duración:** 3–4 horas. **Depende de:** Fase 8 (temas desbloqueables por racha).

### Objetivo
Reemplazar el tema único fijo por un **selector de temas**: Claro/Oscuro (los actuales, sin cambios) más varios temas de color nuevos, algunos desbloqueables por racha.

```dart
// core/theme/tema_app.dart
class TemaApp {
  final String id;
  final String nombre;              // "Azul Clásico", "Esmeralda", "Lavanda", "Atardecer", "Aurora", "Racha Dorada"
  final String descripcion;
  final Color colorPrimario;
  final Color colorSecundario;
  final Color? colorAcento;
  final bool esDesbloqueablePorRacha;
  final int? diasRequeridos;

  const TemaApp({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.colorPrimario,
    required this.colorSecundario,
    this.colorAcento,
    this.esDesbloqueablePorRacha = false,
    this.diasRequeridos,
  });

  bool estaDesbloqueado(int diasRacha, List<String> logrosDesbloqueados) {
    if (!esDesbloqueablePorRacha) return true;
    if (diasRequeridos == null) return true;
    if (diasRacha >= diasRequeridos!) return true;
    return logrosDesbloqueados.contains('dias$diasRequeridos') ||
        logrosDesbloqueados.contains(id);
  }
}
```

El tema elegido se guarda en `ajustes_repository` (SharedPreferences), igual que el resto de preferencias del plan original. En `Ajustes → Temas` se muestra un grid de swatches; los bloqueados se ven con candado y el texto del hito ("Desbloquea a los 30 días 🔥") en vez de ocultarse.

### Criterio de completado ✅
- [x] Cambiar de tema no requiere reiniciar la app
- [x] Los temas bloqueados no se pueden seleccionar, solo previsualizar
- [x] El tema elegido persiste entre sesiones

---

## 🟦 FASE 11: Rediseño visual
**Duración:** 6–10 horas (la más abierta). **Esta es la única fase de todo el documento donde la app debe verse distinta al terminar.**

### Objetivo
Renovar la identidad visual ahora que el rediseño es intencional.

| Área | Sugerencia |
|---|---|
| Tipografía | Jerarquía más marcada (título / subtítulo / cuerpo) en `app_typography.dart` |
| `task_card.dart` | Sombra suave + borde de color según prioridad; `Hero` al abrir el detalle |
| Estados vacíos | Ilustración simple en vez de solo texto cuando "Hoy"/"Semana" no tienen pendientes |
| Transiciones | Animación al completar (Fase 8) y al cambiar de pestaña Hoy/Semana/Mes |
| Splash / inicio de sesión | Integrar el banner de racha (Fase 8) como parte de la apertura de la app |
| Modo oscuro | Revisar contraste de los temas nuevos (Fase 10) específicamente en oscuro |

> [!NOTE]
> Aquí sí conviene tomar capturas "antes/después" — no para evitar cambios, sino para documentar la evolución visual.

### Criterio de completado ✅
- [x] Las 8 pantallas originales conservan su función con la nueva identidad visual
- [x] Racha, chat y selector de temas se sienten parte de la misma app
- [x] Se probó en tema claro, oscuro y al menos un tema de color nuevo

---

# ═══════════════════════════════════════════════
# BLOQUE 4: DECISIONES, RIESGOS Y LO QUE NO HAY QUE HACER
# ═══════════════════════════════════════════════

## Resumen de recomendaciones sobre tus 5 preguntas del §8

| Tu pregunta | Recomendación | Fase |
|---|---|---|
| ¿Migrar a Feature-First? | **Sí**, pero híbrido: 3 features + `core` fuerte. No separes calendario de pendientes. | 5 |
| ¿Formalizar casos de uso? | **Sí, solo los 5 con regla real.** No crees uno por método del repo. | 4 |
| ¿Sealed classes o `AsyncValue`? | **`AsyncValue`** para estado de UI (ya lo tienes); **sealed classes propias** solo para `Result`/`Failure` en el dominio. | 1, 6 |
| ¿DI formal con Riverpod? | **Sí, prioritario.** Es lo que desbloquea todo lo demás. | 2 |
| ¿Tests con mocks? | **Sí, con `mocktail`** (no `mockito`) + SQLite en memoria. | 7 |

## Qué NO hacer

- ❌ **No introduzcas `freezed` ni `riverpod_generator` ahora.** Añaden `build_runner` a un proyecto con una sola entidad. El costo de mantenimiento supera al beneficio a esta escala. Si el proyecto crece a 5+ entidades, reconsidéralo.
- ❌ **No añadas `go_router`.** Tu navegación es un shell con BottomNav + pushes puntuales. Funciona. Cambiarla es riesgo puro sin beneficio.
- ❌ **No conviertas los datos semilla en "borrar la DB si falla".** Implementa `onUpgrade` de verdad.
- ❌ **No hagas dos fases en el mismo commit.** El valor de este plan está en poder revertir una fase sin perder las demás.
- ❌ **No toques ni un `SizedBox`.** Si al terminar una fase la app se ve distinta, revierte.

## Riesgos y mitigación

| Riesgo | Probabilidad | Mitigación |
|---|---|---|
| Romper las notificaciones al desingletonizar | Media | Fase 2 conserva íntegra la lógica interna; verifica con el botón "Probar notificación" y `adb shell dumpsys notification` como ya hiciste |
| Perder datos al migrar el esquema | Baja | `onUpgrade` con `ALTER TABLE`; probar instalando encima, no en emulador limpio |
| Imports rotos en masa en la Fase 5 | Media | Usar Refactor→Move del IDE; un commit por carpeta |
| Cambio visual accidental | Baja | Capturas baseline de la Fase 0 + comparación tras cada fase |
| El refactor no termina (falta de tiempo) | Media | Fases independientes: parar en la 2 o la 4 deja la app en estado sano y mejor que al inicio |

## Estimación total

| Fase | Duración | Prioridad |
|---|---|---|
| 0 — Red de seguridad | 0.5 h | 🔴 Obligatoria |
| 1 — Dominio puro | 2–3 h | 🔴 Alta |
| 2 — Inyección de dependencias | 2 h | 🔴 Alta |
| 3 — Repositorio + migraciones | 2–3 h | 🟠 Media-alta |
| 4 — Casos de uso | 3–4 h | 🟠 Media-alta |
| 5 — Feature-First | 1–2 h | 🟡 Media |
| 6 — AsyncValue | 3–4 h | 🟠 Media-alta |
| 7 — Tests | 3–4 h | 🟡 Media |
| **Subtotal refactor (0–7)** | **~17–23 h** | — |
| 8 — Racha y recompensas | 4–6 h | 🟢 Nueva funcionalidad |
| 9 — Chatbox / Asistente IA | 5–7 h | 🟢 Nueva funcionalidad |
| 10 — Temas de color | 3–4 h | 🟢 Nueva funcionalidad |
| 11 — Rediseño visual | 6–10 h | 🟢 Nueva funcionalidad |
| **Total con Bloque 3** | **~35–50 h** | — |

**Si solo tienes un fin de semana:** Fases 0 → 1 → 2 → 4. Son las que arreglan problemas reales del refactor. La 5 (mudanza de carpetas) es la más vistosa y la menos importante.

**Si quieres priorizar lo visible para el usuario antes que el refactor interno:** puedes hacer 0 → 8 → 10 → 9, dejando el resto del refactor (1, 2, 3, 5, 6, 7) para después. La Fase 4 (casos de uso) sí conviene adelantarla porque la Fase 8 y 9 la reutilizan (`CrearPendiente`, `AlternarCompletado`).

## Tracker de progreso

| Fase | Estado | Fecha | Notas |
|---|:---:|:---:|---|
| 0 — Red de seguridad | ✅ Completado | Sept 2026 | Smoke tests de pantallas y baseline asegurada (`smoke_screens_test.dart`) |
| 1 — Dominio puro | ✅ Completado | Sept 2026 | `HoraDelDia`, `Prioridad` sin Color, `Repeticion`, `Result<T>` y `Failure` puros |
| 2 — Inyección de dependencias | ✅ Completado | Sept 2026 | `ProviderScope` con overrides en `main.dart`, sin singletons estáticos |
| 3 — Repositorio + migraciones | ✅ Completado | Sept 2026 | `onUpgrade` SQLite, columna `notificacion_id`, índices y datos semilla externos |
| 4 — Casos de uso | ✅ Completado | Sept 2026 | 5 casos de uso con regla de negocio real implementados y desacoplados |
| 5 — Feature-First | ✅ Completado | Sept 2026 | Arquitectura híbrida por features (`pendientes`, `completados`, `ajustes`) |
| 6 — AsyncValue | ✅ Completado | Sept 2026 | `AsyncNotifier`, providers derivados por fecha y manejo con `_EstadoError` |
| 7 — Tests con dobles de prueba | ✅ Completado | Sept 2026 | Mocks con `mocktail` y SQLite FFI en memoria (83 tests automáticos verdes) |
| 8 — Racha y recompensas | ✅ Completado | Sept 2026 | 4 ligas `RangoRacha`, 16 hitos escalonados y pantalla Mis Logros |
| 9 — Chatbox / Asistente IA | ✅ Completado | Sept 2026 | Procesador local NLP en español, límite de mensajes y voz a los 15 días |
| 10 — Temas de color | ✅ Completado | Sept 2026 | 6 esquemas de color con `TemaApp`, soporte claro/oscuro y desbloqueables |
| 11 — Rediseño visual | ✅ Completado | Sept 2026 | Splash dinámico con racha, cards pulidas, feedback háptico/visual y estados vacíos |

**Leyenda:** ⚪ Pendiente | 🟡 En proceso | ✅ Completado | 🔴 Bloqueado

---

> [!IMPORTANT]
> **RECORDATORIO FINAL**:
> - Para las **Fases 0–7**, pega **todo el Bloque 1** antes del prompt de la fase. Sin ese contexto la IA no conoce la estructura objetivo, las convenciones de nombres en español ni la regla de que el diseño no se toca — y terminará rediseñándote la app cuando no debía.
> - Para las **Fases 8–11 (Bloque 3)**, pega el Bloque 1 **más** la advertencia de la cabecera del Bloque 3: ahí la IA sí debe tocar diseño y crear pantallas nuevas. Si no le aclaras esto, es probable que se niegue a rediseñar por seguir la regla de oro original.
