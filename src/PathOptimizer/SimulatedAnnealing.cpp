#include "SimulatedAnnealing.hpp"

#include <algorithm>
#include <cmath> // For exp
#include <fstream>
#include <iostream>
#include <random>

using namespace std;

double SimulatedAnnealing::acceptanceProbability(double distanceDifference,
                                                 double temperature) {
  // If the new distance is better (difference < 0), always accept (return 1.0).
  if (distanceDifference < 0) {
    return 1.0;
  }
  // Otherwise, accept with probability exp(-delta / temperature).
  return exp(-distanceDifference / temperature);
}

int SimulatedAnnealing::calculateCost(const vector<int> &path) {
  int totalDistance = 0;
  for (size_t i = 0; i < path.size() - 1; ++i) {
    int from = path[i];
    int to = path[i + 1];
    totalDistance += graph.distanceTable[from][to];
  }
  // Close the loop
  totalDistance += graph.distanceTable[path.back()][path[0]];

  return totalDistance;
}

SimulatedAnnealing::SimulatedAnnealing(const Graph &graph,
                                       double initialTemperature,
                                       double finalTemperature,
                                       long long iterations)
    : graph(graph), initialTemperature(initialTemperature),
      finalTemperature(finalTemperature), iterations(iterations) {
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
      printf("Iteration %lld/%lld (%.0f%%), Temp: %.2f, Curr: %d, Best: "
             "%d\n",
             iter, iterations, (100.0 * iter) / iterations, temperature,
             currentCost, bestCost);
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

    // Calculate the new distance after the swap
    int newCost = calculateCost(currentPath);

    // Calculate the distance difference
    int costDifference = newCost - currentCost;

    // Decide whether to accept the new path
    if (acceptanceProbability(costDifference, temperature) >
        ((double)rand() / RAND_MAX)) {

      // Accept the new path (Reverse the segment)
      // The segment was already reversed above, so no need to reverse again
      // here.

      // Update cost
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
  vector<int> randomPath;
  for (int i = 0; i < pathSize; ++i) {
    randomPath.push_back(i);
  }
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
                    to_string(bestCost) + filePath.substr(dotPos);
    } else {
      newFilePath = filePath + "_cost_" + to_string(bestCost);
    }
    return saveOptimizedPath(newFilePath, false);
  }

  ofstream outFile(filePath);

  if (!outFile.is_open()) {
    cerr << "Error: Could not open file " << filePath << " for writing."
         << endl;
    throw runtime_error("Error writing to file: " + filePath);
  }

  if (bestPath.empty()) {
    outFile.close();
    return;
  }

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