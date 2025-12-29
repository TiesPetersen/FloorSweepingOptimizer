#include "Graph.hpp"
#include "SimulatedAnnealing.hpp"

#include <iostream>

using namespace std;

int main() {

  cout << "Loading graph..." << endl;
  Graph graph("adjacency_list.txt");
  // graph.printAdjMatrix();
  // graph.printDistanceTable();

  cout << "Initializing simulated annealing..." << endl;
  SimulatedAnnealing sa(graph, 1000.0, 1, 100000000);

  cout << "Starting optimization..." << endl;
  sa.optimize();
  sa.saveOptimizedPath("path.txt");

  return 0;
}