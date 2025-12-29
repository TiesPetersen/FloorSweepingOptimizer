#pragma once

#include <cstdint>
#include <string>
#include <vector>

using namespace std;

class Graph {
private:
  void readAdjMatrixFromFile(const string filePath);

  void buildDistanceTable();

public:
  uint16_t n;
  vector<vector<pair<uint16_t, uint8_t>>> adjMatrix;
  vector<vector<uint32_t>> distanceTable;
  vector<vector<uint16_t>> predecessorTable;

  Graph(string filePath);

  void addEdge(uint16_t from, uint16_t to, uint8_t weight);

  void printAdjMatrix();

  void printDistanceTable();
};