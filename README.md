# flutter_h3

A Flutter plugin that provides an FFI interface to [Uber's H3](https://h3geo.org/) geospatial indexing system. This plugin supports iOS and Android platforms.

## Features

- Convert latitude/longitude coordinates to H3 indices and vice versa
- Get boundary coordinates of an H3 cell
- Get surrounding cells (k-ring)
- Get parent cells at lower resolutions
- Get child cells at higher resolutions
- Convert a polygon to H3 cells (with optional holes)
- Experimental polygon-to-cells functions with different containment modes
- Check if cells are valid or neighbors
- Get H3 cell resolution
- Convert between string and integer H3 formats

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_h3: ^0.1.0
```

### Android Setup

Place the compiled H3 library file `libh3.so` in the appropriate directories:

- `android/src/main/jniLibs/arm64-v8a/libh3.so`
- `android/src/main/jniLibs/armeabi-v7a/libh3.so`
- `android/src/main/jniLibs/x86/libh3.so`
- `android/src/main/jniLibs/x86_64/libh3.so`

### iOS Setup

1. Add the `libh3.a` file to your project's `ios/Frameworks` directory.
2. Update your `ios/Podfile` to include:

```ruby
target 'Runner' do
  # ... existing code ...
  
  pod 'flutter_h3', :path => '.symlinks/plugins/flutter_h3/ios'
  
  # Add this line to link the static library
  pod 'h3', :podspec => '.symlinks/plugins/flutter_h3/ios/h3.podspec'
end
```

3. Create a file named `h3.podspec` in the `ios` directory of the plugin with:

```ruby
Pod::Spec.new do |s|
  s.name             = 'h3'
  s.version          = '0.1.0'
  s.summary          = 'H3 Core library'
  s.description      = 'H3 Core library for the flutter_h3 plugin'
  s.homepage         = 'https://h3geo.org/'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  s.source           = { :http => 'https://github.com/uber/h3/archive/refs/tags/v4.2.0.tar.gz' }
  s.ios.vendored_libraries = 'Frameworks/libh3.a'
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  s.source_files = 'Classes/**/*'
  s.xcconfig = {
    'HEADER_SEARCH_PATHS' => '${PODS_ROOT}/../../.symlinks/plugins/flutter_h3/ios/Frameworks',
    'LIBRARY_SEARCH_PATHS' => '${PODS_ROOT}/../../.symlinks/plugins/flutter_h3/ios/Frameworks'
  }
end
```

## API Reference

### Basic Operations

#### `latLngToCell`
Converts latitude and longitude to an H3 index.

```dart
int h3Index = FlutterH3.latLngToCell(37.7749, -122.4194, 9);
```

Parameters:
- `lat` (double): Latitude in degrees
- `lng` (double): Longitude in degrees
- `resolution` (int): Resolution of the H3 index (0-15, where 0 is coarsest and 15 is finest)

Returns:
- H3 index as a 64-bit integer

#### `cellToLatLng`
Converts an H3 index to its center point latitude and longitude.

```dart
Map<String, double> latLng = FlutterH3.cellToLatLng(h3Index);
print('Lat: ${latLng['lat']}, Lng: ${latLng['lng']}');
```

Parameters:
- `h3Index` (int): The H3 index

Returns:
- Map with 'lat' and 'lng' keys containing the coordinates in degrees

#### `cellToBoundary`
Gets the boundary of an H3 cell as a list of lat/lng points.

```dart
List<Map<String, double>> boundary = FlutterH3.cellToBoundary(h3Index);
```

Parameters:
- `h3Index` (int): The H3 index

Returns:
- List of maps with 'lat' and 'lng' keys representing the boundary vertices

### Cell Relationships

#### `gridDisk`
Gets the surrounding cells (k-ring) for a given cell.

```dart
List<int> surroundingCells = FlutterH3.gridDisk(h3Index, 1);
```

Parameters:
- `h3Index` (int): The center H3 index
- `k` (int): The radius of the k-ring

Returns:
- List of H3 indices in the k-ring (including the center)

#### `cellToParent`
Gets the parent cell at a given resolution.

```dart
int parentIndex = FlutterH3.cellToParent(h3Index, 8);
```

Parameters:
- `h3Index` (int): The H3 index
- `parentRes` (int): The resolution of the parent (must be less than or equal to the resolution of the input)

Returns:
- The parent H3 index

#### `cellToChildren`
Gets the children cells at a given resolution.

```dart
List<int> childIndices = FlutterH3.cellToChildren(h3Index, 10);
```

Parameters:
- `h3Index` (int): The H3 index
- `childRes` (int): The resolution of the children (must be greater than or equal to the resolution of the input)

Returns:
- List of children H3 indices

### Polygon Operations

#### `polygonToCells`
Converts a polygon to a set of H3 cells.

```dart
// Define a polygon (must close by repeating the first point)
List<List<double>> polygon = [
  [37.7866, -122.4183], // lat, lng
  [37.7198, -122.3543],
  [37.7790, -122.3898],
  [37.7866, -122.4183], // repeat the first point to close the polygon
];

// Optional holes in the polygon
List<List<List<double>>> holes = [
  [
    [37.7805, -122.4051],
    [37.7850, -122.4009],
    [37.7870, -122.4080],
    [37.7805, -122.4051],
  ]
];

// Convert the polygon to H3 cells at resolution 9
List<int> cells = FlutterH3.polygonToCells(polygon, holes, 9);
```

Parameters:
- `polygon` (List<List<double>>): A list of [lat, lng] coordinates in degrees representing the polygon boundary
- `holes` (List<List<List<double>>>?): Optional list of holes in the polygon, each as a list of [lat, lng] coordinates
- `resolution` (int): The resolution of the H3 cells

Returns:
- List of H3 indices that cover the polygon

#### `polygonToCellsExperimental`
Experimental version of polygonToCells with configurable containment modes.

```dart
// For full cell containment (more accurate but slower)
List<int> cellsFullContainment = FlutterH3.polygonToCellsExperimental(
  polygon, 
  holes, 
  9, 
  1 // CONTAINMENT_FULL
);

// For overlapping containment (any cell that overlaps the polygon)
List<int> cellsOverlapping = FlutterH3.polygonToCellsExperimental(
  polygon, 
  holes, 
  9, 
  2 // CONTAINMENT_OVERLAPPING
);
```

Parameters:
- `polygon` (List<List<double>>): A list of [lat, lng] coordinates in degrees representing the polygon boundary
- `holes` (List<List<List<double>>>?): Optional list of holes in the polygon, each as a list of [lat, lng] coordinates
- `resolution` (int): The resolution of the H3 cells
- `flags` (int): Bit field of flags used to control the algorithm:
  - 0: Use the default algorithm (cell center point)
  - 1: Use the full cell containment algorithm (more accurate but slower)
  - 2: Use the algorithm that considers any overlap with the polygon

Returns:
- List of H3 indices that cover the polygon according to the selected containment mode

### String Conversions

#### `h3ToString`
Converts an H3 index to a string representation.

```dart
String h3String = FlutterH3.h3ToString(h3Index);
```

Parameters:
- `h3Index` (int): The H3 index

Returns:
- String representation of the H3 index

#### `stringToH3`
Converts a string representation to an H3 index.

```dart
int h3Index = FlutterH3.stringToH3("8928308280fffff");
```

Parameters:
- `h3Str` (String): The string representation of the H3 index

Returns:
- H3 index as a 64-bit integer

### Validation and Properties

#### `isValidCell`
Checks if a cell is valid.

```dart
bool isValid = FlutterH3.isValidCell(h3Index);
```

Parameters:
- `h3Index` (int): The H3 index

Returns:
- true if the cell is valid, false otherwise

#### `areNeighborCells`
Checks if two cells are neighbors.

```dart
bool areNeighbors = FlutterH3.areNeighborCells(h3Index1, h3Index2);
```

Parameters:
- `origin` (int): The first H3 index
- `destination` (int): The second H3 index

Returns:
- true if the cells are neighbors, false otherwise

#### `getResolution`
Gets the resolution of an H3 index.

```dart
int resolution = FlutterH3.getResolution(h3Index);
```

Parameters:
- `h3Index` (int): The H3 index

Returns:
- The resolution (0-15)

## Example

For a complete example, check the `example` directory in the package source.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_h3/flutter_h3.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Sample location
  final double lat = 37.7749;
  final double lng = -122.4194;
  
  // H3 indices and data
  int? h3Index;
  String? h3String;
  List<Map<String, double>>? boundary;
  
  @override
  void initState() {
    super.initState();
    
    // Get H3 index at resolution 9
    h3Index = FlutterH3.latLngToCell(lat, lng, 9);
    
    // Convert to string
    h3String = FlutterH3.h3ToString(h3Index!);
    
    // Get boundary
    boundary = FlutterH3.cellToBoundary(h3Index!);
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('H3 Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Location: $lat, $lng'),
              SizedBox(height: 20),
              Text('H3 Index: $h3String'),
              SizedBox(height: 20),
              Text('Boundary Points: ${boundary?.length ?? 0}'),
            ],
          ),
        ),
      ),
    );
  }
}
```

## License

This package is available under the MIT License. See the LICENSE file for details.

## Additional Information

* The H3 library itself is licensed under the Apache 2.0 License.
* For more information about the H3 Core library, visit [h3geo.org](https://h3geo.org/).
* For bug reports and feature requests, please use the [issue tracker](https://github.com/yourusername/flutter_h3/issues).

