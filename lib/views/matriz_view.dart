import 'dart:math';
import 'package:flutter/material.dart';
import 'package:grafos/models/ModelArco.dart';
import 'package:grafos/models/ModelGrafo.dart';

class MatrizView extends StatefulWidget {
  final List<List<int>> matriz;
  final List<ModeloNodo> nodosDemanda;
  final List<ModeloNodo> nodosOferta;

  const MatrizView({
    required this.matriz,
    required this.nodosDemanda,
    required this.nodosOferta,
  });

  @override
  _MatrizViewState createState() => _MatrizViewState();
}

class _MatrizViewState extends State<MatrizView> {
  late List<List<int>> assignmentMatrix;
  late int totalCost;
  List<int> demandas = [];
  List<int> ofertas = [];
  List<ModeloNodo> resultadoNodos = [];
  List<ModeloArco> resultadoArcos = [];

  @override
  void initState() {
    super.initState();
    assignmentMatrix = List.generate(
      widget.nodosDemanda.length, 
      (_) => List.filled(widget.nodosOferta.length, 0)
    );
    totalCost = 0;

    demandas = List.filled(widget.nodosDemanda.length, 0);
    ofertas = List.filled(widget.nodosOferta.length, 0);
  }

  // Calcula la asignación utilizando el método North West
  void _calcularAsignacion() {
    List<List<int>> costosConDemandaOferta = List.generate(
      widget.nodosDemanda.length + 1,
      (i) => List.generate(widget.nodosOferta.length + 1, (j) => 0)
    );

    // Llenar la matriz de costos inicial
    for (int i = 0; i < widget.matriz.length; i++) {
      for (int j = 0; j < widget.matriz[i].length; j++) {
        costosConDemandaOferta[i][j] = widget.matriz[i][j];
      }
    }

    // Añadir demandas y ofertas en la matriz extendida
    for (int i = 0; i < demandas.length; i++) {
      costosConDemandaOferta[i][widget.nodosOferta.length] = demandas[i];
    }
    for (int j = 0; j < ofertas.length; j++) {
      costosConDemandaOferta[widget.nodosDemanda.length][j] = ofertas[j];
    }

    // Calcular la asignación usando el método North West
    assignmentMatrix = northWest(costosConDemandaOferta);
    totalCost = calcularCostoTotal(widget.matriz, assignmentMatrix);

    // Almacenar los nodos y arcos involucrados en el resultado
    resultadoNodos = widget.nodosDemanda + widget.nodosOferta;
    resultadoArcos = [];

    setState(() {});
  }

  // Reinicia la matriz de asignación y el costo total
  void _reiniciarMatriz() {
    setState(() {
      assignmentMatrix = List.generate(
          widget.matriz.length, (i) => List.filled(widget.matriz[0].length, 0));
      totalCost = 0;
    });
  }

  // Abre un diálogo de ayuda
  void _mostrarAyuda() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Ayuda"),
          content: Text("Esta vista muestra una matriz de costos. Puedes ingresar demandas y ofertas, calcular la asignación óptima y ver el costo total."),
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

 void _volverAlHome() {
  // Aquí debes asegurarte de que los arcos en `resultadoArcos` estén configurados correctamente.
  resultadoArcos = [];
  for (int i = 0; i < assignmentMatrix.length; i++) {
    for (int j = 0; j < assignmentMatrix[i].length; j++) {
      if (assignmentMatrix[i][j] > 0) {
        // Encontramos un arco asignado. Crear el arco y marcarlo como parte de la solución.
        resultadoArcos.add(
          ModeloArco(
            widget.nodosDemanda[i],
            widget.nodosOferta[j],
            assignmentMatrix[i][j].toString(),
            Offset(
              (widget.nodosDemanda[i].x + widget.nodosOferta[j].x) / 2,
              (widget.nodosDemanda[i].y + widget.nodosOferta[j].y) / 2 - 50,
            ),
            color: Colors.blue,  // Color opcional para diferenciarlo
            esSolucion: true,    // Marcamos el arco como parte de la solución
          ),
        );
      }
    }
  }

  Navigator.of(context).pop({
    'nodos': resultadoNodos,
    'arcos': resultadoArcos,
  });
}

  // Genera la interfaz
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Matriz de Costos", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            onPressed: _calcularAsignacion,
            icon: Icon(Icons.calculate, color: Colors.white),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Ayuda') {
                _mostrarAyuda();
              } else if (value == 'Reiniciar') {
                _reiniciarMatriz();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Ayuda',
                child: Text('Ayuda'),
              ),
              const PopupMenuItem<String>(
                value: 'Reiniciar',
                child: Text('Reiniciar matriz'),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _volverAlHome,
            child: const Text("Volver con Resultados"),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _buildTextFields("Ingresar Demandas:", widget.nodosDemanda, demandas),
                SizedBox(height: 10),
                _buildTextFields("Ingresar Ofertas:", widget.nodosOferta, ofertas),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('')), // Columna vacía para la esquina
                  ...widget.nodosOferta.map((nodo) => DataColumn(label: Text(nodo.nombre))),
                  DataColumn(label: Text('Disponibilidad')),
                ],
                rows: [
                  ...List.generate(widget.nodosDemanda.length, (i) {
                    return DataRow(cells: [
                      DataCell(Text(widget.nodosDemanda[i].nombre, style: TextStyle(fontWeight: FontWeight.bold))),
                      ...List.generate(widget.nodosOferta.length, (j) {
                        return DataCell(
                          Container(
                            color: assignmentMatrix[i][j] > 0 ? Colors.lightGreenAccent : Colors.transparent,
                            child: Center(
                              child: Text(assignmentMatrix[i][j].toString()),
                            ),
                          ),
                        );
                      }),
                      DataCell(Text(demandas[i].toString())),
                    ]);
                  }),
                  DataRow(
                    cells: [
                      DataCell(Text("Demanda", style: TextStyle(fontWeight: FontWeight.bold))),
                      ...List.generate(ofertas.length, (j) {
                        return DataCell(Text(ofertas[j].toString()));
                      }),
                      DataCell(Text("")),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Costo Total de Asignación: $totalCost",
            style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Constructor de campos de texto para demandas y ofertas
  Widget _buildTextFields(String label, List<ModeloNodo> nodos, List<int> values) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(nodos.length, (index) {
            return Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: nodos[index].nombre,
                    filled: true,
                    fillColor: Colors.blue[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    values[index] = int.tryParse(value) ?? 0;
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // Método North West para asignación inicial
  List<List<int>> northWest(List<List<int>> costsMatrix) {
    int numRows = costsMatrix.length;
    int numCols = costsMatrix[0].length;
    List<List<int>> assignmentMatrix = List.generate(numRows - 1, (i) => List.filled(numCols - 1, 0));

    List<int> supply = getSupply(costsMatrix);
    List<int> demand = getDemand(costsMatrix);

    int i = 0, j = 0;
    while (i < supply.length && j < demand.length) {
      int amount = min(supply[i], demand[j]);
      assignmentMatrix[i][j] = amount;

      supply[i] -= amount;
      demand[j] -= amount;

      if (supply[i] == 0 && i < supply.length) i++;
      if (demand[j] == 0 && j < demand.length) j++;
    }

    return assignmentMatrix;
  }

  // Calcula el costo total de la asignación
  int calcularCostoTotal(List<List<int>> costsMatrix, List<List<int>> assignmentMatrix) {
    int total = 0;
    for (int i = 0; i < assignmentMatrix.length; i++) {
      for (int j = 0; j < assignmentMatrix[i].length; j++) {
        total += assignmentMatrix[i][j] * costsMatrix[i][j];
      }
    }
    return total;
  }

  // Obtiene el suministro de cada fila
  List<int> getSupply(List<List<int>> matrix) {
    return matrix.take(matrix.length - 1).map((row) => row.last).toList();
  }

  // Obtiene la demanda de cada columna
  List<int> getDemand(List<List<int>> matrix) {
    return matrix.last.take(matrix[0].length - 1).toList();
  }
}
