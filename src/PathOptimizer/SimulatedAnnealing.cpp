#include "SimulatedAnnealing.hpp"

#include <algorithm>
#include <cmath>
#include <fstream>
#include <iostream>
#include <random>

using namespace std;

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

double SimulatedAnnealing::acceptanceProbability(double costDifference,
                                                 double temperature) {
  // If the new cost is better (difference < 0), always accept (return 1.0).
  if (costDifference < 0) {
    return 1.0;
  }
  // Otherwise, accept with probability exp(-delta / temperature).
  return exp(-costDifference / temperature);
}

double SimulatedAnnealing::calculateCost(const vector<int> &path) {
  double totalCost = 0.0;
  double totalDistance = 0.0;
  double totalAngleCost = 0.0;

  size_t size = path.size();
  if (size < 2)
    return 0.0;

  for (size_t i = 0; i < size; ++i) {
    int u = path[i];
    int v = path[(i + 1) % size];

    // 1. Distance Cost
    totalDistance += graph.distanceTable[u][v];

    // 2. Angle Cost (Calculate deviation at node v)
    // We look at the sequence: u -> v -> w
    if (graph.nodeCoordinates.size() == graph.n && angleWeight > 0.0) {
      int w = path[(i + 2) % size];

      Point p1 = graph.nodeCoordinates[u];
      Point p2 = graph.nodeCoordinates[v];
      Point p3 = graph.nodeCoordinates[w];

      // Vector v1 (u -> v)
      double dx1 = p2.x - p1.x;
      double dy1 = p2.y - p1.y;

      // Vector v2 (v -> w)
      double dx2 = p3.x - p2.x;
      double dy2 = p3.y - p2.y;

      // Calculate angles
      double angle1 = atan2(dy1, dx1);
      double angle2 = atan2(dy2, dx2);

      // Calculate deviation (absolute difference)
      double diff = abs(angle1 - angle2);

      // Normalize to [0, PI]
      if (diff > M_PI) {
        diff = 2 * M_PI - diff;
      }

      totalAngleCost += diff;
    }
  }

  totalCost = totalDistance + (totalAngleCost * angleWeight);
  return totalCost;
}

SimulatedAnnealing::SimulatedAnnealing(const Graph &graph,
                                       double initialTemperature,
                                       double finalTemperature,
                                       long long iterations, double angleWeight)
    : graph(graph), initialTemperature(initialTemperature),
      finalTemperature(finalTemperature), iterations(iterations),
      angleWeight(angleWeight) {
  pathSize = graph.n;
  currentPath = calculateRandomPath();
  currentCost = calculateCost(currentPath);
  bestPath = currentPath;
  bestCost = currentCost;
}

void SimulatedAnnealing::optimize() {
  double temperature = initialTemperature;
  // Pre-calculate cooling factor
  double coolingRate =
      pow(finalTemperature / initialTemperature, 1.0 / iterations);

  for (long long iter = 0; iter < iterations; ++iter) {
    // Logging progress every 5% of iterations
    if (iter % (iterations / 20) == 0) {
      printf("Iteration %lld/%lld (%.0f%%), Temp: %.2f, Curr: %.2f, Best: "
             "%.2f\n",
             iter, iterations, (100.0 * iter) / iterations, temperature,
             currentCost, bestCost);
      int count = iter / (iterations / 20);
      saveOptimizedPath("path_inter_" + to_string(count) + ".txt");
    }

    // Generate two distinct indices for swapping
    size_t i = rand() % pathSize;
    size_t j = rand() % pathSize;
    while (i == j) {
      j = rand() % pathSize;
    }
    if (i > j) {
      swap(i, j);
    }
    if (i == 0 && j == pathSize - 1) {
      // Swapping the entire path is pointless
      continue;
    }

    // Perform the 2-opt swap by reversing the segment between i and j
    reverse(currentPath.begin() + i, currentPath.begin() + j + 1);

    // Calculate the new cost after the swap
    double newCost = calculateCost(currentPath);

    // Calculate the difference
    double costDifference = newCost - currentCost;

    // Decide whether to accept the new path
    if (acceptanceProbability(costDifference, temperature) >
        ((double)rand() / RAND_MAX)) {

      // Accept the new path
      currentCost = newCost;

      // Update best path
      if (currentCost < bestCost) {
        bestPath = currentPath;
        bestCost = currentCost;
      }
    } else {
      // Revert the swap (reverse the segment back)
      reverse(currentPath.begin() + i, currentPath.begin() + j + 1);
    }

    temperature *= coolingRate;
  }
}

vector<int> SimulatedAnnealing::calculateRandomPath() {
  // Initialize a sequential path
  vector<int> randomPath;
  for (int i = 0; i < pathSize; ++i) {
    randomPath.push_back(i);
  }

  // Shuffle the path
  random_device rd;
  mt19937 g(rd());
  shuffle(randomPath.begin(), randomPath.end(), g);

  return randomPath;
}

void SimulatedAnnealing::saveOptimizedPath(const string filePath,
                                           bool appendBestCost) {
  // Optionally add the best cost to filename
  if (appendBestCost) {
    size_t dotPos = filePath.find_last_of('.');
    string newFilePath;
    if (dotPos != string::npos) {
      newFilePath = filePath.substr(0, dotPos) + "_cost_" +
                    to_string((int)bestCost) + filePath.substr(dotPos);
    } else {
      newFilePath = filePath + "_cost_" + to_string((int)bestCost);
    }
    return saveOptimizedPath(newFilePath, false);
  }

  // Save the best path to the specified file, expanding via predecessor table
  ofstream outFile(filePath);

  if (!outFile.is_open()) {
    cerr << "Error: Could not open file " << filePath << " for writing."
         << endl;
    throw runtime_error("Error writing to file: " + filePath);
  }

  // Expand the path using the predecessor table
  for (size_t i = 0; i < bestPath.size(); ++i) {
    int u = bestPath[i];
    int v = bestPath[(i + 1) % bestPath.size()];

    if (i == 0) {
      outFile << u << endl;
    }

    vector<int> segment;
    int curr = v;

    while (curr != u) {
      segment.push_back(curr);
      curr = graph.predecessorTable[u][curr];

      if (curr == UINT16_MAX) {
        cerr << "Error: No path found between " << u << " and " << v << endl;
        break;
      }
    }

    for (auto it = segment.rbegin(); it != segment.rend(); ++it) {
      outFile << *it << endl;
    }
  }

  outFile.close();
}