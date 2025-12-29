#pragma once

#include <string>
#include <vector>

using namespace std;

class Graph {
private:
  void readAdjMatrixFromFile(const string filePath);

  void buildDistanceTable();

public:
  int n;
  vector<vector<pair<int, int>>> adjMatrix;
  vector<vector<int>> distanceTable;
  vector<vector<int>> predecessorTable;

  Graph(string filePath);

  void addEdge(int from, int to, int weight);

  void printAdjMatrix();

  void printDistanceTable();
};