#include "Graph.hpp"
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <utility>

using namespace std;

void Graph::readAdjMatrixFromFile(const string filePath) {
  // Open the file
  ifstream file(filePath);

  if (!file.is_open()) {
    cerr << "Error opening file: " << filePath << endl;
    throw runtime_error("Error opening file: " + filePath);
  }

  // Read the adjacency matrix from the file
  string line;
  vector<pair<int, int>> current_neighbors;

  while (getline(file, line)) {
    if (line.empty()) {
      // Empty line indicates new node (or end of previous node's list)
      // Note: The logic here assumes the file ends with an empty line or the
      // loop handles the push correctly. Based on MapGenerator, it prints
      // neighbors then an empty line.
      adjMatrix.push_back(current_neighbors);
      current_neighbors.clear();
    } else {
      // Parse neighbor and weight
      stringstream ss(line);
      int neighbor_id;
      int weight;

      if (ss >> neighbor_id >> weight) {
        current_neighbors.push_back({neighbor_id, weight});
      }
    }
  }

  // Handle case where file might not end with empty line but data exists
  if (!current_neighbors.empty()) {
    adjMatrix.push_back(current_neighbors);
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
          int new_distance = distanceTable[i][k] + distanceTable[k][j];
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

void Graph::loadMap(const string filePath) {
  ifstream file(filePath);
  if (!file.is_open()) {
    cerr << "Error opening map file: " << filePath << endl;
    return;
  }

  string line;
  bool readingTiles = false;
  nodeCoordinates.clear();

  // The map file structure:
  // 1. Obstacles (x y)
  // 2. Empty Line
  // 3. Tiles (x y)
  // We only care about tiles, and their order must match the adjacency list
  // IDs.

  while (getline(file, line)) {
    // Trim whitespace from line for robust checking
    size_t first = line.find_first_not_of(" \t\r\n");
    size_t last = line.find_last_not_of(" \t\r\n");
    if (first == string::npos) {
      // Empty line found
      readingTiles = true;
      continue;
    }

    if (readingTiles) {
      stringstream ss(line);
      int x, y;
      if (ss >> x >> y) {
        nodeCoordinates.push_back({x, y});
      }
    }
  }

  if (nodeCoordinates.size() != n) {
    cerr << "Warning: Number of tiles in map.txt (" << nodeCoordinates.size()
         << ") does not match number of nodes in graph (" << n << ")." << endl;
  } else {
    cout << "Loaded " << nodeCoordinates.size() << " node coordinates." << endl;
  }
}

void Graph::addEdge(int from, int to, int weight) {
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