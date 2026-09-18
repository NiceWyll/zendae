import 'package:mi_pendiente/core/error/result.dart';
import 'package:mi_pendiente/core/services/reloj.dart';
import 'package:mi_pendiente/features/pendientes/domain/entities/pendiente.dart';
import 'package:mi_pendiente/features/pendientes/domain/usecases/crear_pendiente.dart';
import '../../data/datasources/ia_datasource.dart';
import '../entities/mensaje_chat.dart';
import '../repositories/asistente_repository.dart';
import 'interpretar_mensaje.dart';

class EnviarMensajeChat {
  final AsistenteRepository _repo;
  final InterpretarMensaje _interpretar;
  final CrearPendiente _crearPendiente;
  final Reloj _reloj;
  final String Function() _generarUuid;

  const EnviarMensajeChat({
    required AsistenteRepository repo,
    required InterpretarMensaje interpretar,
    required CrearPendiente crearPendiente,
    required Reloj reloj,
    required String Function() generarUuid,
  })  : _repo = repo,
        _interpretar = interpretar,
        _crearPendiente = crearPendiente,
        _reloj = reloj,
        _generarUuid = generarUuid;

  Future<Result<MensajeChat>> call(String texto) async {
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

    // 4. Interpretar mensaje del usuario
    final resInterpretacion = await _interpretar(texto);
    final interpretacion = switch (resInterpretacion) {
      Exito(:final valor) => valor,
      Fallo() => const ResultadoInterpretacion(
          respuestaTexto: 'No pude procesar tu mensaje en este momento.',
          esConversacional: true,
        ),
    };

    // 5. Si extrajo una tarea, crearla usando CrearPendiente
    if (interpretacion.pendiente != null) {
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

    // 6. Mensaje conversacional o aclaración
    final mensajeAsistente = MensajeChat(
      id: _generarUuid(),
      texto: interpretacion.respuestaTexto,
      esUsuario: false,
      fecha: ahora,
    );
    await _repo.guardarMensaje(mensajeAsistente);
    return Exito(mensajeAsistente);
  }
}
