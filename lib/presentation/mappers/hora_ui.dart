import 'package:flutter/material.dart';
import '../../domain/entities/hora_del_dia.dart';

extension HoraDelDiaUI on HoraDelDia {
  TimeOfDay get comoTimeOfDay => TimeOfDay(hour: hora, minute: minuto);
}

extension TimeOfDayDominio on TimeOfDay {
  HoraDelDia get comoHoraDelDia => HoraDelDia(hora: hour, minuto: minute);
}
