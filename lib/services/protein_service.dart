import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/protein.dart';

class ProteinService {
  // Your existing function for basic protein info
  Future<Protein> fetchProteinById(String ligandId) async {
    try {
      final response = await http.get(
        Uri.parse('https://data.rcsb.org/rest/v1/core/chemcomp/$ligandId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Protein(
          name: jsonData['chem_comp']?['id'],
          formula: jsonData['chem_comp']?['formula'],
          complete_name: jsonData['chem_comp']?['name'],
          atomCount: jsonData['rcsb_chem_comp_info']?['atom_count'],
        );
      }
      throw Exception('Failed to load protein data for $ligandId');
    } catch (e) {
      print('API error for $ligandId: $e');
      throw Exception('Failed to load protein data for $ligandId');
    }
  }

  Future<String?> fetchLigandSDF(String ligandId) async {
    final url = 'https://files.rcsb.org/ligands/view/${ligandId}_ideal.sdf';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        print('Successfully fetched SDF for $ligandId');
        return response.body;
      } else {
        print('Failed to fetch SDF: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching ligand SDF: $e');
      return null;
    }
  }
}
