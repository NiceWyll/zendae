import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_pendiente/features/pendientes/data/datasources/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider debe sobreescribirse en main()');
});
