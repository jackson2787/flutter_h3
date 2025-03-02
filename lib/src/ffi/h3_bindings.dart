import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// H3Index is a uint64_t in C
typedef H3IndexNative = Uint64;
typedef H3IndexDart = int;

// H3Error is a uint32_t in C
typedef H3ErrorNative = Uint32;
typedef H3ErrorDart = int;

// C struct for LatLng
base class LatLng extends Struct {
  @Double()
  external double lat; // latitude in radians

  @Double()
  external double lng; // longitude in radians
}

// C struct for CoordIJ
base class CoordIJ extends Struct {
  @Int32()
  external int i;

  @Int32()
  external int j;
}

// Maximum number of cell boundary vertices
final int MAX_CELL_BNDRY_VERTS = 10;

// C struct for CellBoundary
base class CellBoundary extends Struct {
  @Int32()
  external int numVerts;

  // We can't represent fixed-size arrays directly in Dart FFI
  // Instead, we'll access the verts one by one in our wrapper
  external LatLng vert0;
  external LatLng vert1;
  external LatLng vert2;
  external LatLng vert3;
  external LatLng vert4;
  external LatLng vert5;
  external LatLng vert6;
  external LatLng vert7;
  external LatLng vert8;
  external LatLng vert9;

  // Helper method to get a vertex by index
  LatLng getVert(int index) {
    assert(index >= 0 && index < MAX_CELL_BNDRY_VERTS, 'Vertex index out of bounds');
    
    switch (index) {
      case 0: return vert0;
      case 1: return vert1;
      case 2: return vert2;
      case 3: return vert3;
      case 4: return vert4;
      case 5: return vert5;
      case 6: return vert6;
      case 7: return vert7;
      case 8: return vert8;
      case 9: return vert9;
      default: throw ArgumentError('Invalid vertex index: $index');
    }
  }
}

// C struct for GeoLoop
base class GeoLoop extends Struct {
  @Int32()
  external int numVerts;

  external Pointer<LatLng> verts;
}

// C struct for GeoPolygon
base class GeoPolygon extends Struct {
  external GeoLoop geoloop;

  @Int32()
  external int numHoles;

  external Pointer<GeoLoop> holes;
}

// Define the DynamicLibrary based on the platform
final DynamicLibrary h3Lib = () {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libh3.so');
  } else if (Platform.isIOS) {
    // On iOS, the H3 library is statically linked and symbols are in the process space
    return DynamicLibrary.process();
  }
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}();

// Define bindings for the H3 functions we need
class H3Bindings {
  // Convert lat/long to H3 index
  static final latLngToCell = h3Lib.lookupFunction<
      H3ErrorNative Function(Pointer<LatLng>, Int32, Pointer<H3IndexNative>),
      H3ErrorDart Function(Pointer<LatLng>, int, Pointer<H3IndexNative>)>('latLngToCell');

  // Convert H3 index to lat/long center point
  static final cellToLatLng = h3Lib.lookupFunction<
      H3ErrorNative Function(H3IndexNative, Pointer<LatLng>),
      H3ErrorDart Function(H3IndexDart, Pointer<LatLng>)>('cellToLatLng');

  // Get the cell boundary in lat/long coordinates
  static final cellToBoundary = h3Lib.lookupFunction<
      H3ErrorNative Function(H3IndexNative, Pointer<CellBoundary>),
      H3ErrorDart Function(H3IndexDart, Pointer<CellBoundary>)>('cellToBoundary');

  // Get surrounding cells (k-ring)
  static final gridDisk = h3Lib.lookupFunction<
      H3ErrorNative Function(H3IndexNative, Int32, Pointer<H3IndexNative>),
      H3ErrorDart Function(H3IndexDart, int, Pointer<H3IndexNative>)>('gridDisk');

  // Get max size for k-ring
  static final maxGridDiskSize = h3Lib.lookupFunction<
      H3ErrorNative Function(Int32, Pointer<Int64>),
      H3ErrorDart Function(int, Pointer<Int64>)>('maxGridDiskSize');

  // Convert to parent cell
  static final cellToParent = h3Lib.lookupFunction<
      H3ErrorNative Function(H3IndexNative, Int32, Pointer<H3IndexNative>),
      H3ErrorDart Function(H3IndexDart, int, Pointer<H3IndexNative>)>('cellToParent');

  // Get children cells 
  static final cellToChildren = h3Lib.lookupFunction<
      H3ErrorNative Function(H3IndexNative, Int32, Pointer<H3IndexNative>),
      H3ErrorDart Function(H3IndexDart, int, Pointer<H3IndexNative>)>('cellToChildren');

  // Get children size
  static final cellToChildrenSize = h3Lib.lookupFunction<
      H3ErrorNative Function(H3IndexNative, Int32, Pointer<Int64>),
      H3ErrorDart Function(H3IndexDart, int, Pointer<Int64>)>('cellToChildrenSize');

  // Polygon to cells
  static final polygonToCells = h3Lib.lookupFunction<
      H3ErrorNative Function(Pointer<GeoPolygon>, Int32, Uint32, Pointer<H3IndexNative>),
      H3ErrorDart Function(Pointer<GeoPolygon>, int, int, Pointer<H3IndexNative>)>('polygonToCells');

  // Max size for polygon to cells
  static final maxPolygonToCellsSize = h3Lib.lookupFunction<
      H3ErrorNative Function(Pointer<GeoPolygon>, Int32, Uint32, Pointer<Int64>),
      H3ErrorDart Function(Pointer<GeoPolygon>, int, int, Pointer<Int64>)>('maxPolygonToCellsSize');

  // Experimental version: Polygon to cells
  static final polygonToCellsExperimental = h3Lib.lookupFunction<
      H3ErrorNative Function(Pointer<GeoPolygon>, Int32, Uint32, Int64, Pointer<H3IndexNative>),
      H3ErrorDart Function(Pointer<GeoPolygon>, int, int, int, Pointer<H3IndexNative>)>('polygonToCellsExperimental');

  // Experimental version: Max size for polygon to cells
  static final maxPolygonToCellsSizeExperimental = h3Lib.lookupFunction<
      H3ErrorNative Function(Pointer<GeoPolygon>, Int32, Uint32, Pointer<Int64>),
      H3ErrorDart Function(Pointer<GeoPolygon>, int, int, Pointer<Int64>)>('maxPolygonToCellsSizeExperimental');

  // Check if valid cell
  static final isValidCell = h3Lib.lookupFunction<
      Int32 Function(H3IndexNative),
      int Function(H3IndexDart)>('isValidCell');

  // Get resolution
  static final getResolution = h3Lib.lookupFunction<
      Int32 Function(H3IndexNative),
      int Function(H3IndexDart)>('getResolution');

  // Convert H3 index to string
  static final h3ToString = h3Lib.lookupFunction<
      H3ErrorNative Function(H3IndexNative, Pointer<Char>, Size),
      H3ErrorDart Function(H3IndexDart, Pointer<Char>, int)>('h3ToString');

  // Convert string to H3 index
  static final stringToH3 = h3Lib.lookupFunction<
      H3ErrorNative Function(Pointer<Char>, Pointer<H3IndexNative>),
      H3ErrorDart Function(Pointer<Char>, Pointer<H3IndexNative>)>('stringToH3');

  // Check if cells are neighbors
  static final areNeighborCells = h3Lib.lookupFunction<
      H3ErrorNative Function(H3IndexNative, H3IndexNative, Pointer<Int32>),
      H3ErrorDart Function(H3IndexDart, H3IndexDart, Pointer<Int32>)>('areNeighborCells');
} 