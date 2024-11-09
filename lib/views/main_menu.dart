import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:grafos/views/home.dart';

class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  final Random _random = Random();
  final List<Offset> _nodePositions = []; // Posiciones de los nodos
  final List<Offset> _nodeVelocities = []; // Velocidades de los nodos
  final List<Color> _nodeColors = []; // Colores de los nodos
  final List<List<int>> _edges = []; // Conexiones entre nodos
  int? _lastTappedNode; // Último nodo tocado para conectar
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_updateNodePositions)..start(); // Iniciar el ticker
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nodePositions.isEmpty) {
      _generateRandomNodes(5); // Generar nodos iniciales solo una vez
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // Genera una cantidad de nodos en posiciones, velocidades y colores aleatorios
  void _generateRandomNodes(int count) {
    final screenSize = MediaQuery.of(context).size;
    for (int i = 0; i < count; i++) {
      _nodePositions.add(
        Offset(
          _random.nextDouble() * screenSize.width,
          _random.nextDouble() * screenSize.height,
        ),
      );
      _nodeVelocities.add(
        Offset(
          (_random.nextDouble() - 0.5) * 2, // Velocidad en X
          (_random.nextDouble() - 0.5) * 2, // Velocidad en Y
        ),
      );
      _nodeColors.add(_getRandomColor()); // Asignar color aleatorio
    }
  }

  // Generar un color aleatorio
  Color _getRandomColor() {
    return Color.fromARGB(
      255,
      _random.nextInt(256),
      _random.nextInt(256),
      _random.nextInt(256),
    );
  }

  // Agregar un nodo en la posición tocada por el usuario
  void _addNode(Offset position) {
    setState(() {
      _nodePositions.add(position);
      _nodeVelocities.add(
        Offset(
          (_random.nextDouble() - 0.5) * 2,
          (_random.nextDouble() - 0.5) * 2,
        ),
      );
      _nodeColors.add(_getRandomColor()); // Asignar color aleatorio al nuevo nodo
    });
  }

  // Actualizar las posiciones de los nodos en cada tick
  void _updateNodePositions(Duration elapsed) {
    final screenSize = MediaQuery.of(context).size;
    setState(() {
      for (int i = 0; i < _nodePositions.length; i++) {
        // Actualizar la posición del nodo sumando la velocidad
        Offset newPosition = _nodePositions[i] + _nodeVelocities[i];

        // Rebotar en los bordes de la pantalla
        if (newPosition.dx <= 0 || newPosition.dx >= screenSize.width) {
          _nodeVelocities[i] = Offset(-_nodeVelocities[i].dx, _nodeVelocities[i].dy);
        }
        if (newPosition.dy <= 0 || newPosition.dy >= screenSize.height) {
          _nodeVelocities[i] = Offset(_nodeVelocities[i].dx, -_nodeVelocities[i].dy);
        }

        // Aplicar la nueva posición
        _nodePositions[i] = Offset(
          newPosition.dx.clamp(0, screenSize.width),
          newPosition.dy.clamp(0, screenSize.height),
        );
      }
    });
  }

  // Agregar una conexión entre el último nodo tocado y el actual
  void _addEdge(int currentNode) {
    if (_lastTappedNode != null && _lastTappedNode != currentNode) {
      setState(() {
        _edges.add([_lastTappedNode!, currentNode]);
      });
    }
    _lastTappedNode = currentNode; // Actualizar el último nodo tocado
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro
      body: GestureDetector(
        onTapUp: (details) {
          // Agregar un nuevo nodo donde el usuario tocó
          _addNode(details.localPosition);
        },
        child: Stack(
          children: [
            // Dibujar los nodos y las conexiones
            CustomPaint(
              painter: GraphPainter(_nodePositions, _nodeColors, _edges, _addEdge),
              child: Container(),
            ),
            // Título y botones en el centro
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Graph-Maker',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildMenuButton(Icons.home, 'Inicio', () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Home()),
                    );
                  }),
                  _buildMenuButton(Icons.info, 'Acerca de', _showAboutDialog),
                  _buildMenuButton(Icons.help, 'Ayuda', _showHelpDialog),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Función para construir los botones
  Widget _buildMenuButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.purpleAccent, Colors.blueAccent],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 40, color: Colors.white),
              SizedBox(height: 10),
              Text(label, style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  // Diálogo "Acerca de"
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Acerca de"),
          content: Text("Aplicación para gestionar nodos y arcos con un enfoque visual."),
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

  // Diálogo "Ayuda"
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Ayuda"),
          content: Text("Aquí puedes obtener información sobre cómo usar la app."),
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
}

// Pintor de los nodos y las conexiones
class GraphPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final List<Color> nodeColors; // Colores de los nodos
  final List<List<int>> edges;
  final Function(int) onNodeTap; // Función para manejar toques en nodos
  final Paint edgePaint = Paint()
    ..color = Colors.white.withOpacity(0.5)
    ..strokeWidth = 2;

  GraphPainter(this.nodePositions, this.nodeColors, this.edges, this.onNodeTap);

  @override
  void paint(Canvas canvas, Size size) {
    // Dibujar las conexiones (arcos) entre los nodos
    for (var edge in edges) {
      Offset node1 = nodePositions[edge[0]];
      Offset node2 = nodePositions[edge[1]];
      canvas.drawLine(node1, node2, edgePaint);
    }

    // Dibujar los nodos con sus colores respectivos
    for (int i = 0; i < nodePositions.length; i++) {
      final nodePosition = nodePositions[i];
      final nodePaint = Paint()..color = nodeColors[i]; // Color aleatorio para el nodo

      // Dibujar el nodo
      canvas.drawCircle(nodePosition, 20.0, nodePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true; // Siempre repintamos ya que las posiciones de los nodos cambian
  }
}
