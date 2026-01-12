# FloorSweepingOptimizer

A C++ optimizer that generates efficient floor sweeping routes on grid maps with obstacles using simulated annealing.

Blog post with more details, visualizations and gifs: [Link to Blog Post](https://open.substack.com/pub/tiespetersen/p/i-got-paid-minimum-wage-to-solve?r=58fv3v&utm_campaign=post&utm_medium=web&showWelcomeOnShare=true)

![Optimized path](/assets/PathB/PathB_optimized.gif)
*An example of one of the optimized paths.*

![Simulated annealing at work](/assets/SimulatedAnnealingAtWorkGIF/SimulatedAnnealingAtWorkGIF_optimized.gif)
*Simulated annealing slowly optimizing the path over many iterations.*

## Project Overview

The FloorSweepingOptimizer consists of 3 parts:

1.  **MapGenerator** (`/src/MapGenerator`)
    Interactively design grid maps with obstacles. Exports `map.txt` (coordinates) and `adjacency_list.txt` (graph weights).

2.  **PathOptimizer** (`/src/PathOptimizer`)
    A C++ application that calculates the most efficient route to visit every tile using Simulated Annealing. It minimizes travel distance and turns.

3.  **PathVisualizer** (`/src/PathVisualizer`)
    Visualizes the resulting path on the map with animation and density indicators.



## 1. MapGenerator

**Environment:** Processing (Java)

### How to use
1.  Open the file in the Processing IDE and run it.
2.  **Mouse Click/Drag:** Toggle cells between Empty, Obstacle (Bordered), and Tile (Filled).
3.  **Spacebar:** Save `map.txt` and `adjacency_list.txt` to the sketch folder.
4.  **Key 'O':** Open an existing map file to edit.

## 2. PathOptimizer

**Environment:** C++ (v23)

### Configuration
Adjust the following parameters in `main.cpp` before compiling:
* **Iterations:** Total optimization steps.
* **AngleWeight:** Cost penalty for turning. Higher values result in straighter paths.
* **Temperature:** Start and end temperatures control the annealing schedule.

### How to run
1.  Ensure `map.txt` and `adjacency_list.txt` are in the working directory.
2.  Update the filenames in `main.cpp` if necessary.
3.  Compile and run the C++ project.
    ```bash
    g++ main.cpp Graph.cpp SimulatedAnnealing.cpp -o optimizer
    ./optimizer
    ```
4.  The program outputs a `path.txt` file containing the optimized node sequence.

## 3. PathVisualizer

**Environment:** Processing (Java)

### How to use
1.  Open the file in Processing and run it.
2.  Select `map.txt` when prompted.
3.  Select `path.txt` when prompted.
4.  The visualization animates automatically.

### Controls
* **Key 'T':** Toggle path transparency. Useful for seeing high-traffic areas (darker lines indicate more overlaps).
* **Key 'Q':** Save a screenshot.



## File Formatting

### Map file (`map.txt`)
Contains coordinate definitions in two sections separated by an empty line.
1.  **Obstacles:** `x y` coordinates.
2.  **Tiles:** `x y` coordinates (these correspond to Node IDs sequentially).

```text
0 0
0 1
...
(empty line)
1 1
1 2
...

```

### Adjacency List (`adjacency_list.txt`)

Defines the graph structure. Each block represents a node's neighbors. Blocks are separated by empty lines.

* **Format:** `NeighborID Weight`
* **Weights:** Straight = 100, Diagonal = 141.

```text
1 100
4 141

0 100
2 100
5 141

...

```

### Path file (`path.txt`)

An ordered list of Node IDs representing the sequence of the path.

```text
0
1
2
5
...

```

## Note

This project can be extended to work on generic graphs. The optimizer functions on any valid adjacency list and does not strictly require a grid structure, provided the `map.txt` (used for angle calculation) format matches the node indices.
