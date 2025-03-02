import 'src/h3_wrapper.dart';

/// A Flutter plugin that provides an interface to Uber's H3 geospatial library.
class FlutterH3 {
  /// Converts latitude and longitude to an H3 index.
  /// 
  /// [lat] Latitude in degrees
  /// [lng] Longitude in degrees
  /// [resolution] Resolution of the H3 index (0-15, where 0 is coarsest and 15 is finest)
  /// 
  /// Returns the H3 index as a 64-bit integer.
  static int latLngToCell(double lat, double lng, int resolution) {
    return H3Wrapper.latLngToCell(lat, lng, resolution);
  }

  /// Converts an H3 index to latitude and longitude.
  /// 
  /// [h3Index] The H3 index
  /// 
  /// Returns a map with 'lat' and 'lng' in degrees
  static Map<String, double> cellToLatLng(int h3Index) {
    return H3Wrapper.cellToLatLng(h3Index);
  }

  /// Gets the boundary of an H3 cell.
  /// 
  /// [h3Index] The H3 index
  /// 
  /// Returns a list of points (lat/lng in degrees) representing the boundary
  static List<Map<String, double>> cellToBoundary(int h3Index) {
    return H3Wrapper.cellToBoundary(h3Index);
  }

  /// Gets the surrounding cells (k-ring) for a given cell.
  /// 
  /// [h3Index] The center H3 index
  /// [k] The radius of the k-ring
  /// 
  /// Returns a list of H3 indices
  static List<int> gridDisk(int h3Index, int k) {
    return H3Wrapper.gridDisk(h3Index, k);
  }

  /// Gets the parent cell at a given resolution.
  /// 
  /// [h3Index] The H3 index
  /// [parentRes] The resolution of the parent
  /// 
  /// Returns the parent H3 index
  static int cellToParent(int h3Index, int parentRes) {
    return H3Wrapper.cellToParent(h3Index, parentRes);
  }

  /// Gets the children cells at a given resolution.
  /// 
  /// [h3Index] The H3 index
  /// [childRes] The resolution of the children
  /// 
  /// Returns a list of children H3 indices
  static List<int> cellToChildren(int h3Index, int childRes) {
    return H3Wrapper.cellToChildren(h3Index, childRes);
  }

  /// Converts a polygon to a set of H3 cells.
  /// 
  /// [polygon] A list of [lat, lng] coordinates in degrees representing the polygon boundary
  /// [holes] A list of lists of [lat, lng] coordinates representing holes in the polygon
  /// [resolution] The resolution of the H3 cells
  /// 
  /// Returns a list of H3 indices
  static List<int> polygonToCells(List<List<double>> polygon, List<List<List<double>>>? holes, int resolution) {
    return H3Wrapper.polygonToCells(polygon, holes, resolution);
  }

  /// Returns a list of H3 indices using the experimental polygon-to-cells function
  /// 
  /// This is an experimental API and is subject to change in minor versions.
  /// 
  /// [polygon] The polygon coordinates as a list of [lat, lng] points
  /// [holes] Optional list of holes in the polygon, each as a list of [lat, lng] points
  /// [resolution] The desired H3 resolution (0-15)
  /// [flags] Bit field of flags used to control the algorithm. Possible values:
  ///   0: Use the default algorithm (cell center point)
  ///   1: Use the full cell containment algorithm (more accurate but slower)
  ///   2: Use the algorithm that considers any overlap with the polygon
  static List<int> polygonToCellsExperimental(List<List<double>> polygon, List<List<List<double>>>? holes, int resolution, int flags) {
    return H3Wrapper.polygonToCellsExperimental(polygon, holes, resolution, flags);
  }

  /// Converts an H3 index to a string representation.
  /// 
  /// [h3Index] The H3 index
  /// 
  /// Returns the string representation of the H3 index
  static String h3ToString(int h3Index) {
    return H3Wrapper.h3ToString(h3Index);
  }

  /// Converts a string representation to an H3 index.
  /// 
  /// [h3Str] The string representation of the H3 index
  /// 
  /// Returns the H3 index
  static int stringToH3(String h3Str) {
    return H3Wrapper.stringToH3(h3Str);
  }

  /// Checks if a cell is valid.
  /// 
  /// [h3Index] The H3 index
  /// 
  /// Returns true if the cell is valid, false otherwise
  static bool isValidCell(int h3Index) {
    return H3Wrapper.isValidCell(h3Index);
  }

  /// Checks if two cells are neighbors.
  /// 
  /// [origin] The first H3 index
  /// [destination] The second H3 index
  /// 
  /// Returns true if the cells are neighbors, false otherwise
  static bool areNeighborCells(int origin, int destination) {
    return H3Wrapper.areNeighborCells(origin, destination);
  }

  /// Gets the resolution of an H3 index.
  /// 
  /// [h3Index] The H3 index
  /// 
  /// Returns the resolution (0-15)
  static int getResolution(int h3Index) {
    return H3Wrapper.getResolution(h3Index);
  }
}
