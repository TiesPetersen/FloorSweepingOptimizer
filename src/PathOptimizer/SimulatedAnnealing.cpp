#include "SimulatedAnnealing.hpp"

#include <fstream>
#include <iostream>
#include <random>

double SimulatedAnnealing::acceptanceProbability(double distanceDifference,
                                                 double temperature) {
  if (distanceDifference < 0) {
    return 1.0;
  }
  return exp(-distanceDifference / temperature);
}

double SimulatedAnnealing::calculatePathDistance(const vector<uint16_t> &path) {
  double totalDistance = 0.0;
  for (size_t i = 0; i < path.size() - 1; ++i) {
    uint16_t from = path[i];
    uint16_t to = path[i + 1];
    totalDistance += graph.distanceTable[from][to];
  }

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
  currentDistance = calculatePathDistance(currentPath);
  bestPath = currentPath;
  bestDistance = currentDistance;
}

void SimulatedAnnealing::optimize() {
  double temperature = initialTemperature;
  double coolingRate =
      pow(finalTemperature / initialTemperature, 1.0 / iterations);

  for (long long iter = 0; iter < iterations; ++iter) {
    // Log progress every 10% of iterations
    if (iter % (iterations / 10) == 0) {
      printf("Iteration %lld/%lld (%.0f%%), Temperature: %.2f, Current "
             "Distance: %.2f, Best "
             "Distance: %.2f\n",
             iter, iterations, (100.0 * iter) / iterations, temperature,
             currentDistance, bestDistance);
    }

    // Pick two random nodes to swap
    size_t i = rand() % pathSize;
    size_t j = rand() % pathSize;
    while (j == i) {
      j = rand() % pathSize;
    }
    swap(currentPath[i], currentPath[j]);

    // Calculate the new distance
    double newDistance = calculatePathDistance(currentPath);
    double distanceDifference = newDistance - currentDistance;

    if (acceptanceProbability(distanceDifference, temperature) >
        ((double)rand() / RAND_MAX)) {
      // Accept the new path
      currentDistance = newDistance;

      // Update best path found
      if (currentDistance < bestDistance) {
        bestPath = currentPath;
        bestDistance = currentDistance;
      }
    } else {
      // Revert the swap
      swap(currentPath[i], currentPath[j]);
    }

    temperature *= coolingRate;
  }
}

vector<uint16_t> SimulatedAnnealing::calculateRandomPath() {
  vector<uint16_t> randomPath;
  for (uint16_t i = 0; i < pathSize; ++i) {
    randomPath.push_back(i);
  }
  random_device rd;
  mt19937 g(rd());
  shuffle(randomPath.begin(), randomPath.end(), g);
  return randomPath;
}

void SimulatedAnnealing::saveOptimizedPath(const string filePath) {
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

  // Iterate through the bestPath sequence to reconstruct the full journey
  for (size_t i = 0; i < bestPath.size(); ++i) {
    uint16_t u = bestPath[i];
    uint16_t v =
        bestPath[(i + 1) % bestPath.size()]; // Wrap around to close the loop

    // If it's the very first node of the tour, write it to the file
    if (i == 0) {
      outFile << u << endl;
    }

    // Reconstruct the path from u to v using the predecessor table
    // We backtrack from v to u
    vector<uint16_t> segment;
    uint16_t curr = v;

    while (curr != u) {
      segment.push_back(curr);
      curr = graph.predecessorTable[u][curr];

      // Safety check: if the graph is disconnected or logic fails
      if (curr == UINT16_MAX) {
        cerr << "Error: No path found between " << u << " and " << v << endl;
        break;
      }
    }

    // The segment vector now contains [v, prev(v), ..., node_after_u]
    // We need to write this in reverse order: node_after_u -> ... -> v
    // Note: We do not write 'u' here because it was written in the previous
    // iteration (or the initial check if i==0)
    for (auto it = segment.rbegin(); it != segment.rend(); ++it) {
      outFile << *it << endl;
    }
  }

  outFile.close();
}