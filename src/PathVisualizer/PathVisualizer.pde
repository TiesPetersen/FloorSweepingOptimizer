/**
 * Path Visualizer (Animated)
 * 1. Loads Map -> Reconstructs Nodes.
 * 2. Loads Path -> Calculates Density.
 * 3. Animates the path step-by-step.
 */

import java.util.*; 

int cols = 44;
int rows = 28;
int cellSize = 25; 
int[][] grid;

ArrayList<PVector> nodePositions; 
ArrayList<Integer> pathIDs;

// --- ANIMATION VARIABLES ---
int pathProgress = 0;      // How many steps have we drawn so far?
int speedDelay = 1;        // Higher = Slower. 1 = Fast, 10 = Slow.

// Holds the highest traffic count on any single edge
int maxOverlaps = 1;

final int EMPTY = 0;
final int OBSTACLE = 1;
final int TILE = 2;

void setup() {
  size(1101, 701);
  
  int windowWidth = cols * cellSize;
  int windowHeight = rows * cellSize;
  windowResize(windowWidth, windowHeight);
  
  grid = new int[cols][rows];
  nodePositions = new ArrayList<PVector>();
  pathIDs = new ArrayList<Integer>();

  textAlign(CENTER, CENTER);
  textSize(16);
  
  selectInput("Select the map txt file (map.txt):", "mapFileSelected");
}

void draw() {
  background(240);
  
  // 1. Draw Grid
  strokeWeight(1);
  stroke(200);
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      int x = i * cellSize;
      int y = j * cellSize;
      if (grid[i][j] == OBSTACLE) {
        fill(0);
        rect(x, y, cellSize, cellSize);
      } else if (grid[i][j] == TILE) {
        fill(255);
        rect(x, y, cellSize, cellSize);
      } else {
        fill(240);
        rect(x, y, cellSize, cellSize);
      }
    }
  }
  
  // 2. Draw Path (Animated)
  if (pathIDs.size() > 1 && nodePositions.size() > 0) {
    
    // --- ANIMATION UPDATE LOGIC ---
    // Only update every 'speedDelay' frames
    if (frameCount % speedDelay == 0) {
      if (pathProgress < pathIDs.size() - 1) {
        pathProgress++;
      }
    }
    
    // Calculate Alpha based on MAX density found in the whole file
    //float pathAlpha = 255.0 / (float)maxOverlaps;
    float pathAlpha = 255.0;
    if (pathAlpha < 20) pathAlpha = 20; // Minimum visibility

    stroke(255, 0, 0, pathAlpha); 
    strokeWeight(2);
    noFill();
    
    // Draw from start ONLY up to the current 'pathProgress'
    for (int i = 0; i < pathProgress; i++) {
      int idCurrent = pathIDs.get(i);
      int idNext = pathIDs.get(i+1);
      
      if (isValidID(idCurrent) && isValidID(idNext)) {
        PVector p1 = nodePositions.get(idCurrent);
        PVector p2 = nodePositions.get(idNext);
        drawArrow(p1.x + cellSize/2, p1.y + cellSize/2, p2.x + cellSize/2, p2.y + cellSize/2);
      }
    }
    
    // Draw Start Point (Green)
    drawEndPoint(pathIDs.get(0), color(0, 255, 0)); 
    
    // Draw "Head" of the path (Current Position) - Yellow
    if (pathProgress < pathIDs.size() - 1) {
       drawEndPoint(pathIDs.get(pathProgress), color(255, 200, 0)); 
    } else {
       // Only draw Blue End point when animation finishes
       drawEndPoint(pathIDs.get(pathIDs.size()-1), color(0, 0, 255)); 
    }
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
    ellipse(pos.x + cellSize/2, pos.y + cellSize/2, 10, 10);
  }
}

// --- FILE LOADING ---

void mapFileSelected(File selection) {
  if (selection == null) return;
  loadMapFromFile(selection);
  reconstructNodeMapping();
  selectInput("Select the path txt file (path.txt):", "pathFileSelected");
}

void pathFileSelected(File selection) {
  if (selection == null) return;
  loadPathFromFile(selection);
  calculateMaxOverlaps();
  
  // RESET ANIMATION
  pathProgress = 0;
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
      if (x >= 0 && x < cols && y >= 0 && y < rows) grid[x][y] = currentImportState;
    }
  }
  surface.setTitle("Map Loaded.");
}

void reconstructNodeMapping() {
  nodePositions.clear();
  for (int j = 0; j < rows; j++) {
    for (int i = 0; i < cols; i++) {
      if (grid[i][j] == TILE) {
        nodePositions.add(new PVector(i * cellSize, j * cellSize));
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
  surface.setTitle("Playing Path: " + pathIDs.size() + " steps");
}
