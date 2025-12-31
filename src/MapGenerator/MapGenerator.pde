/**
 * Map Generator
 * * INTERACTION:
 * - Mouse Click: Toggle cell state (Empty -> Tile -> Obstacle -> Empty)
 * - Spacebar: Export adjacency list to "map.txt" file
 * - O: Open a map txt file
 */

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
  size(1101, 701); 
  
  // Calculate window size based on grid dimensions
  int windowWidth = cols * cellSize;
  int windowHeight = rows * cellSize;
  windowResize(windowWidth, windowHeight);
  grid = new int[cols][rows];
  
  // Set initial text align for UI feedback
  textAlign(CENTER, CENTER);
  textSize(16);
  surface.setTitle("Map Generator - Click or Drag to generate a map - Press SPACE to save - Press O to open a map txt file");
}

void draw() {
  background(240);
  strokeCap(SQUARE);
  
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      int x = i * cellSize;
      int y = j * cellSize;
      
      int state = grid[i][j];
      
      if (state == EMPTY) {
        fill(255);
        stroke(224);
        strokeWeight(1);
        rect(x, y, cellSize, cellSize);
      } 
      else if (state == OBSTACLE) {
        fill(0);
        stroke(224);
        strokeWeight(1);
        rect(x, y, cellSize, cellSize);
      } 
      else if (state == TILE) {
        fill(220);
        stroke(200);
        strokeWeight(1);
        rect(x + 1, y + 1, cellSize - 2, cellSize - 2);
      }
    }
  }
}

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
