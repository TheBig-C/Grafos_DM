import 'dart:math';
import 'package:flutter/material.dart';
import 'package:grafos/drawer/dibujos.dart';
import 'package:grafos/models/ModelArco.dart';
import 'package:grafos/models/ModelGrafo.dart';
import 'package:grafos/views/matriz_view.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin  {
  List<ModeloNodo> vNodo = [];
  List<ModeloArco> vArco = [];
  List<ModeloNodo> resultadoNodos = [];
  List<ModeloArco> resultadoArcos = [];
    late AnimationController _progressController; // Nuevo controlador para animar el progreso de conexión
late Animation<double>  _progressAnimation;
  int idNodo = 1;
  int modo = -1;
  bool flagOrigen = false;
  int nodoOrigen = -1;
  ModeloNodo? nodoSeleccionado;
  ModeloArco? arcoSeleccionado;
  Offset canvasOffset = Offset.zero;
  Offset initialFocalPoint = Offset.zero;

  // Definir listas y matriz para nodos de demanda y oferta
  List<ModeloNodo> nodosDemanda = [];
  List<ModeloNodo> nodosOferta = [];
  List<List<int>> matriz = [];

  late AnimationController _controller;
  
  late Animation<Color?> _colorAnimation;
  bool hasResult = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _colorAnimation = ColorTween(
      begin: Colors.redAccent,
      end: Colors.red.shade900,
    ).animate(_controller);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        setState(() {});
      });
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_progressController);
  }
 @override
  void dispose() {
    _controller.dispose();
    _progressController.dispose();
    super.dispose();
  }
  @override
   Widget build(BuildContext context) {
    final colorAnimations = List<Animation<Color?>>.generate(
      resultadoNodos.length,
      (_) => _colorAnimation,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Graficador", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.grid_on, color: Colors.white),
            onPressed: () => mostrarMatrizAdyacencia(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Ayuda') {
                _mostrarAyuda();
              } else if (value == 'Acerca de') {
                _mostrarAcercaDe();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Ayuda',
                child: Text('Ayuda'),
              ),
              const PopupMenuItem<String>(
                value: 'Acerca de',
                child: Text('Acerca de'),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: InteractiveViewer(
        boundaryMargin: EdgeInsets.all(20.0),
        minScale: 0.5,
        maxScale: 3.0,
        child: GestureDetector(
          onPanStart: (details) {
            if (modo == 8) {
              initialFocalPoint = details.localPosition;
            }
          },
          onPanUpdate: (details) {
            if (modo == 8) {
              setState(() {
                canvasOffset += details.delta;
              });
            }
          },
          child: Transform.translate(
            offset: canvasOffset,
            child: Stack(
              children: [
                CustomPaint(
                  painter: DibujoArco(vArco, resultadoArcos, colorAnimations, _progressAnimation),
                ),
                CustomPaint(
                  painter: DibujaNodo(vNodo, resultadoNodos, colorAnimations),
                ),
                _buildGestureDetector(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  void _mostrarAyuda() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Ayuda"),
          content: Text("Aquí puedes obtener información sobre cómo utilizar esta aplicación."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  void _mostrarAcercaDe() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Acerca de"),
          content: Text("Aplicación de graficación interactiva para gestionar nodos y arcos."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  void mostrarMatrizAdyacencia(BuildContext context) async {
    nodosDemanda = vNodo.where((nodo) => nodo.x < MediaQuery.of(context).size.width / 2).toList();
    nodosOferta = vNodo.where((nodo) => nodo.x >= MediaQuery.of(context).size.width / 2).toList();

    matriz = List.generate(
      nodosDemanda.length,
      (_) => List.generate(nodosOferta.length, (_) => 0),
    );

    for (var arco in vArco) {
      int row = nodosDemanda.indexOf(arco.origen);
      int col = nodosOferta.indexOf(arco.destino);
      if (row >= 0 && col >= 0) {
        matriz[row][col] = int.tryParse(arco.peso) ?? 0;
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatrizView(
          nodosDemanda: nodosDemanda,
          nodosOferta: nodosOferta,
          matriz: matriz,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        resultadoNodos = result['nodos'] ?? [];
        resultadoArcos = result['arcos'] ?? [];
        hasResult = true;

        vArco.forEach((arco) {
          arco.esSolucion = resultadoArcos.contains(arco);
        });

        vArco = resultadoArcos;
      });

      _progressController.forward(from: 0); // Inicia la animación de conexión
    }
  }

  

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            child: Text(
              'Menú de Opciones',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Borrar Todo'),
            onTap: () {
              setState(() {
                vNodo.clear();
                vArco.clear();
                resultadoNodos.clear();
                resultadoArcos.clear();
                hasResult = false;
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      color: Colors.teal.shade900,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildActionButton(Icons.add, 1),
          _buildActionButton(Icons.delete, 2),
          _buildActionButton(Icons.move_down_rounded, 3),
          _buildActionButton(Icons.arrow_back, 4),
          _buildActionButton(Icons.adjust, 5),
          _buildActionButton(Icons.select_all, 7),
          _buildActionButton(Icons.open_with, 8), // Botón para mover el canvas completo
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, int actionMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: CircleAvatar(
        backgroundColor: (modo == actionMode) ? Colors.white : Colors.teal,
        child: IconButton(
          onPressed: () {
            setState(() {
              modo = actionMode;
            });
          },
          icon: Icon(icon),
        ),
      ),
    );
  }

  Widget _buildGestureDetector() {
    return GestureDetector(
      onPanDown: (details) {
        Offset position = details.localPosition;
        if (modo == 1) {
          setState(() {
            vNodo.add(ModeloNodo(
              position.dx,
              position.dy,
              20,
              Colors.teal,
              idNodo.toString(),
            ));
            idNodo++;
          });
        } else if (modo == 2) {
          setState(() {
            int pos = tocoNodo(position.dx, position.dy);
            if (pos >= 0) {
              vNodo.removeAt(pos);
            } else {
              int arcoIndex = tocoArco(position.dx, position.dy);
              if (arcoIndex >= 0) {
                vArco.removeAt(arcoIndex);
              }
            }
          });
        } else if (modo == 4) {
          int pos = tocoNodo(position.dx, position.dy);
          if (pos >= 0 && !flagOrigen) {
            flagOrigen = true;
            nodoOrigen = pos;
          } else if (pos >= 0 && flagOrigen) {
            setState(() {
              ModeloNodo destino = vNodo[pos];
              ModeloNodo origen = vNodo[nodoOrigen];
              Offset puntoControl = Offset(
                (origen.x + destino.x) / 2,
                (origen.y + destino.y) / 2 - 50,
              );
              vArco.add(ModeloArco(origen, destino, "10", puntoControl));
              flagOrigen = false;
            });
          }
        } else if (modo == 5) {
          for (var arco in vArco) {
            double dist = sqrt(
                pow(position.dx - arco.puntoControl.dx, 2) +
                    pow(position.dy - arco.puntoControl.dy, 2));
            if (dist < 20) {
              setState(() {
                arcoSeleccionado = arco;
                modo = 6;
              });
              break;
            }
          }
        } else if (modo == 7) {
          int pos = tocoNodo(position.dx, position.dy);
          if (pos >= 0) {
            nodoSeleccionado = vNodo[pos];
            mostrarDialogoPersonalizacionNodo();
          } else {
            int arcoIndex = tocoArco(position.dx, position.dy);
            if (arcoIndex >= 0) {
              arcoSeleccionado = vArco[arcoIndex];
              mostrarDialogoPersonalizacionArco();
            }
          }
        }
      },
      onPanUpdate: (details) {
        Offset position = details.localPosition;
        if (modo == 6 && arcoSeleccionado != null) {
          setState(() {
            arcoSeleccionado!.puntoControl = position;
          });
        } else if (modo == 3) {
          int pos = tocoNodo(position.dx, position.dy);
          if (pos >= 0) {
            setState(() {
              vNodo[pos].x = position.dx;
              vNodo[pos].y = position.dy;
            });
          }
        }
      },
    );
  }

  int tocoNodo(double x, double y) {
    for (int i = 0; i < vNodo.length; i++) {
      double dist = sqrt(pow(x - vNodo[i].x, 2) + pow(y - vNodo[i].y, 2));
      if (dist <= vNodo[i].radio) {
        return i;
      }
    }
    return -1;
  }

  int tocoArco(double x, double y) {
    for (int i = 0; i < vArco.length; i++) {
      double dist = sqrt(pow(x - vArco[i].puntoControl.dx, 2) + pow(y - vArco[i].puntoControl.dy, 2));
      if (dist < 20) {
        return i;
      }
    }
    return -1;
  }

  void mostrarDialogoPersonalizacionNodo() {
  double nuevoRadio = nodoSeleccionado?.radio ?? 20;
  String nuevoNombre = nodoSeleccionado?.nombre ?? "";
  Color nuevoColorInicial = nodoSeleccionado?.color ?? Colors.teal;
  Color nuevoColorFinal = Colors.blue;
  bool esDegradado = nodoSeleccionado?.esDegradado ?? false;
  double bordeAncho = nodoSeleccionado?.bordeAncho ?? 1.0;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Personalizar Nodo'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre del Nodo
                TextField(
                  onChanged: (value) => nuevoNombre = value,
                  decoration: InputDecoration(labelText: 'Nombre del Nodo'),
                  controller: TextEditingController(text: nuevoNombre),
                ),
                SizedBox(height: 10),

                // Tamaño del Nodo
                Text('Tamaño del Nodo: ${nuevoRadio.toInt()}'),
                Slider(
                  min: 10,
                  max: 50,
                  value: nuevoRadio,
                  onChanged: (value) {
                    setState(() {
                      nuevoRadio = value;
                    });
                  },
                ),
                SizedBox(height: 10),

                // Selector de Borde
                Text('Estilo de Borde'),
                DropdownButton<double>(
                  value: bordeAncho,
                  items: [
                    DropdownMenuItem(value: 0.0, child: Text('Sin borde')),
                    DropdownMenuItem(value: 1.0, child: Text('Borde normal')),
                    DropdownMenuItem(value: 3.0, child: Text('Borde grueso')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      bordeAncho = value ?? 1.0;
                    });
                  },
                ),
                SizedBox(height: 10),

                // Color del Nodo y Degradado
                Row(
                  children: [
                    Text('Color del Nodo'),
                    Switch(
                      value: esDegradado,
                      onChanged: (value) {
                        setState(() {
                          esDegradado = value;
                        });
                      },
                    ),
                    Text(esDegradado ? 'Degradado' : 'Sólido'),
                  ],
                ),
                if (!esDegradado)
                  GestureDetector(
                    onTap: () async {
                      Color? colorSeleccionado = await mostrarSelectorDeColor();
                      if (colorSeleccionado != null) {
                        setState(() {
                          nuevoColorInicial = colorSeleccionado;
                        });
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      color: nuevoColorInicial,
                      margin: EdgeInsets.only(top: 10),
                    ),
                  ),
                if (esDegradado)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('Color Inicial'),
                          GestureDetector(
                            onTap: () async {
                              Color? colorSeleccionado = await mostrarSelectorDeColor();
                              if (colorSeleccionado != null) {
                                setState(() {
                                  nuevoColorInicial = colorSeleccionado;
                                });
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              color: nuevoColorInicial,
                              margin: EdgeInsets.only(top: 10),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Color Final'),
                          GestureDetector(
                            onTap: () async {
                              Color? colorSeleccionado = await mostrarSelectorDeColor();
                              if (colorSeleccionado != null) {
                                setState(() {
                                  nuevoColorFinal = colorSeleccionado;
                                });
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              color: nuevoColorFinal,
                              margin: EdgeInsets.only(top: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            child: Text("Guardar"),
            onPressed: () {
              // Aplicar los valores directamente en el nodo seleccionado
              setState(() {
                nodoSeleccionado?.nombre = nuevoNombre;
                nodoSeleccionado?.radio = nuevoRadio;
                nodoSeleccionado?.color = nuevoColorInicial;
                nodoSeleccionado?.bordeAncho = bordeAncho;
                nodoSeleccionado?.esDegradado = esDegradado;
                nodoSeleccionado?.colorDegradado = esDegradado
                    ? [nuevoColorInicial, nuevoColorFinal]
                    : null;
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

  Future<Color?> mostrarSelectorDeColor() async {
    return showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Selecciona un Color"),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8.0,
              children: [
                _colorOption(Colors.teal),
                _colorOption(Colors.blue),
                _colorOption(Colors.red),
                _colorOption(Colors.green),
                _colorOption(Colors.orange),
                _colorOption(Colors.purple),
                _colorOption(Colors.pink),
                _colorOption(Colors.yellow),
                _colorOption(Colors.brown),
                _colorOption(Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _colorOption(Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(color);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(width: 1, color: Colors.black),
        ),
      ),
    );
  }

  void mostrarDialogoPersonalizacionArco() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String nuevoPeso = arcoSeleccionado?.peso ?? "10";
        return AlertDialog(
          title: Text('Personalizar Arco'),
          content: TextField(
            onChanged: (value) => nuevoPeso = value,
            decoration: InputDecoration(labelText: 'Peso del Arco'),
            controller: TextEditingController(text: nuevoPeso),
          ),
          actions: [
            TextButton(
              child: Text("Guardar"),
              onPressed: () {
                setState(() {
                  arcoSeleccionado?.peso = nuevoPeso;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
