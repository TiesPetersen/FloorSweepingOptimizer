#pragma once

#include <string>
#include <vector>

using namespace std;

struct Point {
  int x;
  int y;
};

class Graph {
private:
  void readAdjMatrixFromFile(const string filePath);

  void buildDistanceTable();

public:
  int n;
  vector<vector<pair<int, int>>> adjMatrix;
  vector<vector<int>> distanceTable;
  vector<vector<int>> predecessorTable;

  // Coordinates of the nodes (index matches node ID)
  vector<Point> nodeCoordinates;

  Graph(string filePath);

  // Function to load node coordinates from map.txt
  void loadMap(const string filePath);

  void addEdge(int from, int to, int weight);

  void printAdjMatrix();

  void printDistanceTable();
};