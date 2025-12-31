/**
 * Map Generator (Dark Mode Style)
 * * INTERACTION:
 * - Mouse Click: Toggle cell state (Empty -> Tile -> Obstacle -> Empty)
 * - Spacebar: Export adjacency list to "map.txt" file
 * - O: Open a map txt file
 */

import java.util.*;

int cols = 46;
int rows = 30;
int cellSize = 25; // Size of each square in pixels
int[][] grid;

// Variable to store the state we are applying during a drag
int paintState = -1; 

// States
final int EMPTY = 0;
final int OBSTACLE = 1;
final int TILE = 2;

void setup() {
  // --- RESIZE LOGIC (Matches Source Style) ---
  size(100, 100); // Initial placeholder size
  
  int windowWidth = cols * cellSize;
  int windowHeight = rows * cellSize;
  windowResize(windowWidth, windowHeight);
  
  grid = new int[cols][rows];
  
  // Set initial text align for UI feedback
  textAlign(CENTER, CENTER);
  textSize(16);
  surface.setTitle("Map Generator - Click/Drag to paint - SPACE to save - O to open");
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
      int state = grid[i][j];
      
      if (state == TILE) {
        fill(0);
        stroke(96);
        strokeWeight(1);
        rect(x, y, cellSize, cellSize);
        
        noStroke();
        fill(96);
        ellipse(x + cellSize/2, y + cellSize/2, 2, 2);
      } 
    }
  }
  
  // 3. Draw Obstacles
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      int x = i * cellSize;
      int y = j * cellSize;
      int state = grid[i][j];
      
      if (state == OBSTACLE) {
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
  
  // Note: EMPTY cells are left as background (black) with just the grid dots

}

// --- INTERACTION LOGIC (UNCHANGED) ---

void mousePressed() {
  // specific logic to ensure we click inside the grid
  int i = mouseX / cellSize;
  int j = mouseY / cellSize;
  
  if (i >= 0 && i < cols && j >= 0 && j < rows) {
    // Determine the target state based on the clicked cell
    // Cycle: 0 -> 1 -> 2 -> 0
    paintState = (grid[i][j] + 1) % 3;
    grid[i][j] = paintState;
  } else {
    paintState = -1; // Clicked outside, do nothing
  }
}

void mouseDragged() {
  int i = mouseX / cellSize;
  int j = mouseY / cellSize;
  
  // Apply the state determined in mousePressed to any cell we drag over
  if (i >= 0 && i < cols && j >= 0 && j < rows && paintState != -1) {
    grid[i][j] = paintState;
  }
}

void keyPressed() {
  if (key == ' ') {
    exportCoordinates();
  } else if (key == 'o' || key == 'O') {
    selectInput("Select a map file to load:", "fileSelected");
  }
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    loadMapFromFile(selection);
  }
}

void loadMapFromFile(File file) {
  String[] lines = loadStrings(file.getAbsolutePath());
  
  if (lines == null) return;

  // Clear current grid
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      grid[i][j] = EMPTY;
    }
  }

  // First section in file is OBSTACLE
  int currentImportState = OBSTACLE;
  
  for (String line : lines) {
    line = trim(line);
    
    // Empty line indicates switch from Bordered to Filled section
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
  
  surface.setTitle("Loaded grid from " + file.getName());
}

void exportCoordinates() {
  String adjFilename = "adjacency_list.txt";
  PrintWriter outputAdj = createWriter(adjFilename); 
  
  String mapFilename = "map.txt";
  PrintWriter outputMap = createWriter(mapFilename);

  // Array to map the absolute Grid ID to the new Sequential ID
  int[] nodeMapping = new int[cols * rows];
  for (int k = 0; k < nodeMapping.length; k++) nodeMapping[k] = -1;
  
  int listIdCounter = 0;
  
  // File 1: Generate Adjacency List (adjacency_list.txt)
  
  // 1. Assign Sequential IDs
  for (int j = 0; j < rows; j++) {
    for (int i = 0; i < cols; i++) {
      if (grid[i][j] == TILE) {
        int gridId = j * cols + i;
        nodeMapping[gridId] = listIdCounter;
        listIdCounter++;
      }
    }
  }
  
  // 2. Export Adjacency List
  int exportedNodes = 0;
  
  for (int j = 0; j < rows; j++) {
    for (int i = 0; i < cols; i++) {
      
      if (grid[i][j] == TILE) {
        
        // Check all 8 Neighbors
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            
            if (dx == 0 && dy == 0) continue;
            
            int nx = i + dx;
            int ny = j + dy;
            
            if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
              
              if (grid[nx][ny] == TILE) {
                
                boolean isDiagonal = (dx != 0 && dy != 0);
                int weight = isDiagonal ? 141 : 100;
                boolean validConnection = true;
                
                // Corner Cutting Logic
                if (isDiagonal) {
                  if (grid[i + dx][j] == OBSTACLE) validConnection = false;
                  if (grid[i][j + dy] == OBSTACLE) validConnection = false;
                }
                
                if (validConnection) {
                  int neighborGridId = ny * cols + nx;
                  int neighborListId = nodeMapping[neighborGridId];
                  outputAdj.println(neighborListId + " " + weight);
                }
              }
            }
          }
        }
        
        // Add an empty line to separate nodes
        outputAdj.println("");
        exportedNodes++;
      }
    }
  }
  
  // File 2: Generate Map File (map.txt)
  
  int obstacleCount = 0;
  int tileCount = 0;

  // 1. Export OBSTACLES
  for (int j = 0; j < rows; j++) {
    for (int i = 0; i < cols; i++) {
      if (grid[i][j] == OBSTACLE) {
        outputMap.println(i + " " + j);
        obstacleCount++;
      }
    }
  }
  
  // Separator (Empty Line)
  outputMap.println("");
  
  // 2. Export TILES
  for (int j = 0; j < rows; j++) {
    for (int i = 0; i < cols; i++) {
      if (grid[i][j] == TILE) {
        outputMap.println(i + " " + j);
        tileCount++;
      }
    }
  }

  outputAdj.flush(); 
  outputAdj.close(); 
  
  outputMap.flush();
  outputMap.close();
  
  println("Exported Adjacency List (" + exportedNodes + " nodes) to " + adjFilename);
  println("Exported Coordinates (" + tileCount + " tiles, " + obstacleCount + " obstacles) to " + mapFilename);
  
  surface.setTitle("Saved '" + adjFilename + "' and '" + mapFilename + "'");
}
