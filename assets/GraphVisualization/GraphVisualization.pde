/**
 * Graph Visualizer (Dark Mode - Merged Obstacles)
 * 1. Loads "map.txt" to determine node positions (Tiles).
 * 2. Loads "adjacency_list.txt" to draw the graph edges.
 * 3. Overlays the graph on the map.
 */

import java.util.*; 

// --- CONFIGURATION ---
int cols = 46; 
int rows = 30; 
int cellSize = 25; 

// Data Structures
int[][] grid;
ArrayList<PVector> nodePositions; // Index = Node ID, Value = Screen Position
ArrayList<Edge> edges;            // List of all connections to draw

// State
boolean mapLoaded = false;
boolean graphLoaded = false;
int drawMode = 0;
// 0 -> obstacles
// 1 -> obstacles + tiles
// 2 -> obstacles + tiles + dots
// 3 -> obstacles + dots + edges
// 4 -> dots + edges

// Constants
final int EMPTY = 0;
final int OBSTACLE = 1;
final int TILE = 2;

class Edge {
  int from;
  int to;
  int weight;
  
  Edge(int f, int t, int w) {
    from = f;
    to = t;
    weight = w;
  }
}

void setup() {
  // Initial size, will be resized immediately below
  size(100, 100);
  
  // --- RESIZE LOGIC ---
  int windowWidth = cols * cellSize;
  int windowHeight = rows * cellSize;
  windowResize(windowWidth, windowHeight);
  
  // Initialize grid and lists
  grid = new int[cols][rows];
  nodePositions = new ArrayList<PVector>();
  edges = new ArrayList<Edge>();
  
  // Initialize grid to empty
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      grid[i][j] = EMPTY;
    }
  }

  textAlign(CENTER, CENTER);
  textSize(16);
  surface.setTitle("Graph Visualizer - Waiting for Input...");
  
  // Start the loading chain
  selectInput("Step 1: Select the map file (map.txt):", "mapFileSelected");
}

void draw() {
  background(0); // Completely black background
  
  // 1. Draw Grid Dots (Dark Grey on corners)
  stroke(48);
  strokeWeight(2);
  for (int i = 1; i <= cols; i++) {
    for (int j = 1; j <= rows; j++) {
      point(i * cellSize, j * cellSize);
    }
  }
  
  // 2. Draw Tiles
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      int x = i * cellSize;
      int y = j * cellSize;
      
      if (grid[i][j] == TILE && (drawMode == 1 || drawMode == 2)) {
        // Tile:
        fill(0);
        stroke(96);
        strokeWeight(1);
        rect(x, y, cellSize, cellSize);
      } 
    }
  }
  
  // 3. Draw Obstacles (With Merged Borders)
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      int x = i * cellSize;
      int y = j * cellSize;
      
      if (grid[i][j] == OBSTACLE && (drawMode != 4)) {
        // B. Draw White Borders ONLY if neighbor is NOT an obstacle
        stroke(255);
        strokeWeight(1);
        
        // Check Top
        if (j == 0 || grid[i][j-1] != OBSTACLE) {
          line(x, y, x + cellSize, y);
        }
        
        // Check Bottom
        if (j == rows - 1 || grid[i][j+1] != OBSTACLE) {
          line(x, y + cellSize, x + cellSize, y + cellSize);
        }
        
        // Check Left
        if (i == 0 || grid[i-1][j] != OBSTACLE) {
          line(x, y, x, y + cellSize);
        }
        
        // Check Right
        if (i == cols - 1 || grid[i+1][j] != OBSTACLE) {
          line(x + cellSize, y, x + cellSize, y + cellSize);
        }
      }
    }
  }
  
  // Empty cells are left as background (black) with just the grid dots

  // 4. Draw Graph Edges
  if (graphLoaded && mapLoaded && (drawMode == 3 || drawMode == 4)) {
    stroke(255, 70);
    strokeWeight(1);
    noFill();
    
    for (Edge e : edges) {
      if (e.from < nodePositions.size() && e.to < nodePositions.size()) {
        PVector p1 = nodePositions.get(e.from);
        PVector p2 = nodePositions.get(e.to);
        line(p1.x, p1.y, p2.x, p2.y);
      }
    }
  }
  
  // 5. Draw Graph Nodes
  if (mapLoaded && (drawMode == 2 ||drawMode == 3 || drawMode == 4)) {
    noStroke();
    fill(255); // White dots
    
    for (PVector pos : nodePositions) {
      ellipse(pos.x, pos.y, 7, 7);
    }
  }
  
  // 6. Loading Text Feedback
  if (!mapLoaded) {
    fill(255);
    text("Please select map.txt...", width/2, height/2);
  } else if (!graphLoaded) {
    fill(255);
    text("Map Loaded. Please select adjacency_list.txt...", width/2, height/2);
  }
}

// --- FILE LOADING HANDLERS ---

void mapFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
    return;
  }
  
  loadMapData(selection);
  mapLoaded = true;
  surface.setTitle("Map Loaded. Select Adjacency List...");
  
  // Chain the next input request
  selectInput("Step 2: Select the adjacency list (adjacency_list.txt):", "adjFileSelected");
}

void adjFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
    return;
  }
  
  loadAdjacencyData(selection);
  graphLoaded = true;
  surface.setTitle("Graph Visualizer - " + nodePositions.size() + " Nodes, " + edges.size() + " Edges");
}

// --- PARSING LOGIC ---

void loadMapData(File file) {
  String[] lines = loadStrings(file.getAbsolutePath());
  if (lines == null) return;
  
  // Clear lists
  nodePositions.clear();
  
  // Reset grid
  for(int i=0; i<cols; i++) for(int j=0; j<rows; j++) grid[i][j] = EMPTY;
  
  // The map.txt format:
  // Section 1: Obstacles (x y)
  // Empty Line
  // Section 2: Tiles (x y) -> These correspond to Node IDs 0, 1, 2...
  
  int currentImportState = OBSTACLE;
  
  for (String line : lines) {
    line = trim(line);
    
    if (line.length() == 0) {
      currentImportState = TILE;
      continue;
    }
    
    String[] parts = split(line, ' ');
    if (parts.length >= 2) {
      int x = int(parts[0]);
      int y = int(parts[1]);
      
      if (x >= 0 && x < cols && y >= 0 && y < rows) {
        grid[x][y] = currentImportState;
        
        // If we are reading the TILE section, this is a Node definition
        if (currentImportState == TILE) {
          // Calculate center of the cell for visualization
          float centerX = x * cellSize + cellSize/2.0;
          float centerY = y * cellSize + cellSize/2.0;
          nodePositions.add(new PVector(centerX, centerY));
        }
      }
    }
  }
  println("Map Loaded: " + nodePositions.size() + " nodes identified.");
}

void loadAdjacencyData(File file) {
  String[] lines = loadStrings(file.getAbsolutePath());
  if (lines == null) return;
  
  edges.clear();
  
  int currentNodeID = 0;
  
  // adjacency_list.txt format:
  // Blocks of lines representing neighbors for the current Node ID.
  // Blocks are separated by empty lines.
  
  for (String line : lines) {
    line = trim(line);
    
    if (line.length() == 0) {
      // Empty line means we are done with the current node and moving to the next
      currentNodeID++;
    } else {
      // Line contains: neighborID weight
      String[] parts = split(line, ' ');
      if (parts.length >= 2) {
        int neighborID = int(parts[0]);
        int weight = int(parts[1]);
        
        edges.add(new Edge(currentNodeID, neighborID, weight));
      }
    }
  }
  println("Graph Loaded: " + edges.size() + " edges parsed.");
}

void keyPressed() {
  if (key == 'd') {
    drawMode = (drawMode + 1) % 5;
    println("Changing drawing mode");
  } else if (key == 'q') {
    save("vis_" + drawMode + ".png");
    println("Saved image");
  }
}
