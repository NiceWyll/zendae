import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum Prioridad {
  alta,
  media,
  baja;

  String get label {
    switch (this) {
      case Prioridad.alta:
        return 'Alta';
      case Prioridad.media:
        return 'Media';
      case Prioridad.baja:
        return 'Baja';
    }
  }

  Color get color {
    switch (this) {
      case Prioridad.alta:
        return AppColors.priorityAlta;
      case Prioridad.media:
        return AppColors.priorityMedia;
      case Prioridad.baja:
        return AppColors.priorityBaja;
    }
  }

  Color get bgColor {
    switch (this) {
      case Prioridad.alta:
        return AppColors.priorityAltaBg;
      case Prioridad.media:
        return AppColors.priorityMediaBg;
      case Prioridad.baja:
        return AppColors.priorityBajaBg;
    }
  }

  static Prioridad fromString(String value) {
    return Prioridad.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => Prioridad.media,
    );
  }
}
