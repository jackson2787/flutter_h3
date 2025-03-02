import 'dart:ffi';
import 'dart:math' as math;
import 'package:ffi/ffi.dart';
import 'ffi/h3_bindings.dart';

/// A wrapper for the H3 library to make it easier to use from Dart.
class H3Wrapper {
  /// Converts latitude and longitude to an H3 index.
  /// 
  /// [lat] Latitude in degrees
  /// [lng] Longitude in degrees
  /// [resolution] Resolution of the H3 index (0-15)
  /// 
  /// Returns the H3 index as a 64-bit integer.
  static int latLngToCell(double lat, double lng, int resolution) {
    // Check resolution bounds
    if (resolution < 0 || resolution > 15) {
      throw ArgumentError('Resolution must be between 0 and 15');
    }

    final latLngPtr = calloc<LatLng>();
    final indexPtr = calloc<H3IndexNative>();
    
    try {
      // Convert degrees to radians
      latLngPtr.ref.lat = degreesToRadians(lat);
      latLngPtr.ref.lng = degreesToRadians(lng);
      
      // Call the H3 function
      final error = H3Bindings.latLngToCell(latLngPtr, resolution, indexPtr);
      if (error != 0) {
        throw H3Exception._fromErrorCode(error);
      }
      
      return indexPtr.value;
    } finally {
      calloc.free(latLngPtr);
      calloc.free(indexPtr);
    }
  }

  /// Converts an H3 index to latitude and longitude.
  /// 
  /// [h3Index] The H3 index
  /// 
  /// Returns a map with 'lat' and 'lng' in degrees
  static Map<String, double> cellToLatLng(int h3Index) {
    final latLngPtr = calloc<LatLng>();
    
    try {
      // Call the H3 function
      final error = H3Bindings.cellToLatLng(h3Index, latLngPtr);
      if (error != 0) {
        throw H3Exception._fromErrorCode(error);
      }
      
      // Convert radians to degrees
      return {
        'lat': radiansToDegrees(latLngPtr.ref.lat),
        'lng': radiansToDegrees(latLngPtr.ref.lng),
      };
    } finally {
      calloc.free(latLngPtr);
    }
  }

  /// Gets the boundary of an H3 cell.
  /// 
  /// [h3Index] The H3 index
  /// 
  /// Returns a list of points (lat/lng in degrees) representing the boundary
  static List<Map<String, double>> cellToBoundary(int h3Index) {
    final boundaryPtr = calloc<CellBoundary>();
    
    try {
      // Call the H3 function
      final error = H3Bindings.cellToBoundary(h3Index, boundaryPtr);
      if (error != 0) {
        throw H3Exception._fromErrorCode(error);
      }
      
      // Convert the boundary to a list of points
      final result = <Map<String, double>>[];
      final numVerts = boundaryPtr.ref.numVerts;
      
      for (var i = 0; i < numVerts; i++) {
        final vert = boundaryPtr.ref.getVert(i);
        result.add({
          'lat': radiansToDegrees(vert.lat),
          'lng': radiansToDegrees(vert.lng),
        });
      }
      
      return result;
    } finally {
      calloc.free(boundaryPtr);
    }
  }

  /// Gets the surrounding cells (k-ring) for a given cell.
  /// 
  /// [h3Index] The center H3 index
  /// [k] The radius of the k-ring
  /// 
  /// Returns a list of H3 indices
  static List<int> gridDisk(int h3Index, int k) {
    // Get the maximum size of the k-ring
    final sizePtr = calloc<Int64>();
    try {
      final error = H3Bindings.maxGridDiskSize(k, sizePtr);
      if (error != 0) {
        throw H3Exception._fromErrorCode(error);
      }
      
      final maxSize = sizePtr.value;
      final outPtr = calloc<H3IndexNative>(maxSize);
      
      try {
        // Call the H3 function
        final error = H3Bindings.gridDisk(h3Index, k, outPtr);
        if (error != 0) {
          throw H3Exception._fromErrorCode(error);
        }
        
        // Convert the result to a list
        final result = <int>[];
        for (var i = 0; i < maxSize; i++) {
          final value = outPtr[i];
          // Skip empty (0) indices
          if (value != 0) {
            result.add(value);
          }
        }
        
        return result;
      } finally {
        calloc.free(outPtr);
      }
    } finally {
      calloc.free(sizePtr);
    }
  }

  /// Gets the parent cell at a given resolution.
  /// 
  /// [h3Index] The H3 index
  /// [parentRes] The resolution of the parent
  /// 
  /// Returns the parent H3 index
  static int cellToParent(int h3Index, int parentRes) {
    final currentRes = H3Bindings.getResolution(h3Index);
    if (parentRes > currentRes) {
      throw ArgumentError('Parent resolution must be less than or equal to the current resolution');
    }
    
    final parentPtr = calloc<H3IndexNative>();
    
    try {
      // Call the H3 function
      final error = H3Bindings.cellToParent(h3Index, parentRes, parentPtr);
      if (error != 0) {
        throw H3Exception._fromErrorCode(error);
      }
      
      return parentPtr.value;
    } finally {
      calloc.free(parentPtr);
    }
  }

  /// Gets the children cells at a given resolution.
  /// 
  /// [h3Index] The H3 index
  /// [childRes] The resolution of the children
  /// 
  /// Returns a list of children H3 indices
  static List<int> cellToChildren(int h3Index, int childRes) {
    final currentRes = H3Bindings.getResolution(h3Index);
    if (childRes < currentRes) {
      throw ArgumentError('Child resolution must be greater than or equal to the current resolution');
    }
    
    // Get the number of children
    final sizePtr = calloc<Int64>();
    try {
      final error = H3Bindings.cellToChildrenSize(h3Index, childRes, sizePtr);
      if (error != 0) {
        throw H3Exception._fromErrorCode(error);
      }
      
      final size = sizePtr.value;
      final childrenPtr = calloc<H3IndexNative>(size);
      
      try {
        // Call the H3 function
        final error = H3Bindings.cellToChildren(h3Index, childRes, childrenPtr);
        if (error != 0) {
          throw H3Exception._fromErrorCode(error);
        }
        
        // Convert the result to a list
        final result = <int>[];
        for (var i = 0; i < size; i++) {
          result.add(childrenPtr[i]);
        }
        
        return result;
      } finally {
        calloc.free(childrenPtr);
      }
    } finally {
      calloc.free(sizePtr);
    }
  }

  /// Converts a polygon to a set of H3 cells.
  /// 
  /// [polygon] A list of [lat, lng] coordinates in degrees representing the polygon boundary
  /// [holes] A list of lists of [lat, lng] coordinates representing holes in the polygon
  /// [resolution] The resolution of the H3 cells
  /// 
  /// Returns a list of H3 indices
  static List<int> polygonToCells(List<List<double>> polygon, List<List<List<double>>>? holes, int resolution) {
    if (polygon.isEmpty) {
      throw ArgumentError('Polygon cannot be empty');
    }
    
    // Create GeoPolygon
    final geoPolygon = calloc<GeoPolygon>();
    
    try {
      // Setup the exterior boundary (geoloop)
      final numVerts = polygon.length;
      final geoLoopVerts = calloc<LatLng>(numVerts);
      
      try {
        // Convert polygon vertices to LatLng (in radians)
        for (var i = 0; i < numVerts; i++) {
          if (polygon[i].length != 2) {
            throw ArgumentError('Each polygon vertex must be [lat, lng]');
          }
          geoLoopVerts[i].lat = degreesToRadians(polygon[i][0]);
          geoLoopVerts[i].lng = degreesToRadians(polygon[i][1]);
        }
        
        // Set up the geoloop in the polygon
        geoPolygon.ref.geoloop.numVerts = numVerts;
        geoPolygon.ref.geoloop.verts = geoLoopVerts;
        
        // Set up holes if any
        final numHoles = holes?.length ?? 0;
        geoPolygon.ref.numHoles = numHoles;
        
        // Create and set up holes
        Pointer<GeoLoop>? holesPtr;
        List<Pointer<LatLng>> holeVertsPointers = [];
        
        if (numHoles > 0) {
          holesPtr = calloc<GeoLoop>(numHoles);
          
          try {
            for (var i = 0; i < numHoles; i++) {
              final hole = holes![i];
              final holeNumVerts = hole.length;
              
              // Allocate vertices for this hole
              final holeVerts = calloc<LatLng>(holeNumVerts);
              holeVertsPointers.add(holeVerts);
              
              // Convert hole vertices to LatLng (in radians)
              for (var j = 0; j < holeNumVerts; j++) {
                if (hole[j].length != 2) {
                  throw ArgumentError('Each hole vertex must be [lat, lng]');
                }
                holeVerts[j].lat = degreesToRadians(hole[j][0]);
                holeVerts[j].lng = degreesToRadians(hole[j][1]);
              }
              
              // Set up this hole
              holesPtr[i].numVerts = holeNumVerts;
              holesPtr[i].verts = holeVerts;
            }
            
            geoPolygon.ref.holes = holesPtr;
            
            // Get the maximum number of cells
            final sizePtr = calloc<Int64>();
            try {
              final error = H3Bindings.maxPolygonToCellsSize(geoPolygon, resolution, 0, sizePtr);
              if (error != 0) {
                throw H3Exception._fromErrorCode(error);
              }
              
              final maxSize = sizePtr.value;
              final outPtr = calloc<H3IndexNative>(maxSize);
              
              try {
                // Call the H3 function
                final error = H3Bindings.polygonToCells(geoPolygon, resolution, 0, outPtr);
                if (error != 0) {
                  throw H3Exception._fromErrorCode(error);
                }
                
                // Convert the result to a list
                final result = <int>[];
                for (var i = 0; i < maxSize; i++) {
                  final value = outPtr[i];
                  // Skip empty (0) indices
                  if (value != 0) {
                    result.add(value);
                  } else {
                    // Once we hit a 0, we've reached the end of valid indices
                    break;
                  }
                }
                
                return result;
              } finally {
                calloc.free(outPtr);
              }
            } finally {
              calloc.free(sizePtr);
            }
          } finally {
            if (holesPtr != null) {
              calloc.free(holesPtr);
            }
            // Free all hole vertices
            for (var vertsPtr in holeVertsPointers) {
              calloc.free(vertsPtr);
            }
          }
        } else {
          // No holes, just get the max size and cells
          final sizePtr = calloc<Int64>();
          try {
            final error = H3Bindings.maxPolygonToCellsSize(geoPolygon, resolution, 0, sizePtr);
            if (error != 0) {
              throw H3Exception._fromErrorCode(error);
            }
            
            final maxSize = sizePtr.value;
            final outPtr = calloc<H3IndexNative>(maxSize);
            
            try {
              // Call the H3 function
              final error = H3Bindings.polygonToCells(geoPolygon, resolution, 0, outPtr);
              if (error != 0) {
                throw H3Exception._fromErrorCode(error);
              }
              
              // Convert the result to a list
              final result = <int>[];
              for (var i = 0; i < maxSize; i++) {
                final value = outPtr[i];
                // Skip empty (0) indices
                if (value != 0) {
                  result.add(value);
                } else {
                  // Once we hit a 0, we've reached the end of valid indices
                  break;
                }
              }
              
              return result;
            } finally {
              calloc.free(outPtr);
            }
          } finally {
            calloc.free(sizePtr);
          }
        }
      } finally {
        calloc.free(geoLoopVerts);
      }
    } finally {
      calloc.free(geoPolygon);
    }
  }

  /// Converts an H3 index to a string representation.
  /// 
  /// [h3Index] The H3 index
  /// 
  /// Returns the string representation of the H3 index
  static String h3ToString(int h3Index) {
    // H3 string length is max 17 chars + null terminator
    final strPtr = calloc<Char>(18);
    
    try {
      // Call the H3 function
      final error = H3Bindings.h3ToString(h3Index, strPtr, 18);
      if (error != 0) {
        throw H3Exception._fromErrorCode(error);
      }
      
      // Convert the C string to a Dart string
      return strPtr.cast<Utf8>().toDartString();
    } finally {
      calloc.free(strPtr);
    }
  }

  /// Converts a string representation to an H3 index.
  /// 
  /// [h3Str] The string representation of the H3 index
  /// 
  /// Returns the H3 index
  static int stringToH3(String h3Str) {
    final strPtr = h3Str.toNativeUtf8();
    final indexPtr = calloc<H3IndexNative>();
    
    try {
      // Call the H3 function
      final error = H3Bindings.stringToH3(strPtr.cast<Char>(), indexPtr);
      if (error != 0) {
        throw H3Exception._fromErrorCode(error);
      }
      
      return indexPtr.value;
    } finally {
      calloc.free(strPtr);
      calloc.free(indexPtr);
    }
  }

  /// Checks if a cell is valid.
  /// 
  /// [h3Index] The H3 index
  /// 
  /// Returns true if the cell is valid, false otherwise
  static bool isValidCell(int h3Index) {
    return H3Bindings.isValidCell(h3Index) != 0;
  }

  /// Checks if two cells are neighbors.
  /// 
  /// [origin] The first H3 index
  /// [destination] The second H3 index
  /// 
  /// Returns true if the cells are neighbors, false otherwise
  static bool areNeighborCells(int origin, int destination) {
    final resultPtr = calloc<Int32>();
    
    try {
      // Call the H3 function
      final error = H3Bindings.areNeighborCells(origin, destination, resultPtr);
      if (error != 0) {
        throw H3Exception._fromErrorCode(error);
      }
      
      return resultPtr.value != 0;
    } finally {
      calloc.free(resultPtr);
    }
  }

  /// Gets the resolution of an H3 index.
  /// 
  /// [h3Index] The H3 index
  /// 
  /// Returns the resolution (0-15)
  static int getResolution(int h3Index) {
    return H3Bindings.getResolution(h3Index);
  }

  // Utility functions
  
  /// Converts degrees to radians.
  static double degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Converts radians to degrees.
  static double radiansToDegrees(double radians) {
    return radians * (180.0 / math.pi);
  }

  /// Returns a list of H3 indices using the experimental polygon-to-cells function
  /// 
  /// This is an experimental API and is subject to change in minor versions.
  /// 
  /// @param polygon The polygon coordinates as a list of [lat, lng] points
  /// @param holes Optional list of holes in the polygon, each as a list of [lat, lng] points
  /// @param resolution The desired H3 resolution (0-15)
  /// @param flags Bit field of flags used to control the algorithm. Possible values:
  ///   0: Use the default algorithm (cell center point)
  ///   1: Use the full cell containment algorithm (more accurate but slower)
  ///   2: Use the algorithm that considers any overlap with the polygon
  static List<int> polygonToCellsExperimental(List<List<double>> polygon, List<List<List<double>>>? holes, int resolution, int flags) {
    if (polygon.isEmpty) {
      throw ArgumentError('Polygon cannot be empty');
    }
    
    // Create GeoPolygon
    final geoPolygon = calloc<GeoPolygon>();
    
    try {
      // Setup the exterior boundary (geoloop)
      final numVerts = polygon.length;
      final geoLoopVerts = calloc<LatLng>(numVerts);
      
      try {
        // Convert polygon vertices to LatLng (in radians)
        for (var i = 0; i < numVerts; i++) {
          if (polygon[i].length != 2) {
            throw ArgumentError('Each polygon vertex must be [lat, lng]');
          }
          geoLoopVerts[i].lat = degreesToRadians(polygon[i][0]);
          geoLoopVerts[i].lng = degreesToRadians(polygon[i][1]);
        }
        
        // Set up the geoloop in the polygon
        geoPolygon.ref.geoloop.numVerts = numVerts;
        geoPolygon.ref.geoloop.verts = geoLoopVerts;
        
        // Set up holes if any
        final numHoles = holes?.length ?? 0;
        geoPolygon.ref.numHoles = numHoles;
        
        // Create and set up holes
        Pointer<GeoLoop>? holesPtr;
        List<Pointer<LatLng>> holeVertsPointers = [];
        
        if (numHoles > 0) {
          holesPtr = calloc<GeoLoop>(numHoles);
          
          try {
            for (var i = 0; i < numHoles; i++) {
              final hole = holes![i];
              final holeNumVerts = hole.length;
              
              // Allocate vertices for this hole
              final holeVerts = calloc<LatLng>(holeNumVerts);
              holeVertsPointers.add(holeVerts);
              
              // Convert hole vertices to LatLng (in radians)
              for (var j = 0; j < holeNumVerts; j++) {
                if (hole[j].length != 2) {
                  throw ArgumentError('Each hole vertex must be [lat, lng]');
                }
                holeVerts[j].lat = degreesToRadians(hole[j][0]);
                holeVerts[j].lng = degreesToRadians(hole[j][1]);
              }
              
              // Set up this hole
              holesPtr[i].numVerts = holeNumVerts;
              holesPtr[i].verts = holeVerts;
            }
            
            geoPolygon.ref.holes = holesPtr;
            
            // Get the maximum number of cells
            final sizePtr = calloc<Int64>();
            try {
              final error = H3Bindings.maxPolygonToCellsSizeExperimental(geoPolygon, resolution, flags, sizePtr);
              if (error != 0) {
                throw H3Exception._fromErrorCode(error);
              }
              
              final maxSize = sizePtr.value;
              final outPtr = calloc<H3IndexNative>(maxSize);
              
              try {
                // Call the H3 function
                final error = H3Bindings.polygonToCellsExperimental(geoPolygon, resolution, flags, maxSize, outPtr);
                if (error != 0) {
                  throw H3Exception._fromErrorCode(error);
                }
                
                // Convert the result to a list
                final result = <int>[];
                for (var i = 0; i < maxSize; i++) {
                  final value = outPtr[i];
                  // Skip empty (0) indices
                  if (value != 0) {
                    result.add(value);
                  } else {
                    // Once we hit a 0, we've reached the end of valid indices
                    break;
                  }
                }
                
                return result;
              } finally {
                calloc.free(outPtr);
              }
            } finally {
              calloc.free(sizePtr);
            }
          } finally {
            if (holesPtr != null) {
              calloc.free(holesPtr);
            }
            // Free all hole vertices
            for (var vertsPtr in holeVertsPointers) {
              calloc.free(vertsPtr);
            }
          }
        } else {
          // No holes, just get the max size and cells
          final sizePtr = calloc<Int64>();
          try {
            final error = H3Bindings.maxPolygonToCellsSizeExperimental(geoPolygon, resolution, flags, sizePtr);
            if (error != 0) {
              throw H3Exception._fromErrorCode(error);
            }
            
            final maxSize = sizePtr.value;
            final outPtr = calloc<H3IndexNative>(maxSize);
            
            try {
              // Call the H3 function
              final error = H3Bindings.polygonToCellsExperimental(geoPolygon, resolution, flags, maxSize, outPtr);
              if (error != 0) {
                throw H3Exception._fromErrorCode(error);
              }
              
              // Convert the result to a list
              final result = <int>[];
              for (var i = 0; i < maxSize; i++) {
                final value = outPtr[i];
                // Skip empty (0) indices
                if (value != 0) {
                  result.add(value);
                } else {
                  // Once we hit a 0, we've reached the end of valid indices
                  break;
                }
              }
              
              return result;
            } finally {
              calloc.free(outPtr);
            }
          } finally {
            calloc.free(sizePtr);
          }
        }
      } finally {
        calloc.free(geoLoopVerts);
      }
    } finally {
      calloc.free(geoPolygon);
    }
  }
}

/// Exception thrown when an H3 function returns an error.
class H3Exception implements Exception {
  final int errorCode;
  final String message;

  H3Exception._(this.errorCode, this.message);

  factory H3Exception._fromErrorCode(int errorCode) {
    String message;
    
    switch (errorCode) {
      case 1:
        message = 'The operation failed but a more specific error is not available';
        break;
      case 2:
        message = 'Argument was outside of acceptable range';
        break;
      case 3:
        message = 'Latitude or longitude arguments were outside of acceptable range';
        break;
      case 4:
        message = 'Resolution argument was outside of acceptable range';
        break;
      case 5:
        message = 'H3Index cell argument was not valid';
        break;
      // Add more error codes as needed
      default:
        message = 'Unknown error code: $errorCode';
    }
    
    return H3Exception._(errorCode, message);
  }

  @override
  String toString() => 'H3Exception: $message (code: $errorCode)';
} 