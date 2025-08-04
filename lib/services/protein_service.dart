import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/protein.dart';
import 'package:flutter/services.dart';

class ProteinService {
  // Simulate fetching proteins from an API
  Future<List<Protein>> fetchProteins() async {
    final String fileContent = await rootBundle.loadString(
      'assets/ligands.txt',
    );
    final List<String> ligandIds = fileContent
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    List<Protein> proteins = [];

    for (int i = 0; i < ligandIds.length; i++) {
      print('Fetching protein for ligand ID: ${ligandIds[i]}');
      final String ligandId = ligandIds[i];
      try {
        final protein = await fetchProteinById(ligandId);
        proteins.add(protein);
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        proteins.add(
          Protein(
            name: ligandId,
            formula: 'Unknown',
            complete_name: 'Protein data could not be retrieved',
            atomCount: 0,
          ),
        );
      }
    }
    return proteins;
  }

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
    } catch (e) {
      print('API error for $ligandId: $e');
      return Protein(
        name: ligandId,
        formula: 'Unknown',
        complete_name: 'Protein data could not be retrieved',
        atomCount: 0,
      );
    }
    return Protein(
      name: ligandId,
      formula: 'Unknown',
      complete_name: 'Protein data could not be retrieved',
      atomCount: 0,
    );
  }

  // Search proteins by name
  Future<List<Protein>> searchProteins(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // if (query.isEmpty) {
    //   return _mockProteins;
    // }

    return _mockProteins
        .where(
          (protein) => protein.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
