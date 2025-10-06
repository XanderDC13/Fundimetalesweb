import 'package:basefundi/services/importcatalogo_desk.dart';
import 'package:basefundi/services/transition.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/services/navbar_desk.dart';

class VisualizarCatalogoScreen extends StatefulWidget {
  const VisualizarCatalogoScreen({super.key});

  @override
  State<VisualizarCatalogoScreen> createState() =>
      _VisualizarCatalogoScreenState();
}

class _VisualizarCatalogoScreenState extends State<VisualizarCatalogoScreen> {
  String categoriaSeleccionada = 'Discos';
  String terminoBusqueda = '';
  final TextEditingController _controladorBusqueda = TextEditingController();

  // Lista de todas las categorías disponibles
  final List<String> categorias = [
    'Discos',
    'Tambores',
    'Bocines',
    'Arañas',
    'Alcantarillado',
    'Sumideros',
    'Rejillas',
    'Accesorios',
    'Cocinas',
    'Gimnasio',
    'Agrícolas',
    'Sistemas Adaptación Frenos',
    'Soporteria',
  ];

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  // Stream para obtener productos de la categoría seleccionada
  Stream<QuerySnapshot> _obtenerProductos() {
    return FirebaseFirestore.instance
        .collection('catalogo')
        .doc(categoriaSeleccionada)
        .collection('productos')
        .snapshots();
  }

  // Filtrar productos por término de búsqueda
  List<DocumentSnapshot> _filtrarProductos(List<DocumentSnapshot> productos) {
    if (terminoBusqueda.isEmpty) return productos;

    return productos.where((producto) {
      final data = producto.data() as Map<String, dynamic>;
      final referencia = data['referencia']?.toString().toLowerCase() ?? '';
      final nombre = data['nombre']?.toString().toLowerCase() ?? '';
      final termino = terminoBusqueda.toLowerCase();

      return referencia.contains(termino) || nombre.contains(termino);
    }).toList();
  }

  // Obtener columnas específicas según la categoría
  List<String> _obtenerColumnas() {
    switch (categoriaSeleccionada) {
      case 'Discos':
        return [
          'Referencia',
          'Nombre',
          'Diámetro',
          'Altura T',
          'Bocín',
          'Espesor',
          'Huecos',
          'S/V',
          'PVP',
          '20%',
          'Peso',
          'Acciones',
        ];
      case 'Tambores':
        return [
          'Referencia',
          'Nombre',
          'Diámetro',
          'Hueco',
          'Banda',
          'Bocín',
          'POC',
          'Observaciones',
          'PVP',
          '20%',
          'Peso',
          'Acciones',
        ];
      case 'Soporteria':
        return [
          'Referencia',
          'Nombre',
          'Dimensiones',
          'Peso',
          'PVP',
          'Acciones',
        ];
      case 'Rejillas':
        return [
          'Referencia',
          'Nombre',
          'Dimensiones',
          'PVP',
          'Desc',
          'Acciones',
        ];
      case 'Accesorios':
        return [
          'Referencia',
          'Nombre',
          'Dimensiones',
          'Peso',
          'PVP',
          'Acciones',
        ];
      case 'Sumideros':
        return [
          'Referencia',
          'Nombre',
          'Dimensiones',
          'Tapa',
          'Cerco',
          'PVP',
          'Desc',
          'Acciones',
        ];
      default:
        return ['Referencia', 'Nombre', 'Descripción', 'PVP', 'Acciones'];
    }
  }

  // Obtener valor de celda según la categoría y campo
  String _obtenerValorCelda(Map<String, dynamic> data, String columna) {
    switch (categoriaSeleccionada) {
      case 'Discos':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Diámetro':
            return data['diametro']?.toString() ?? '';
          case 'Altura T':
            return data['alturaTotal']?.toString() ?? '';
          case 'Bocín':
            return data['bocin']?.toString() ?? '';
          case 'Espesor':
            return data['espesor']?.toString() ?? '';
          case 'Huecos':
            return data['huecos']?.toString() ?? '';
          case 'S/V':
            return data['tipo']?.toString() ?? '';
          case 'PVP':
            return '\$${data['pvp']?.toString() ?? '0.00'}';
          case '20%':
            return '\$${data['descuento20']?.toString() ?? '0.00'}';
          case 'Peso':
            return '${data['peso']?.toString() ?? '0.00'} kg';
          default:
            return '';
        }
      case 'Tambores':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Diámetro':
            return data['diametro']?.toString() ?? '';
          case 'Hueco':
            return data['hueco']?.toString() ?? '';
          case 'Banda':
            return data['banda']?.toString() ?? '';
          case 'Bocín':
            return data['bocin']?.toString() ?? '';
          case 'POC':
            return data['poc']?.toString() ?? '';
          case 'Observaciones':
            return data['observaciones']?.toString() ?? '';
          case 'PVP':
            return '\$${data['pvp']?.toString() ?? '0.00'}';
          case '20%':
            return '\$${data['descuento20']?.toString() ?? '0.00'}';
          case 'Peso':
            return '${data['peso']?.toString() ?? '0.00'} kg';
          default:
            return '';
        }
      case 'Soporteria':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Dimensiones':
            return data['dimensiones']?.toString() ?? '';
          case 'Peso':
            return '${data['peso']?.toString() ?? '0.00'} kg';
          case 'PVP':
            return "\$${data['pvp']?.toString() ?? '0.00'}";
          default:
            return '';
        }
      case 'Rejillas':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Dimensiones':
            return data['dimensiones']?.toString() ?? '';
          case 'PVP':
            return "\$${data['pvp']?.toString() ?? '0.00'}";
          case 'Desc':
            return "\$${data['descuento']?.toString() ?? '0.00'}";
          default:
            return '';
        }
      case 'Accesorios':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Dimensiones':
            return data['dimensiones']?.toString() ?? '';
          case 'Peso':
            return '${data['peso']?.toString() ?? '0.00'} kg';
          case 'PVP':
            return "\$${data['pvp']?.toString() ?? '0.00'}";

          default:
            return '';
        }
      case 'Sumideros':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Dimensiones':
            return data['dimensiones']?.toString() ?? '';
          case 'Tapa':
            return data['tapa']?.toString() ?? '';
          case 'Cerco':
            return data['cerco']?.toString() ?? '';
          case 'PVP':
            return "\$${data['pvp']?.toString() ?? '0.00'}";
          case 'Desc':
            return "\$${data['descuento']?.toString() ?? '0.00'}";
          default:
            return '';
        }
      default:
        return data[columna.toLowerCase()]?.toString() ?? 'N/A';
    }
  }

  // Obtener icono según la categoría
  IconData _obtenerIconoCategoria() {
    switch (categoriaSeleccionada) {
      case 'Discos':
        return Icons.album;
      case 'Tambores':
        return Icons.radio_button_unchecked;
      case 'Bocines':
        return Icons.speaker;
      case 'Arañas':
        return Icons.settings;
      case 'Alcantarillado':
        return Icons.water_damage;
      case 'Sumideros Rejillas':
        return Icons.grid_on;
      case 'Rejillas':
        return Icons.view_module;
      case 'Cocinas':
        return Icons.kitchen;
      case 'Gimnasio':
        return Icons.fitness_center;
      case 'Agrícolas':
        return Icons.agriculture;
      case 'Sistemas Adaptación Frenos':
        return Icons.build;
      case 'Soportería':
        return Icons.construction;
      default:
        return Icons.category;
    }
  }

  // Función para mostrar el diálogo de eliminar producto
  void _mostrarDialogoEliminar(String productoId, String nombreProducto) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder:
          (context) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 12,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Eliminar producto',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¿Seguro que deseas eliminar "$nombreProducto"?',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Eliminar',
                              style: TextStyle(
                                color: const Color(0xFFFFFFFF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );

    if (confirmacion == true) {
      try {
        await FirebaseFirestore.instance
            .collection('catalogo')
            .doc(categoriaSeleccionada)
            .collection('productos')
            .doc(productoId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto "$nombreProducto" eliminado exitosamente'),
            backgroundColor: const Color(0xFF2C3E50),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar el producto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Función para mostrar el diálogo de editar producto
  void _mostrarDialogoEditarProducto(
    String productoId,
    Map<String, dynamic> datosActuales,
  ) {
    final columnas = _obtenerColumnas();
    final Map<String, TextEditingController> controladores = {};

    // Crear controladores para cada campo con los valores actuales
    for (String columna in columnas) {
      if (columna != 'Acciones') {
        // ✅ SOLO EXCLUIR ACCIONES
        controladores[columna] = TextEditingController();

        // Llenar con datos actuales
        String valorActual = _obtenerValorParaEdicion(datosActuales, columna);
        controladores[columna]!.text = valorActual;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header del diálogo
                Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: const Color(0xFF4682B4),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Editar Producto - $categoriaSeleccionada',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Formulario
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Campos del formulario
                        ...columnas
                            .where(
                              (columna) =>
                                  columna != 'Acciones',
                            )
                            .map((columna) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: TextFormField(
                                  controller: controladores[columna],
                                  decoration: InputDecoration(
                                    labelText: columna,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: const Color(0xFF4682B4),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  keyboardType:
                                      _esNumerico(columna)
                                          ? TextInputType.number
                                          : TextInputType.text,
                                ),
                              );
                            })
                            .toList(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed:
                          () => _actualizarProducto(productoId, controladores),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4682B4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Actualizar Producto'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Función para obtener valor para edición
  // Función para obtener valor para edición
  String _obtenerValorParaEdicion(Map<String, dynamic> data, String columna) {
    switch (categoriaSeleccionada) {
      case 'Discos':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Diámetro':
            return data['diametro']?.toString() ?? '';
          case 'Altura T':
            return data['alturaTotal']?.toString() ?? '';
          case 'Bocín':
            return data['bocin']?.toString() ?? '';
          case 'Espesor':
            return data['espesor']?.toString() ?? '';
          case 'Huecos':
            return data['huecos']?.toString() ?? '';
          case 'S/V':
            return data['tipo']?.toString() ?? '';
          case 'PVP': // AGREGAR ESTE CASO
            return data['pvp']?.toString() ?? '';
          case '20%':
            return data['descuento20']?.toString() ?? '';
          case 'Peso':
            return data['peso']?.toString() ?? '';
          default:
            return '';
        }
      case 'Tambores':
        switch (columna) {
          case 'Referencia':
            return data['referencia']?.toString() ?? '';
          case 'Nombre':
            return data['nombre']?.toString() ?? '';
          case 'Diámetro':
            return data['diametro']?.toString() ?? '';
          case 'Hueco':
            return data['hueco']?.toString() ?? '';
          case 'Banda':
            return data['banda']?.toString() ?? '';
          case 'Bocín':
            return data['bocin']?.toString() ?? '';
          case 'POC':
            return data['poc']?.toString() ?? '';
          case 'Observaciones':
            return data['observaciones']?.toString() ?? '';
          case 'PVP': // AGREGAR ESTE CASO
            return data['pvp']?.toString() ?? '';
          case '20%':
            return data['descuento20']?.toString() ?? '';
          case 'Peso':
            return data['peso']?.toString() ?? '';
          default:
            return '';
        }
      // AGREGAR CASOS PARA LAS OTRAS CATEGORÍAS
      case 'Soporteria':
      case 'Rejillas':
      case 'Accesorios':
      case 'Sumideros':
        if (columna == 'PVP') {
          return data['pvp']?.toString() ?? '';
        }
        if (columna == 'Desc') {
          return data['descuento']?.toString() ?? '';
        }
        return data[_convertirColumnaNombreCampo(columna)]?.toString() ?? '';
      default:
        return data[_convertirColumnaNombreCampo(columna)]?.toString() ?? '';
    }
  }

  // Función para actualizar producto
  void _actualizarProducto(
    String productoId,
    Map<String, TextEditingController> controladores,
  ) async {
    try {
      Map<String, dynamic> datosProducto = {};

      // Convertir los datos según la categoría
      for (String columna in controladores.keys) {
        String valor = controladores[columna]!.text.trim();
        if (valor.isNotEmpty) {
          datosProducto[_convertirColumnaNombreCampo(columna)] = valor;
        }
      }

      // Calcular descuento 20% si hay PVP
      if (datosProducto.containsKey('pvp')) {
        double pvp = double.tryParse(datosProducto['pvp'].toString()) ?? 0.0;
        datosProducto['descuento20'] = (pvp * 0.8).toStringAsFixed(2);
      }

      // Actualizar en Firestore
      await FirebaseFirestore.instance
          .collection('catalogo')
          .doc(categoriaSeleccionada)
          .collection('productos')
          .doc(productoId)
          .update(datosProducto);

      Navigator.of(context).pop();

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto actualizado exitosamente'),
          backgroundColor: const Color(0xFF2C3E50),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el producto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Función para mostrar el diálogo de agregar producto
  void _mostrarDialogoAgregarProducto() {
    final columnas = _obtenerColumnas();
    final Map<String, TextEditingController> controladores = {};

    // Crear controladores para cada campo
    for (String columna in columnas) {
      if (columna != 'PVP' && columna != 'Desc. 20%' && columna != 'Acciones') {
        controladores[columna] = TextEditingController();
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header del diálogo
                Row(
                  children: [
                    Icon(
                      _obtenerIconoCategoria(),
                      color: const Color(0xFF2C3E50),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Agregar Producto - $categoriaSeleccionada',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Formulario
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Campos del formulario
                        ...columnas
                            .where(
                              (columna) =>
                                  columna != 'Acciones',
                            )
                            .map((columna) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: TextFormField(
                                  controller: controladores[columna],
                                  decoration: InputDecoration(
                                    labelText: columna,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: const Color(0xFF2C3E50),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  keyboardType:
                                      _esNumerico(columna)
                                          ? TextInputType.number
                                          : TextInputType.text,
                                ),
                              );
                            })
                            .toList(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _guardarProducto(controladores),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C3E50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Guardar Producto'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Función para determinar si un campo es numérico
  bool _esNumerico(String columna) {
    const camposNumericos = [
      'Diámetro',
      'Altura Total',
      'Espesor',
      'Huecos',
      'Peso',
      'Hueco',
      'Banda',
      'Bocín',
      'POC',
    ];
    return camposNumericos.contains(columna);
  }

  // Función para guardar el producto
  void _guardarProducto(
    Map<String, TextEditingController> controladores,
  ) async {
    try {
      Map<String, dynamic> datosProducto = {};

      // Convertir los datos según la categoría
      for (String columna in controladores.keys) {
        String valor = controladores[columna]!.text.trim();
        if (valor.isNotEmpty) {
          datosProducto[_convertirColumnaNombreCampo(columna)] = valor;
        }
      }

      // Calcular descuento 20% si hay PVP
      if (datosProducto.containsKey('pvp')) {
        double pvp = double.tryParse(datosProducto['pvp'].toString()) ?? 0.0;
        datosProducto['descuento20'] = (pvp * 0.8).toStringAsFixed(2);
      }

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('catalogo')
          .doc(categoriaSeleccionada)
          .collection('productos')
          .add(datosProducto);

      Navigator.of(context).pop();

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Producto agregado exitosamente a $categoriaSeleccionada',
          ),
          backgroundColor: const Color(0xFF2C3E50),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar el producto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Función para convertir nombre de columna a nombre de campo
  String _convertirColumnaNombreCampo(String columna) {
    switch (columna) {
      case 'Referencia':
        return 'referencia';
      case 'Nombre':
        return 'nombre';
      case 'Diámetro':
        return 'diametro';
      case 'Altura Total':
        return 'alturaTotal';
      case 'Bocín':
        return 'bocin';
      case 'Espesor':
        return 'espesor';
      case 'Huecos':
        return 'huecos';
      case 'Tipo (S/V)':
        return 'tipo';
      case 'PVP':
        return 'pvp';
      case '20%': 
      return 'descuento20';
      case 'Peso':
        return 'peso';
      case 'Hueco':
        return 'hueco';
      case 'Banda':
        return 'banda';
      case 'POC':
        return 'poc';
      case 'Observaciones':
        return 'observaciones';
      case 'Descripción':
        return 'descripcion';
      default:
        return columna.toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // Header
          Transform.translate(
            offset: const Offset(-0.5, 0),
            child: Container(
              width: double.infinity,
              color: const Color(0xFF2C3E50),
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 38),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Visualizar Catálogo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filtros y controles
          Container(
            color: Colors.white, // Cambiado de Colors.grey[100] a Colors.white
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Selector de categoría
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: categoriaSeleccionada,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: const Color(0xFF2C3E50),
                        ),
                        style: TextStyle(
                          color: const Color(0xFF2C3E50),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        dropdownColor:
                            Colors.white, // Fondo blanco para el dropdown
                        onChanged: (String? nuevaCategoria) {
                          if (nuevaCategoria != null) {
                            setState(() {
                              categoriaSeleccionada = nuevaCategoria;
                              terminoBusqueda = '';
                              _controladorBusqueda.clear();
                            });
                          }
                        },
                        items:
                            categorias.map<DropdownMenuItem<String>>((
                              String categoria,
                            ) {
                              return DropdownMenuItem<String>(
                                value: categoria,
                                child: Container(
                                  color:
                                      Colors
                                          .white, // Fondo blanco para cada item
                                  child: Row(
                                    children: [
                                      Icon(
                                        _obtenerIconoCategoriaPorNombre(
                                          categoria,
                                        ),
                                        size: 20,
                                        color: const Color(0xFF2C3E50),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        categoria,
                                        style: const TextStyle(
                                          color: Color(0xFF2C3E50),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Campo de búsqueda
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _controladorBusqueda,
                      decoration: InputDecoration(
                        hintText: 'Buscar por referencia o nombre...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: const Color(0xFF2C3E50),
                        ),
                        suffixIcon:
                            terminoBusqueda.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      terminoBusqueda = '';
                                      _controladorBusqueda.clear();
                                    });
                                  },
                                )
                                : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (valor) {
                        setState(() {
                          terminoBusqueda = valor;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Botón Agregar Producto
                Container(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _mostrarDialogoAgregarProducto,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Agregar Producto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C3E50),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Botón Importar
                Container(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      navegarConFade(context, const ImportarCatalogoScreen());
                    },
                    icon: const Icon(Icons.file_upload, size: 20),
                    label: const Text('Importar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabla de productos
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: StreamBuilder<QuerySnapshot>(
                stream: _obtenerProductos(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar los datos',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red[400],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Cargando productos...',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _obtenerIconoCategoria(),
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay productos en $categoriaSeleccionada',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Importa un archivo CSV para ver los productos aquí',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final todosLosProductos = snapshot.data!.docs;
                  final productosFiltrados = _filtrarProductos(
                    todosLosProductos,
                  );
                  final columnas = _obtenerColumnas();

                  if (productosFiltrados.isEmpty &&
                      terminoBusqueda.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron productos',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Intenta con otro término de búsqueda',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información de resultados
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              Colors
                                  .white, // Cambiado de color gris con opacidad a blanco
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF2C3E50).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _obtenerIconoCategoria(),
                              color: const Color(0xFF2C3E50),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$categoriaSeleccionada',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2C3E50),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Mostrando ${productosFiltrados.length} de ${todosLosProductos.length} productos',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF2C3E50),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tabla
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                Colors
                                    .white, // Cambiado de color gris con opacidad a blanco
                              ),
                              headingTextStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2C3E50),
                                fontSize: 14,
                              ),
                              dataTextStyle: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              columnSpacing: 20,
                              horizontalMargin: 12,
                              dataRowColor: MaterialStateProperty.all(
                                Colors.white,
                              ), // Filas blancas
                              columns:
                                  columnas.map((columna) {
                                    return DataColumn(label: Text(columna));
                                  }).toList(),
                              rows:
                                  productosFiltrados.map((producto) {
                                    final data =
                                        producto.data() as Map<String, dynamic>;
                                    return DataRow(
                                      color: MaterialStateProperty.all(
                                        Colors.white,
                                      ), // Fila blanca
                                      cells:
                                          columnas.map((columna) {
                                            if (columna == 'Acciones') {
                                              return DataCell(
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit_outlined,
                                                        color: Color(
                                                          0xFF4682B4,
                                                        ),
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        _mostrarDialogoEditarProducto(
                                                          producto.id,
                                                          data,
                                                        );
                                                      },
                                                      tooltip:
                                                          'Editar producto',
                                                    ),
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                        color: Colors.redAccent,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        _mostrarDialogoEliminar(
                                                          producto.id,
                                                          data['nombre']
                                                                  ?.toString() ??
                                                              data['referencia']
                                                                  ?.toString() ??
                                                              'Producto',
                                                        );
                                                      },
                                                      tooltip:
                                                          'Eliminar producto',
                                                    ),
                                                  ],
                                                ),
                                              );
                                            } else {
                                              return DataCell(
                                                Text(
                                                  _obtenerValorCelda(
                                                    data,
                                                    columna,
                                                  ),
                                                ),
                                              );
                                            }
                                          }).toList(),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Función auxiliar para obtener iconos por nombre de categoría
  IconData _obtenerIconoCategoriaPorNombre(String categoria) {
    switch (categoria) {
      case 'Discos':
        return Icons.album;
      case 'Tambores':
        return Icons.radio_button_unchecked;
      case 'Bocines':
        return Icons.speaker;
      case 'Arañas':
        return Icons.settings;
      case 'Alcantarillado':
        return Icons.water_damage;
      case 'Sumideros Rejillas':
        return Icons.grid_on;
      case 'Rejillas':
        return Icons.view_module;
      case 'Cocinas':
        return Icons.kitchen;
      case 'Gimnasio':
        return Icons.fitness_center;
      case 'Agrícolas':
        return Icons.agriculture;
      case 'Sistemas Adaptación Frenos':
        return Icons.build;
      case 'Soportería':
        return Icons.construction;
      default:
        return Icons.category;
    }
  }
}
