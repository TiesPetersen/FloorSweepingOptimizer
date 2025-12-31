/**
 * Path Visualizer (Dark Mode - Merged Obstacles)
 * 1. Loads Map -> Reconstructs Nodes.
 * 2. Loads Path -> Calculates Density.
 * 3. Animates the path step-by-step.
 */

import java.util.*; 

// --- CONFIGURATION ---
int cols = 46;
int rows = 30;
int cellSize = 25; 

// Data Structures
int[][] grid;
ArrayList<PVector> nodePositions; 
ArrayList<Integer> pathIDs;

// --- ANIMATION VARIABLES ---
int pathProgress = 0;      // How many steps have we drawn so far?
int speedDelay = 1;        // Higher = Slower. 1 = Fast, 10 = Slow.
int pathProgressPerCycle = 100;

// Holds the highest traffic count on any single edge
int maxOverlaps = 1;

// Constants
final int EMPTY = 0;
final int OBSTACLE = 1;
final int TILE = 2;

// State flags for loading text
boolean mapLoaded = false;
boolean pathLoaded = false;

boolean pathTransparaceny = false;

void setup() {
  // Initial size matching your original ratio
  size(1101, 701);
  frameRate(60);
  
  // Resize logic to fit grid exactly
  int windowWidth = cols * cellSize;
  int windowHeight = rows * cellSize;
  windowResize(windowWidth, windowHeight);
  
  // Initialize grid and lists
  grid = new int[cols][rows];
  nodePositions = new ArrayList<PVector>();
  pathIDs = new ArrayList<Integer>();

  // Initialize grid to empty
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      grid[i][j] = EMPTY;
    }
  }

  textAlign(CENTER, CENTER);
  textSize(16);
  surface.setTitle("Path Visualizer - Waiting for Input...");
  
  selectInput("Select the map txt file (map.txt):", "mapFileSelected");
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
      
      if (grid[i][j] == TILE) {
        // Tile: Dark fill with grey border
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
      
      if (grid[i][j] == OBSTACLE) {
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
  
  // 4. Draw Graph Nodes (Background white dots for valid tiles)
  if (mapLoaded) {
    noStroke();
    fill(255); // White dots
    for (PVector pos : nodePositions) {
      ellipse(pos.x, pos.y, 7, 7); // Using center position
    }
  }

  // 5. Draw Path (Animated)
  if (pathLoaded && pathIDs.size() > 1 && nodePositions.size() > 0) {
    
    // --- ANIMATION UPDATE LOGIC ---
    if (frameCount % speedDelay == 0) {
      if (pathProgress < pathIDs.size() - 1) {
        pathProgress += pathProgressPerCycle;
        if (pathProgress >= pathIDs.size()) {
          pathProgress = pathIDs.size() - 1;
        }
      }
    }
    
    // Calculate Alpha
    float pathAlpha;
    if (pathTransparaceny) {
      pathAlpha = 255 / sqrt(maxOverlaps);
      if (pathAlpha < 20) pathAlpha = 20;
    } else {
      pathAlpha = 255;
    }

    stroke(0, 209, 192, pathAlpha); 
    strokeWeight(2);
    noFill();
    
    // Draw from start ONLY up to the current 'pathProgress'
    for (int i = 0; i < pathProgress; i++) {
      int idCurrent = pathIDs.get(i);
      int idNext = pathIDs.get(i+1);
      
      if (isValidID(idCurrent) && isValidID(idNext)) {
        PVector p1 = nodePositions.get(idCurrent);
        PVector p2 = nodePositions.get(idNext);
        // Note: p1 and p2 are already centered in this version
        drawArrow(p1.x, p1.y, p2.x, p2.y);
      }
    }
  }
  
  // 6. Loading Text Feedback
  if (!mapLoaded) {
    fill(255);
    text("Please select map.txt...", width/2, height/2);
  } else if (!pathLoaded) {
    fill(255);
    text("Map Loaded. Please select path.txt...", width/2, height/2);
  }
}

boolean isValidID(int id) {
  return id >= 0 && id < nodePositions.size();
}

void drawArrow(float x1, float y1, float x2, float y2) {
  line(x1, y1, x2, y2);
  float angle = atan2(y2 - y1, x2 - x1);
  float arrowSize = 5; 
  pushMatrix();
  translate(x2, y2); 
  rotate(angle);     
  line(0, 0, -arrowSize, -arrowSize/2);
  line(0, 0, -arrowSize, arrowSize/2);
  popMatrix();
}

void drawEndPoint(int nodeID, int c) {
  if (isValidID(nodeID)) {
    PVector pos = nodePositions.get(nodeID);
    fill(c);
    noStroke();
    // pos is already centered
    ellipse(pos.x, pos.y, 10, 10);
  }
}

// --- FILE LOADING ---

void mapFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
    return;
  }
  loadMapFromFile(selection);
  reconstructNodeMapping();
  mapLoaded = true;
  surface.setTitle("Map Loaded. Select Path...");
  selectInput("Select the path txt file (path.txt):", "pathFileSelected");
}

void pathFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
    return;
  }
  loadPathFromFile(selection);
  calculateMaxOverlaps();
  
  pathLoaded = true;
  // RESET ANIMATION
  pathProgress = 0;
  surface.setTitle("Playing Path: " + pathIDs.size() + " steps");
}

void calculateMaxOverlaps() {
  HashMap<String, Integer> edgeCounts = new HashMap<String, Integer>();
  maxOverlaps = 1; 
  if (pathIDs.size() < 2) return;
  
  for (int i = 0; i < pathIDs.size() - 1; i++) {
    int u = pathIDs.get(i);
    int v = pathIDs.get(i+1);
    int sm = min(u, v);
    int lg = max(u, v);
    String key = sm + "-" + lg;
    
    int count = edgeCounts.getOrDefault(key, 0);
    count++;
    edgeCounts.put(key, count);
    
    if (count > maxOverlaps) maxOverlaps = count;
  }
  println("Max overlaps: " + maxOverlaps);
}

void loadMapFromFile(File file) {
  String[] lines = loadStrings(file.getAbsolutePath());
  if (lines == null) return;
  
  // Clear grid
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) grid[i][j] = EMPTY;
  }
  
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
      }
    }
  }
}

void reconstructNodeMapping() {
  nodePositions.clear();
  for (int j = 0; j < rows; j++) {
    for (int i = 0; i < cols; i++) {
      if (grid[i][j] == TILE) {
        // Store the CENTER of the cell to match the visual style
        float centerX = i * cellSize + cellSize/2.0;
        float centerY = j * cellSize + cellSize/2.0;
        nodePositions.add(new PVector(centerX, centerY));
      }
    }
  }
}

void loadPathFromFile(File file) {
  String[] lines = loadStrings(file.getAbsolutePath());
  pathIDs.clear();
  if (lines == null) return;
  for (String line : lines) {
    line = trim(line);
    if (line.length() > 0) {
      try { pathIDs.add(int(line)); } catch (Exception e) {}
    }
  }
}

void keyPressed() {
  if (key == 't'){
    pathTransparaceny = !pathTransparaceny;
    println("changing trans");
  } else if (key == 'q') {
    save("path_visualization.png");
    println("saving image");
  }
}
