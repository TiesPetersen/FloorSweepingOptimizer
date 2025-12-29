/**
 * Map Generator
 * * INTERACTION:
 * - Mouse Click: Toggle cell state (Empty -> Tile -> Obstacle -> Empty)
 * - Spacebar: Export adjacency list to "map.txt" file
 * - O: Open a map txt file
 */

int cols = 44;
int rows = 28;
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
        fill(255);
        stroke(0);
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
    loadGridFromFile(selection);
  }
}

void loadGridFromFile(File file) {
  String[] lines = loadStrings(file.getAbsolutePath());
  
  if (lines == null) return;

  // Clear current grid
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      grid[i][j] = EMPTY;
    }
  }

  // First section in file is BORDERED
  int currentImportState = TILE;
  
  for (String line : lines) {
    line = trim(line);
    
    // Empty line indicates switch from Bordered to Filled section
    if (line.length() == 0) {
      currentImportState = OBSTACLE;
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
  // creates a file in the sketch directory
  PrintWriter output = createWriter("map.txt"); 
  
  int borderedCount = 0;
  int filledCount = 0;
  
  // 1. Export Bordered Squares
  for (int j = 0; j < rows; j++) {
    for (int i = 0; i < cols; i++) {
      if (grid[i][j] == TILE) {
        // Format: x y
        output.println(i + " " + j);
        borderedCount++;
      }
    }
  }
  
  // Add empty newline between sections
  output.println("");
  
  // 2. Export Filled (Black) Squares
  for (int j = 0; j < rows; j++) {
    for (int i = 0; i < cols; i++) {
      if (grid[i][j] == OBSTACLE) {
        // Format: x y
        output.println(i + " " + j);
        filledCount++;
      }
    }
  }
  
  output.flush(); // Write remaining data
  output.close(); // Finish file
  
  println("Exported " + borderedCount + " bordered and " + filledCount + " filled squares to tiles.txt");
  surface.setTitle("Saved to 'map.txt' successfully");
}
