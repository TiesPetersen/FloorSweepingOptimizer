#pragma once

#include "Graph.hpp"
#include <stdint.h>
#include <vector>

class SimulatedAnnealing {
private:
  const Graph &graph;

  vector<int> currentPath;
  double currentCost;
  vector<int> bestPath;
  double bestCost;

  int pathSize;

  double initialTemperature;
  double finalTemperature;
  long long iterations;

  double angleWeight;

  double acceptanceProbability(double distanceDifference, double temperature);

  double calculateCost(const vector<int> &path);

public:
  SimulatedAnnealing(const Graph &graph, double initialTemperature,
                     double finalTemperature, long long iterations,
                     double angleWeight);

  void optimize();

  vector<int> calculateRandomPath();

  void saveOptimizedPath(const string filePath, bool appendBestCost = false);
};