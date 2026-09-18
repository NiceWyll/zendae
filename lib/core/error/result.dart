import 'failure.dart';

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
