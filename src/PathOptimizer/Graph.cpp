#include "Graph.hpp"
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <utility>

void Graph::readAdjMatrixFromFile(const string filePath) {
  // Open the file
  ifstream file(filePath);

  if (!file.is_open()) {
    cerr << "Error opening file: " << filePath << endl;
    throw runtime_error("Error opening file: " + filePath);
  }

  // Read the adjacency matrix from the file
  string line;
  vector<std::pair<uint16_t, uint8_t>> current_neighbors;

  while (getline(file, line)) {
    if (line.empty()) {
      // Empty line indicates new node
      adjMatrix.push_back(current_neighbors);
      current_neighbors.clear();
    } else {
      // Parse neighbor and weight
      stringstream ss(line);
      uint16_t neighbor_id;
      int weight_int;

      if (ss >> neighbor_id >> weight_int) {
        uint8_t weight = static_cast<uint8_t>(weight_int);
        current_neighbors.push_back({neighbor_id, weight});
      }
    }
  }

  n = adjMatrix.size();
}

void Graph::buildDistanceTable() {
  // Initialize the distance table with maximum distances
  distanceTable.resize(n);
  for (size_t i = 0; i < n; ++i) {
    distanceTable[i].resize(n, UINT16_MAX);
    distanceTable[i][i] = 0;

    // Initialize direct neighbor distances
    for (const auto &neighbor : adjMatrix[i]) {
      distanceTable[i][neighbor.first] = neighbor.second;
    }
  }

  // Initialize the predecessor table
  predecessorTable.resize(n);
  for (size_t i = 0; i < n; ++i) {
    predecessorTable[i].resize(n, UINT16_MAX);
    for (const auto &neighbor : adjMatrix[i]) {
      predecessorTable[i][neighbor.first] = i;
    }
  }

  // Run Floyd-Warshall algorithm to compute shortest paths
  for (size_t k = 0; k < n; ++k) {
    for (size_t i = 0; i < n; ++i) {
      for (const auto &neighbor : adjMatrix[i]) {

        // Skip if there's no path from i to k
        if (distanceTable[i][k] == UINT16_MAX)
          continue;

        for (size_t j = 0; j < n; ++j) {
          // Skip if there's no path from k to j
          if (distanceTable[k][j] == UINT16_MAX)
            continue;

          // Update the distance if a shorter path is found
          uint32_t new_distance = distanceTable[i][k] + distanceTable[k][j];
          if (new_distance < distanceTable[i][j]) {
            distanceTable[i][j] = new_distance;
            predecessorTable[i][j] = predecessorTable[k][j];
          }
        }
      }
    }
  }
}

Graph::Graph(string filePath) {
  // Initialize the graph by reading the adjacency matrix from a file
  readAdjMatrixFromFile(filePath);

  // Build the distance table for during path optimization
  buildDistanceTable();
}

void Graph::addEdge(uint16_t from, uint16_t to, uint8_t weight) {
  // Ensure the adjacency matrix is large enough
  if (adjMatrix.size() <= from) {
    adjMatrix.resize(from + 1);
  }

  // Ensure the 'to' node exists
  if (adjMatrix.size() <= to) {
    adjMatrix.resize(to + 1);
  }

  // Add the edge
  adjMatrix[from].push_back(make_pair(to, weight));
}

void Graph::printAdjMatrix() {
  // Print the adjacency matrix for debugging

  for (size_t i = 0; i < adjMatrix.size(); ++i) {
    cout << "Node " << i << ": ";
    for (const auto &neighbor : adjMatrix[i]) {
      cout << "(" << neighbor.first << ", " << static_cast<int>(neighbor.second)
           << ") ";
    }
    cout << endl;
  }
}

void Graph::printDistanceTable() {
  // Print the distance table for debugging

  cout << "Distance Table:" << endl;
  for (size_t i = 0; i < distanceTable.size(); ++i) {
    for (size_t j = 0; j < distanceTable[i].size(); ++j) {
      if (distanceTable[i][j] == UINT16_MAX) {
        cout << "INF ";
      } else {
        cout << distanceTable[i][j] << " ";
      }
    }
    cout << endl;
  }
}