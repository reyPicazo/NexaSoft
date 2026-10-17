import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/incidencia.dart';

class AlmacenLocal {
  final prefs = SharedPreferencesAsync();
  final clave = 'nexasoft_incidencias_v1';

  Future<List<Incidencia>> leer() async {
    final guardadas = await prefs.getString(clave);
    
    if (guardadas != null) {
      final lista = jsonDecode(guardadas) as List<dynamic>;
      return lista
          .map((item) => Incidencia.desdeJson(item as Map<String, dynamic>))
          .toList();
    } else {
      final texto = await rootBundle.loadString('assets/data/incidencias.json');
      final lista = jsonDecode(texto) as List<dynamic>;
      final incidenciasInicio = lista
          .map((item) => Incidencia.desdeJson(item as Map<String, dynamic>))
          .toList();
          
      await guardar(incidenciasInicio);
      
      return incidenciasInicio;
    }
  }

  Future<void> guardar(List<Incidencia> lista) async {
    final datos = lista.map((x) => x.toJson()).toList();
    await prefs.setString(clave, jsonEncode(datos));
  }

  Future<void> restaurarDatosDeEjemplo() async {
    await prefs.remove(clave);
  }
}
