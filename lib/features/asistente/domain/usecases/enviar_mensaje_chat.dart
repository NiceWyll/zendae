import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/services/reloj.dart';
import 'package:mi_pendiente/features/horario/domain/entities/clase.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/domain/usecases/actualizar_pendiente.dart';
import 'package:mi_pendiente/features/pendientes/domain/usecases/crear_pendiente.dart';
import 'package:mi_pendiente/features/pendientes/domain/usecases/eliminar_pendiente.dart';
import '../../data/datasources/ia_datasource.dart';
import '../entities/mensaje_chat.dart';
import '../repositories/asistente_repository.dart';
import 'interpretar_mensaje.dart';

class EnviarMensajeChat {
  final AsistenteRepository _repo;
  final InterpretarMensaje _interpretar;
  final CrearPendiente _crearPendiente;
  final ActualizarPendiente? _actualizarPendiente;
  final EliminarPendiente? _eliminarPendiente;
  final Reloj _reloj;
  final String Function() _generarUuid;

  const EnviarMensajeChat({
    required AsistenteRepository repo,
    required InterpretarMensaje interpretar,
    required CrearPendiente crearPendiente,
    ActualizarPendiente? actualizarPendiente,
    EliminarPendiente? eliminarPendiente,
    required Reloj reloj,
    required String Function() generarUuid,
  })  : _repo = repo,
        _interpretar = interpretar,
        _crearPendiente = crearPendiente,
        _actualizarPendiente = actualizarPendiente,
        _eliminarPendiente = eliminarPendiente,
        _reloj = reloj,
        _generarUuid = generarUuid;

  Future<Result<MensajeChat>> call(
    String texto, {
    List<Pendiente> pendientesExistentes = const [],
    List<Clase> clasesExistentes = const [],
    List<Pendiente>? candidatosPendientesEliminacion,
    void Function(List<Pendiente>?)? onCandidatosActualizados,
  }) async {
    final ahora = _reloj.ahora();

    // 1. Guardar mensaje del usuario
    final mensajeUsuario = MensajeChat(
      id: _generarUuid(),
      texto: texto,
      esUsuario: true,
      fecha: ahora,
    );
    await _repo.guardarMensaje(mensajeUsuario);

    // 2. Validar límite diario
    final limiteRes = await _repo.obtenerLimite();
    if (limiteRes case Exito(:final valor)) {
      if (!valor.puedeEnviar) {
        final mensajeLimite = MensajeChat(
          id: _generarUuid(),
          texto: 'Has alcanzado el límite diario de ${valor.mensajesMaximosPorDia} mensajes del asistente. Tu cupo se renovará automáticamente mañana a medianoche ✨.',
          esUsuario: false,
          fecha: ahora,
          esError: true,
        );
        await _repo.guardarMensaje(mensajeLimite);
        return Exito(mensajeLimite);
      }
    }

    // 3. Registrar consumo de cuota
    await _repo.registrarMensajeEnviado();

    // 4. Interpretar mensaje del usuario con contexto de pendientes y clases
    final resInterpretacion = await _interpretar(
      texto,
      pendientesExistentes: pendientesExistentes,
      clasesExistentes: clasesExistentes,
      candidatosPendientesEliminacion: candidatosPendientesEliminacion,
    );
    final interpretacion = switch (resInterpretacion) {
      Exito(:final valor) => valor,
      Fallo() => const ResultadoInterpretacion(
          respuestaTexto: 'No pude procesar tu mensaje en este momento.',
          esConversacional: true,
        ),
    };

    // Caso A: Edición de un pendiente existente (Requisito 5)
    if (interpretacion.tipoAccion == TipoAccionIa.editar && interpretacion.pendienteModificado != null) {
      if (_actualizarPendiente != null) {
        await _actualizarPendiente(interpretacion.pendienteModificado!);
      }
      onCandidatosActualizados?.call(null);
      final mensajeRespuesta = MensajeChat(
        id: _generarUuid(),
        texto: interpretacion.respuestaTexto,
        esUsuario: false,
        fecha: ahora,
        pendienteCreadoId: interpretacion.pendienteModificado!.id,
        tituloPendienteCreado: interpretacion.pendienteModificado!.titulo,
        debeLeerEnVozAlta: interpretacion.debeLeerEnVozAlta,
      );
      await _repo.guardarMensaje(mensajeRespuesta);
      return Exito(mensajeRespuesta);
    }

    // Caso B: Borrado directo de un pendiente (Requisito 5)
    if (interpretacion.tipoAccion == TipoAccionIa.eliminar && interpretacion.pendienteAEliminarId != null) {
      if (_eliminarPendiente != null) {
        await _eliminarPendiente(interpretacion.pendienteAEliminarId!);
      }
      onCandidatosActualizados?.call(null);
      final mensajeRespuesta = MensajeChat(
        id: _generarUuid(),
        texto: interpretacion.respuestaTexto,
        esUsuario: false,
        fecha: ahora,
        debeLeerEnVozAlta: interpretacion.debeLeerEnVozAlta,
      );
      await _repo.guardarMensaje(mensajeRespuesta);
      return Exito(mensajeRespuesta);
    }

    // Caso C: Desambiguación requerida para borrado (>1 coincidencias)
    if (interpretacion.candidatosEliminacion != null) {
      onCandidatosActualizados?.call(interpretacion.candidatosEliminacion);
      final mensajeRespuesta = MensajeChat(
        id: _generarUuid(),
        texto: interpretacion.respuestaTexto,
        esUsuario: false,
        fecha: ahora,
        debeLeerEnVozAlta: interpretacion.debeLeerEnVozAlta,
      );
      await _repo.guardarMensaje(mensajeRespuesta);
      return Exito(mensajeRespuesta);
    }

    // Caso D: Creación de nueva tarea (Flujo normal)
    if (interpretacion.tipoAccion == TipoAccionIa.crear && interpretacion.pendiente != null) {
      onCandidatosActualizados?.call(null);
      final p = interpretacion.pendiente!;
      final nuevoPendiente = Pendiente(
        id: '', // CrearPendiente asignará el UUID
        titulo: p.titulo,
        descripcion: p.descripcion,
        fecha: p.fecha,
        hora: p.hora,
        prioridad: p.prioridad,
        tieneRecordatorio: p.tieneRecordatorio,
        minutosAntes: p.minutosAntes,
        repetir: p.repetir,
        estaCompletado: false,
      );

      final creacionRes = await _crearPendiente(nuevoPendiente);

      switch (creacionRes) {
        case Exito(:final valor):
          final mensajeRespuesta = MensajeChat(
            id: _generarUuid(),
            texto: interpretacion.respuestaTexto,
            esUsuario: false,
            fecha: ahora,
            pendienteCreadoId: valor.id,
            tituloPendienteCreado: valor.titulo,
            debeLeerEnVozAlta: interpretacion.debeLeerEnVozAlta,
          );
          await _repo.guardarMensaje(mensajeRespuesta);
          return Exito(mensajeRespuesta);

        case Fallo(:final failure):
          final mensajeFallo = MensajeChat(
            id: _generarUuid(),
            texto: 'No pude registrar el pendiente: ${failure.mensaje}',
            esUsuario: false,
            fecha: ahora,
            esError: true,
          );
          await _repo.guardarMensaje(mensajeFallo);
          return Exito(mensajeFallo);
      }
    }

    // Caso E: Resumen de lo que tengo (Requisito 6) o conversacional
    onCandidatosActualizados?.call(null);
    final mensajeAsistente = MensajeChat(
      id: _generarUuid(),
      texto: interpretacion.respuestaTexto,
      esUsuario: false,
      fecha: ahora,
      debeLeerEnVozAlta: interpretacion.debeLeerEnVozAlta,
    );
    await _repo.guardarMensaje(mensajeAsistente);
    return Exito(mensajeAsistente);
  }
}
