#pragma once

#include "Graph.hpp"
#include <stdint.h>

class SimulatedAnnealing {
private:
  const Graph &graph;
  vector<uint16_t> currentPath;
  double currentDistance;
  vector<uint16_t> bestPath;
  double bestDistance;
  int pathSize;
  double initialTemperature;
  double finalTemperature;
  long long iterations;

  double acceptanceProbability(double distanceDifference, double temperature);

  double calculatePathDistance(const vector<uint16_t> &path);

public:
  SimulatedAnnealing(const Graph &graph, double initialTemperature,
                     double finalTemperature, long long iterations);

  void optimize();

  vector<uint16_t> calculateRandomPath();

  void saveOptimizedPath(const string filePath);
};