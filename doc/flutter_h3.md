# Flutter H3 Documentation

Flutter H3 is a wrapper around Uber's H3 geospatial indexing system, providing easy access to H3's powerful functionality from within Flutter applications.

## Table of Contents
- [Installation](#installation)
- [Basic Concepts](#basic-concepts)
- [API Reference](#api-reference)
  - [Conversion Operations](#conversion-operations)
  - [Cell Inspection](#cell-inspection)
  - [Hierarchical Operations](#hierarchical-operations)
  - [Neighbor Operations](#neighbor-operations)
  - [Polygon Operations](#polygon-operations)
  - [Utility Functions](#utility-functions)
- [Practical Examples](#practical-examples)
- [Troubleshooting](#troubleshooting)

## Installation

Add flutter_h3 to your pubspec.yaml:

```yaml
dependencies:
  flutter_h3: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Basic Concepts

H3 is a geospatial indexing system that divides the Earth into hexagonal cells. Each cell has:

- A unique identifier (H3 index)
- A resolution level (0-15, where 0 is coarsest and 15 is finest)
- A center point (lat/lng)
- Boundary vertices

Understanding the following concepts will help you use this library effectively:

- **H3 Index**: A 64-bit integer that identifies a specific H3 cell
- **Resolution**: Determines the size of the cell, from 0 (largest) to 15 (smallest)
- **Lat/Lng**: Coordinates in decimal degrees (not radians)
- **k-ring**: The set of cells at a specified grid distance from an origin cell

## API Reference

### Conversion Operations

#### `latLngToCell(double lat, double lng, int resolution)`
Converts a lat/lng point to an H3 cell index.

```dart
// Convert a location to an H3 index at resolution 10
int h3Index = FlutterH3.latLngToCell(51.5074, -0.1278, 10); // London
```

#### `cellToLatLng(int h3Index)`
Converts an H3 index to its center point coordinates.

```dart
// Get the center coordinates of an H3 cell
Map<String, double> center = FlutterH3.cellToLatLng(h3Index);
print('Center: ${center['lat']}, ${center['lng']}');
```

#### `cellToBoundary(int h3Index)`
Gets the boundary of an H3 cell as a list of lat/lng points.

```dart
// Get the boundary vertices of an H3 cell
List<Map<String, double>> boundary = FlutterH3.cellToBoundary(h3Index);
for (var vertex in boundary) {
  print('Vertex: ${vertex['lat']}, ${vertex['lng']}');
}
```

### Cell Inspection

#### `isValidCell(int h3Index)`
Checks if an H3 index represents a valid cell.

```dart
// Check if an H3 index is valid
bool isValid = FlutterH3.isValidCell(h3Index);
if (isValid) {
  print('H3 index is valid');
} else {
  print('H3 index is not valid');
}
```

#### `getResolution(int h3Index)`
Gets the resolution of an H3 index.

```dart
// Get the resolution of an H3 cell
int resolution = FlutterH3.getResolution(h3Index);
print('Cell resolution: $resolution');
```

### Hierarchical Operations

#### `cellToParent(int h3Index, int parentRes)`
Gets the parent cell at a given resolution.

```dart
// Get the parent cell at resolution 9 (assuming h3Index is at resolution 10)
int parentIndex = FlutterH3.cellToParent(h3Index, 9);
print('Parent H3 index: ${FlutterH3.h3ToString(parentIndex)}');
```

#### `cellToChildren(int h3Index, int childRes)`
Gets all child cells at a given resolution.

```dart
// Get all child cells at resolution 11 (assuming h3Index is at resolution 10)
List<int> children = FlutterH3.cellToChildren(h3Index, 11);
print('Number of children: ${children.length}');

// Display the first few children
for (var child in children.take(5)) {
  print('Child H3 index: ${FlutterH3.h3ToString(child)}');
}
```

### Neighbor Operations

#### `gridDisk(int h3Index, int k)`
Gets all cells within k distance of the origin cell.

```dart
// Get all cells within distance 1 (immediate neighbors)
List<int> neighbors = FlutterH3.gridDisk(h3Index, 1);
print('Number of cells in 1-ring: ${neighbors.length}');

// Get all cells within distance 2
List<int> twoRing = FlutterH3.gridDisk(h3Index, 2);
print('Number of cells in 2-ring: ${twoRing.length}');
```

#### `areNeighborCells(int origin, int destination)`
Checks if two cells are neighbors.

```dart
// Check if two cells are neighbors
bool areNeighbors = FlutterH3.areNeighborCells(h3Index1, h3Index2);
if (areNeighbors) {
  print('Cells are neighbors');
} else {
  print('Cells are not neighbors');
}
```

### Polygon Operations

#### `polygonToCells(List<List<double>> polygon, List<List<List<double>>>? holes, int resolution)`
Converts a polygon to a set of H3 cells.

```dart
// Define a polygon (first and last points must be the same to close the polygon)
List<List<double>> polygon = [
  [51.51, -0.12], // lat, lng
  [51.52, -0.11],
  [51.52, -0.13],
  [51.51, -0.12], // closing point
];

// Optional: Define holes in the polygon
List<List<List<double>>> holes = [
  [
    [51.515, -0.125],
    [51.518, -0.12],
    [51.518, -0.13],
    [51.515, -0.125],
  ]
];

// Convert polygon to H3 cells at resolution 11
List<int> cells = FlutterH3.polygonToCells(polygon, holes, 11);
print('Found ${cells.length} cells covering the polygon');
```

#### `polygonToCellsExperimental(List<List<double>> polygon, List<List<List<double>>>? holes, int resolution, int flags)`
Experimental version of polygonToCells with different containment algorithms.

```dart
// Use the default algorithm (cell center point)
List<int> cellsDefault = FlutterH3.polygonToCellsExperimental(polygon, holes, 11, 0);

// Use the full cell containment algorithm (more accurate but slower)
List<int> cellsFullyContained = FlutterH3.polygonToCellsExperimental(polygon, holes, 11, 1);

// Use the algorithm that considers any overlap with the polygon
List<int> cellsOverlapping = FlutterH3.polygonToCellsExperimental(polygon, holes, 11, 2);

print('Default algorithm: ${cellsDefault.length} cells');
print('Full containment algorithm: ${cellsFullyContained.length} cells');
print('Overlap algorithm: ${cellsOverlapping.length} cells');
```

### Utility Functions

#### `h3ToString(int h3Index)`
Converts an H3 index (integer) to its string representation.

```dart
// Convert an H3 index to a string
String h3String = FlutterH3.h3ToString(h3Index);
print('H3 string: $h3String');
```

#### `stringToH3(String h3Str)`
Converts a string representation to an H3 index (integer).

```dart
// Convert an H3 string to an index
int h3Index = FlutterH3.stringToH3('8a2a1072b59ffff');
print('H3 index: $h3Index');
```

## Practical Examples

### Creating a Map with H3 Grid Overlay

```dart
import 'package:flutter/material.dart';
import 'package:flutter_h3/flutter_h3.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class H3MapExample extends StatefulWidget {
  @override
  _H3MapExampleState createState() => _H3MapExampleState();
}

class _H3MapExampleState extends State<H3MapExample> {
  final center = LatLng(51.5074, -0.1278); // London
  final int resolution = 9;
  List<List<Map<String, double>>> hexagons = [];

  @override
  void initState() {
    super.initState();
    _generateHexagons();
  }

  void _generateHexagons() {
    // Get the central H3 cell
    final centerIndex = FlutterH3.latLngToCell(center.latitude, center.longitude, resolution);
    
    // Get a ring of cells around the center
    final cellIndices = FlutterH3.gridDisk(centerIndex, 4);
    
    // Get the boundaries of each cell
    hexagons = cellIndices.map((index) {
      return FlutterH3.cellToBoundary(index);
    }).toList();
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('H3 Grid Map')),
      body: FlutterMap(
        options: MapOptions(
          center: center,
          zoom: 11.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          // Draw each hexagon
          for (var hexagon in hexagons)
            PolygonLayer(
              polygons: [
                Polygon(
                  points: hexagon.map((vertex) => 
                    LatLng(vertex['lat']!, vertex['lng']!)
                  ).toList(),
                  color: Colors.blue.withOpacity(0.3),
                  borderColor: Colors.blue,
                  borderStrokeWidth: 1.0,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
```

### Analyzing Point Density with H3

```dart
import 'package:flutter_h3/flutter_h3.dart';

class DensityAnalyzer {
  // Analyze the density of points within H3 cells
  Map<int, int> analyzePointDensity(List<Map<String, double>> points, int resolution) {
    // Create a map to store counts for each H3 cell
    final Map<int, int> cellCounts = {};
    
    // Count points in each cell
    for (var point in points) {
      final h3Index = FlutterH3.latLngToCell(point['lat']!, point['lng']!, resolution);
      
      if (cellCounts.containsKey(h3Index)) {
        cellCounts[h3Index] = cellCounts[h3Index]! + 1;
      } else {
        cellCounts[h3Index] = 1;
      }
    }
    
    return cellCounts;
  }
  
  // Find hotspots (cells with point count above threshold)
  List<int> findHotspots(Map<int, int> densityMap, int threshold) {
    return densityMap.entries
      .where((entry) => entry.value >= threshold)
      .map((entry) => entry.key)
      .toList();
  }
}

// Usage example
void main() {
  // Sample location data (latitude, longitude)
  final points = [
    {'lat': 51.507, 'lng': -0.127},
    {'lat': 51.508, 'lng': -0.128},
    // ... more points
  ];
  
  final analyzer = DensityAnalyzer();
  final density = analyzer.analyzePointDensity(points, 10);
  final hotspots = analyzer.findHotspots(density, 5);
  
  print('Found ${hotspots.length} hotspots');
}
```

### Efficient Region Queries

```dart
import 'package:flutter_h3/flutter_h3.dart';

class RegionQuery {
  // Precompute and store H3 indices for locations
  final Map<String, int> _locationIndices = {};
  final int _resolution;
  
  RegionQuery(List<Map<String, dynamic>> locations, this._resolution) {
    // Precompute H3 indices for all locations
    for (var location in locations) {
      final h3Index = FlutterH3.latLngToCell(
        location['lat'], 
        location['lng'], 
        _resolution
      );
      
      _locationIndices[location['id']] = h3Index;
    }
  }
  
  // Find locations within a specific region (polygon)
  List<String> findLocationsInRegion(List<List<double>> polygon) {
    // Convert the polygon to H3 cells
    final regionCells = FlutterH3.polygonToCells(polygon, null, _resolution);
    
    // Find locations whose H3 index is in the region cells
    return _locationIndices.entries
      .where((entry) => regionCells.contains(entry.value))
      .map((entry) => entry.key)
      .toList();
  }
  
  // Find locations near a point using k-ring
  List<String> findLocationsNearby(double lat, double lng, int distance) {
    // Get the H3 index for the query point
    final centerIndex = FlutterH3.latLngToCell(lat, lng, _resolution);
    
    // Get all cells within the specified distance
    final nearbyCells = FlutterH3.gridDisk(centerIndex, distance);
    
    // Find locations whose H3 index is in the nearby cells
    return _locationIndices.entries
      .where((entry) => nearbyCells.contains(entry.value))
      .map((entry) => entry.key)
      .toList();
  }
}
```

## Troubleshooting

### Common Issues

1. **Library not found errors on iOS**:
   - Ensure the `libh3.a` file is in the correct location (`ios/Frameworks/`)
   - Check that your Podfile is properly configured
   - Try `flutter clean` and rebuild

2. **Crashes on Android**:
   - Verify that the `libh3.so` files are in the appropriate directories for each architecture
   - Check logcat for more detailed error messages

3. **No cells found when using polygonToCells**:
   - Verify the polygon is correctly formatted (first and last points should be the same)
   - Try a lower resolution (higher resolutions have smaller cells)
   - Check if the experimental version with different flags yields results

### H3 Function Return Values

- Most functions return specific data types as documented in the API reference
- Some functions may throw exceptions when invalid data is provided
- The error messages usually indicate what went wrong (invalid index, resolution out of range, etc.)

### Memory Management

Flutter H3 uses Dart FFI which requires proper memory management. However, this is handled internally by the library, so you typically don't need to worry about manual memory management.

If you're experiencing memory leaks or crashes related to memory, please report these issues on the GitHub page. 