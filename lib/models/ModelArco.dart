import 'package:flutter/material.dart';
import 'package:grafos/models/ModelGrafo.dart';

class ModeloArco {
  ModeloNodo origen, destino;
  String peso;
  Offset puntoControl;
  Color color;
  bool esSolucion;  // Nuevo campo para identificar si es parte de la solución

  ModeloArco(
    this.origen,
    this.destino,
    this.peso,
    this.puntoControl, {
    this.color = Colors.black,
    this.esSolucion = false,  // Valor predeterminado en falso
  });
}
