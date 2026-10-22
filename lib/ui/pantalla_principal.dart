import 'package:flutter/material.dart';
import '../model/incidencia.dart';
import '../services/gestor_incidencias.dart';
import 'pantalla_detalle.dart';
import 'pantalla_nueva.dart';
import '../model/estado.dart';
import '../model/prioridades.dart';
import '../services/estado_chip.dart';
import '../services/prioridad_chip.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  String estadoSeleccionado = 'Todos';
  String prioridadSeleccionada = 'Todos';

  final GestorIncidencias g = GestorIncidencias();
  bool cargando = true;
  String? error;
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    cargar();
  }
   

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      await g.iniciar();
    } catch (e) {
      error = 'No se pudieron cargar las incidencias: $e';
    }
    if (mounted) setState(() => cargando = false);
  }

  Color colorEstado(String estado) {
    if (estado == 'Resuelta') return const Color(0xFF147D64);
    if (estado == 'En proceso') return const Color(0xFFB56B13);
    return const Color(0xFFAC4052);
  }

  Widget resumen(String etiqueta, String valor, IconData icono) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icono, size: 19, color: const Color(0xFF174C83)),
              const SizedBox(height: 4),
              Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(etiqueta, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> abrirDetalle(Incidencia item) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => PantallaDetalle(gestor: g, id: item.id)),
    );
    if (mounted) setState(() {});
  }

  Future<void> abrirFormulario() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PantallaNueva(gestor: g)),
    );
    if (guardado == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incidencia registrada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
   



    final items = g.buscar(busqueda);

    final itemsMostrados = items.where((item){
      if(estadoSeleccionado == 'Todos' && prioridadSeleccionada == 'Todos'){
        return true;
      } else if(estadoSeleccionado == 'Todos'){
        return item.prioridad == prioridadSeleccionada;
      } else if(prioridadSeleccionada == 'Todos'){
        return item.estado == estadoSeleccionado;
      } else {
        return item.estado == estadoSeleccionado && item.prioridad == prioridadSeleccionada;  
      }
    }).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('NexaSoft | Incidencias'),
        actions: [
          IconButton(
            tooltip: 'Restablecer datos de demostración',
            onPressed: () async {
              final aceptar = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Restablecer demostración'),
                  content: const Text('Se descartarán los cambios locales y se cargarán las incidencias iniciales.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restablecer')),
                  ],
                ),
              );
              if (aceptar != true) return;
              try {
                await g.reiniciarDemo();
                if (mounted) setState(() {});
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al reiniciar: $e')));
                }
              }
            },
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      floatingActionButton: cargando || error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: abrirFormulario,
              label: const Text('Nueva incidencia'),
              icon: const Icon(Icons.add),
            ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: cargar, child: const Text('Reintentar')),
                  ]),
                ))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                          child: Row(children: [
                            resumen('Pendientes', '${g.contar('Pendiente')}', Icons.pending_actions),
                            resumen('En proceso', '${g.contar('En proceso')}', Icons.build_outlined),
                            resumen('Resueltas', '${g.contar('Resuelta')}', Icons.check_circle_outline),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Buscar incidencias',
                              hintText: 'Ejemplo: WiFi, correo, pantalla',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (texto) => setState(() => busqueda = texto),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text('Filtrar por Estado', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
                        const SizedBox(height: 8),                   
                        Center(
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0, 
                            alignment: WrapAlignment.center,
                            children: estados.map((estado) {
                              return EstadoChip(
                                texto: estado,
                                seleccionado: estadoSeleccionado == estado,
                                onTap: () {
                                  setState(() {
                                    estadoSeleccionado = estado;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Text('Filtrar por Prioridad', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
                        const SizedBox(height: 8),                   
                        Center(
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0, 
                            alignment: WrapAlignment.center,
                            children: prioridades.map((prioridad) {
                              return PrioridadChip(
                                texto: prioridad,
                                seleccionado: prioridadSeleccionada == prioridad,
                                onTap: () {
                                  setState(() {
                                    prioridadSeleccionada = prioridad;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        //Vamos a poner un boton para limpiar los filtros y mostrar todos los elementos
                        TextButton(
                          onPressed: () {
                            setState(() {
                              estadoSeleccionado = 'Todos';
                              prioridadSeleccionada = 'Todos';
                            });
                          },
                          child: const Text('Limpiar filtros'),
                        ),
                        const SizedBox(height: 8),


                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('${itemsMostrados.length} registros', style: const TextStyle(color: Colors.black54)),
                          ),
                        ),
                        Expanded(
                          child: itemsMostrados.isEmpty
                              ? const Center(child: Text('No se encontraron incidencias'))
                              : ListView.builder(
                                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 100),
                                  itemCount: itemsMostrados.length,
                                  itemBuilder: (context, i) {
                                    final item = itemsMostrados[i];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        title: Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${item.id}  ·  ${item.cliente}'),
                                              const SizedBox(height: 6),
                                              Text('Prioridad: ${item.prioridad}', style: const TextStyle(fontSize: 13)), 
                                              const SizedBox(height: 6),
                                              Text(item.estado, style: TextStyle(
                                                color: colorEstado(item.estado), fontWeight: FontWeight.bold,
                                              )),
                                            ],
                                          ),
                                        ),
                                        trailing: const Icon(Icons.chevron_right),
                                        onTap: () => abrirDetalle(item),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
