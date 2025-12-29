#pragma once

#include "Graph.hpp"
#include <stdint.h>

class SimulatedAnnealing {
private:
  const Graph &graph;
  vector<int> currentPath;
  int currentCost;
  vector<int> bestPath;
  int bestCost;
  int pathSize;
  double initialTemperature;
  double finalTemperature;
  long long iterations;

  double acceptanceProbability(double distanceDifference, double temperature);

  int calculateCost(const vector<int> &path);

public:
  SimulatedAnnealing(const Graph &graph, double initialTemperature,
                     double finalTemperature, long long iterations);

  void optimize();

  vector<int> calculateRandomPath();

  void saveOptimizedPath(const string filePath, bool appendBestCost = false);
};