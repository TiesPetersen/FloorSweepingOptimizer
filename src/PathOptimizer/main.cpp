#include "Graph.hpp"
#include "SimulatedAnnealing.hpp"

#include <iostream>

using namespace std;

int main() {
  cout << "Loading graph..." << endl;
  Graph graph("AH_B_adjacency_list.txt");

  // Load map coordinates for angle calculation
  cout << "Loading map coordinates..." << endl;
  graph.loadMap("AH_B_map.txt");

  cout << "Initializing simulated annealing..." << endl;
  // Parameters: Graph, InitTemp, EndTemp, Iterations, AngleWeight
  // AngleWeight = 20.0 (Adjust this to prioritize straighter paths)
  SimulatedAnnealing sa(graph, 300.0, 0.5, 10000000, 2.0);

  cout << "Starting optimization..." << endl;
  sa.optimize();
  sa.saveOptimizedPath("path.txt", true);

  cout << "Best path cost: " << sa.getBestCost() << endl;

  return 0;
}