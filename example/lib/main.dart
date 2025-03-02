import 'package:flutter/material.dart';
import 'package:flutter_h3/flutter_h3.dart';
import 'dart:math';

// Main entry point for the Flutter H3 example app
void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Victoria Station polygon (covering the general station area)
  // The polygon must be closed (first and last points must be identical)
  final List<List<double>> victoriaStationPolygon = [
    [51.49455159458547, -0.1446546696172812], // Starting point 
    [51.49417708873512, -0.1433847336885552], // 
    [51.49506367987514, -0.1428248239074459], // 
    [51.49546415697182, -0.1431919795735559], // 
    [51.49565626552264, -0.1438897584222176], // 
    [51.49455159458547, -0.1446546696172812], // Back to start
  ];
  
  // Victoria Station approximate center point (calculated from polygon)
  final double victoriaLat = 51.49488255713804;
  final double victoriaLng = -0.1437692030418115;
  
  // Sample location (San Francisco)
  final double sfLat = 37.775938728915946;
  final double sfLng = -122.41795063018799;
  
  // H3 indices and data
  int? victoriaH3Index;
  String? victoriaH3String;
  List<int> victoriaStationCells = [];
  List<int> victoriaStationCellsExperimental = [];
  int victoriaPolygonResolution = 13; // Default resolution we're trying to use
  
  // San Francisco data
  int? sfH3Index;
  String? sfH3String;
  Map<String, double>? sfCenter;
  dynamic victoriaBoundary; // Use dynamic for now to debug type
  dynamic sfBoundary; // Use dynamic for now to debug type
  List<int> surroundingCells = [];
  List<int> childCells = [];
  int? parentIndex;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    
    try {
      // STEP 1: Convert a latitude/longitude coordinate to an H3 index
      // This demonstrates FlutterH3.latLngToCell
      final victoriaH3Index = FlutterH3.latLngToCell(victoriaLat, victoriaLng, 10);
      victoriaH3String = FlutterH3.h3ToString(victoriaH3Index);
      print('Victoria Station H3 Index (Resolution 10): $victoriaH3String');
      
      // STEP 2: Get the boundary of an H3 cell
      // This demonstrates FlutterH3.cellToBoundary
      victoriaBoundary = FlutterH3.cellToBoundary(victoriaH3Index);
      print('Victoria boundary type: ${victoriaBoundary.runtimeType}');
      print('Victoria boundary value: $victoriaBoundary');
      print('Victoria boundary length: ${victoriaBoundary?.length}');
      if (victoriaBoundary is List && victoriaBoundary.isNotEmpty) {
        print('First element type: ${victoriaBoundary[0].runtimeType}');
        print('First element value: ${victoriaBoundary[0]}');
      }
      
      // Print Victoria polygon coordinates for debug
      print('Victoria Station polygon:');
      for (var point in victoriaStationPolygon) {
        print('  [${point[0]}, ${point[1]}]');
      }
      
      // STEP 3: Convert a polygon to H3 cells at different resolutions
      // This demonstrates FlutterH3.polygonToCells
      for (int resolution = 9; resolution <= 15; resolution++) {
        print('Trying resolution $resolution for Victoria Station polygon...');
        try {
          List<int> cells = FlutterH3.polygonToCells(victoriaStationPolygon, null, resolution);
          print('✅ Resolution $resolution produced ${cells.length} cells');
          
          // Store cells if this is resolution 13
          if (resolution == 13) {
            victoriaStationCells = cells;
            victoriaPolygonResolution = 13; // Explicitly set to 13
            print('Found ${cells.length} cells at resolution 13');
            // Print first few cells for debugging
            if (cells.isNotEmpty) {
              print('Sample cells at resolution 13:');
              for (var cell in cells.take(5)) {
                print('  ${FlutterH3.h3ToString(cell)}');
              }
            }
          }
        } catch (e) {
          print('❌ Error at resolution $resolution: $e');
        }
      }
      
      // Only fall back to resolution 10 if we got no cells at resolution
      if (victoriaStationCells.isEmpty) {
        print('⚠️ No cells found at resolution 13, falling back to resolution 10');
        victoriaStationCells = FlutterH3.polygonToCells(victoriaStationPolygon, null, 10);
        victoriaPolygonResolution = 10;
        print('Fallback to resolution 10: ${victoriaStationCells.length} cells');
      }
      
      print('Final resolution being used: $victoriaPolygonResolution with ${victoriaStationCells.length} cells');
      
      // STEP 4: Use the experimental polygon-to-cells function with different flags
      // This demonstrates FlutterH3.polygonToCellsExperimental
      try {
        // Use flag 1 for full cell containment mode (more accurate but slower)
        List<int> experimentalCells = FlutterH3.polygonToCellsExperimental(
          victoriaStationPolygon, 
          null, 
          victoriaPolygonResolution, 
          1 // CONTAINMENT_FULL
        );
        victoriaStationCellsExperimental = experimentalCells;
        print('Found ${experimentalCells.length} cells with experimental algorithm (FULL containment)');
        
        // Use flag 2 for overlapping containment (any cell that overlaps the polygon)
        List<int> overlapCells = FlutterH3.polygonToCellsExperimental(
          victoriaStationPolygon, 
          null, 
          victoriaPolygonResolution, 
          2 // CONTAINMENT_OVERLAPPING
        );
        print('Found ${overlapCells.length} cells with experimental algorithm (OVERLAPPING containment)');
      } catch (e) {
        print('Error with experimental algorithm: $e');
      }
      
      // STEP 5: Demonstrate San Francisco examples
      // This shows more H3 functions
      final sfH3Index = FlutterH3.latLngToCell(sfLat, sfLng, 9);
      sfH3String = FlutterH3.h3ToString(sfH3Index);
      
      // Convert an H3 index back to its center lat/lng
      final sfCenterLatLng = FlutterH3.cellToLatLng(sfH3Index);
      if (sfCenterLatLng != null && sfCenterLatLng.length >= 2) {
        sfCenter = {
          'lat': sfCenterLatLng['lat'] ?? 0.0, 
          'lng': sfCenterLatLng['lng'] ?? 0.0
        };
      }
      
      // Get the boundary of the San Francisco cell
      sfBoundary = FlutterH3.cellToBoundary(sfH3Index);
      print('SF Boundary type: ${sfBoundary.runtimeType}');
      print('SF Boundary value: $sfBoundary');
      print('SF Boundary length: ${sfBoundary?.length}');
      if (sfBoundary is List && sfBoundary.isNotEmpty) {
        print('First element type: ${sfBoundary[0].runtimeType}');
        print('First element value: ${sfBoundary[0]}');
      }
      
      // Get surrounding cells (k-ring)
      surroundingCells = FlutterH3.gridDisk(sfH3Index, 1);
    
      // Get child cells at higher resolution
      childCells = FlutterH3.cellToChildren(sfH3Index, 10);
      if (childCells.length > 7) {
        childCells = childCells.sublist(0, 7);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error initializing H3: $e';
      });
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('H3 Indexing - Victoria Station'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Initialization Error',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(errorMessage!),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            errorMessage = null;
                          });
                          initState();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // VICTORIA STATION SECTION
                    _buildVictoriaStationSection(),
                    
                    const Divider(height: 40, thickness: 2),
                    
                    // SAN FRANCISCO SECTION (COLLAPSED/SECONDARY)
                    _buildHeader('Additional H3 Examples (San Francisco)'),
                    
                    _buildSection(
                      'San Francisco Location',
                      'Latitude: $sfLat\nLongitude: $sfLng',
                    ),
                    
                    if (sfH3Index != null) _buildSection(
                      'H3 Index (Resolution 9)',
                      'Integer: $sfH3Index\nString: ${sfH3String ?? "N/A"}',
                    ),
                    
                    if (sfCenter != null) _buildSection(
                      'Center Point',
                      'Latitude: ${sfCenter!['lat']}\nLongitude: ${sfCenter!['lng']}',
                    ),
                    
                    if (sfBoundary != null) _buildSection(
                      'Boundary',
                      _formatBoundaryPoints(sfBoundary!),
                    ),
                    
                    if (surroundingCells.isNotEmpty) _buildSection(
                      'Surrounding Cells (k=1)',
                      'Found ${surroundingCells.length} cells\nFirst few: ${surroundingCells.take(3).map((idx) => FlutterH3.h3ToString(idx)).join(", ")}...',
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Helper method to create section headers
  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  // Helper method to create a map preview placeholder
  Widget _buildVictoriaMapPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withOpacity(0.5), width: 2),
      ),
      child: const Center(
        child: Text(
          "Victoria Station, London\nH3 Grid Overlay",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Build the Victoria Station section with H3 cell data
  Widget _buildVictoriaStationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Victoria Station'),
        const SizedBox(height: 12),
        
        Text('Location: $victoriaLat, $victoriaLng'),
        Text('H3 Index (res 10): $victoriaH3String'),
        const SizedBox(height: 8),
        
        Text('H3 Cells (standard algorithm, res $victoriaPolygonResolution): ${victoriaStationCells.length}'),
        if (victoriaStationCells.isNotEmpty)
          Container(
            height: 150,
            child: ListView.builder(
              itemCount: min(victoriaStationCells.length, 5),
              itemBuilder: (context, index) {
                return Text('• ${FlutterH3.h3ToString(victoriaStationCells[index])}');
              },
            ),
          )
        else
          Text('No H3 cells found with standard algorithm'),
          
        const SizedBox(height: 12),
        
        Text('H3 Cells (experimental algorithm, res $victoriaPolygonResolution): ${victoriaStationCellsExperimental.length}'),
        if (victoriaStationCellsExperimental.isNotEmpty)
          Container(
            height: 150,
            child: ListView.builder(
              itemCount: min(victoriaStationCellsExperimental.length, 5),
              itemBuilder: (context, index) {
                return Text('• ${FlutterH3.h3ToString(victoriaStationCellsExperimental[index])}');
              },
            ),
          )
        else
          Text('No H3 cells found with experimental algorithm'),
      ],
    );
  }

  // Helper method to build a section with title and content
  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Format boundary points for display
  String _formatBoundaryPoints(dynamic boundary) {
    StringBuffer buffer = StringBuffer();
    if (boundary is List) {
      for (int i = 0; i < boundary.length; i++) {
        final item = boundary[i];
        if (item is List) {
          // If item is a list of doubles [lat, lng]
          if (item.length >= 2) {
            buffer.writeln('Point ${i + 1}: Lat: ${item[0].toStringAsFixed(6)}, Lng: ${item[1].toStringAsFixed(6)}');
          }
        } else if (item is Map) {
          // If item is a map with lat/lng keys
          if (item.containsKey('lat') && item.containsKey('lng')) {
            buffer.writeln('Point ${i + 1}: Lat: ${item['lat'].toStringAsFixed(6)}, Lng: ${item['lng'].toStringAsFixed(6)}');
          }
        } else if (item is double) {
          // If boundary is flat list of doubles [lat1, lng1, lat2, lng2, ...]
          if (i + 1 < boundary.length) {
            buffer.writeln('Point ${i ~/ 2 + 1}: Lat: ${item.toStringAsFixed(6)}, Lng: ${boundary[i+1].toStringAsFixed(6)}');
            i++; // Skip the lng value since we've used it
          }
        }
      }
    }
    return buffer.toString();
  }
}
