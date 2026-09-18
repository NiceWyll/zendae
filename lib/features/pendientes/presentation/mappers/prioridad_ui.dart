import 'package:flutter/material.dart';
import 'package:mi_pendiente/core/constants/app_colors.dart';
import '../../domain/entities/prioridad.dart';

extension PrioridadUI on Prioridad {
  String get label => switch (this) {
        Prioridad.alta => 'Alta',
        Prioridad.media => 'Media',
        Prioridad.baja => 'Baja',
      };

  Color get color => switch (this) {
        Prioridad.alta => AppColors.priorityAlta,
        Prioridad.media => AppColors.priorityMedia,
        Prioridad.baja => AppColors.priorityBaja,
      };

  Color get bgColor => switch (this) {
        Prioridad.alta => AppColors.priorityAltaBg,
        Prioridad.media => AppColors.priorityMediaBg,
        Prioridad.baja => AppColors.priorityBajaBg,
      };
}
