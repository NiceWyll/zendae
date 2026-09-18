import 'failure.dart';

sealed class Result<T> {
  const Result();

  bool get esExito => this is Exito<T>;
  bool get esFallo => this is Fallo<T>;

  T? get valorO => switch (this) {
        Exito(:final valor) => valor,
        Fallo() => null,
      };

  Failure? get failureO => switch (this) {
        Exito() => null,
        Fallo(:final failure) => failure,
      };

  T datosO(T fallback) => switch (this) {
        Exito(:final valor) => valor,
        Fallo() => fallback,
      };

  Failure? errorO(Failure? fallback) => switch (this) {
        Exito() => fallback,
        Fallo(:final failure) => failure,
      };
}

class Exito<T> extends Result<T> {
  const Exito(this.valor);
  final T valor;
  T get datos => valor;
}

class Fallo<T> extends Result<T> {
  const Fallo(this.failure);
  final Failure failure;
  Failure get error => failure;
}
