import 'dart:async';
import 'dart:isolate';
import 'dart:math';

/// Estructura de datos para manejar la comunicación entre el isolate y la UI
class TransportData {
  final List<List<int>> costsMatrix;
  final SendPort sendPort;
  final int maxIterations;

  TransportData(this.costsMatrix, this.sendPort, {this.maxIterations = 100});
}

// Método principal para iniciar el algoritmo en un Isolate
void startAlgorithmInIsolate(List<List<int>> costsMatrix, int maxIterations) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(runAlgorithm, TransportData(costsMatrix, receivePort.sendPort));

  receivePort.listen((result) {
    if (result is String) {
      print("Resultado del algoritmo: $result");
    } else {
      print("Algoritmo terminado. Resultado: ${result}");
    }
    receivePort.close();
  });
}

// Función que ejecuta el algoritmo en el isolate
void runAlgorithm(TransportData data) {
  try {
    final result = runNorthWestAlgorithm(data.costsMatrix, data.maxIterations);
    data.sendPort.send(result);
  } catch (e) {
    data.sendPort.send("Error en el algoritmo: $e");
  }
}

// Método optimizado de North-West para ejecutar en el isolate
List<List<int>> runNorthWestAlgorithm(List<List<int>> costsMatrix, int maxIterations) {
  int numRows = costsMatrix.length - 1;
  int numCols = costsMatrix[0].length - 1;

  List<List<int>> assignmentMatrix = List.generate(numRows, (_) => List.filled(numCols, 0));
  List<int> supply = getSupply(costsMatrix);
  List<int> demand = getDemand(costsMatrix);

  int i = 0, j = 0, iterations = 0;
  while (i < supply.length && j < demand.length) {
    if (++iterations > maxIterations) {
      throw "Límite de iteraciones alcanzado.";
    }
    int amount = min(supply[i], demand[j]);
    assignmentMatrix[i][j] = amount;
    supply[i] -= amount;
    demand[j] -= amount;
    if (supply[i] == 0 && i < supply.length - 1) i++;
    if (demand[j] == 0 && j < demand.length - 1) j++;
  }
  return assignmentMatrix;
}

// Función auxiliar para obtener la oferta
List<int> getSupply(List<List<int>> matrix) {
  return matrix.take(matrix.length - 1).map((row) => row.last).toList();
}

// Función auxiliar para obtener la demanda
List<int> getDemand(List<List<int>> matrix) {
  return matrix.last.take(matrix[0].length - 1).toList();
}
