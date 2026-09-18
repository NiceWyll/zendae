import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../services/reloj.dart';

final relojProvider = Provider<Reloj>((ref) => const RelojDelSistema());
final uuidProvider = Provider<String Function()>((ref) => () => const Uuid().v4());
