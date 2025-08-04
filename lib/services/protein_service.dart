import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/protein.dart';

class ProteinService {
  // Mock data for demonstration - replace with actual API calls
  static final List<Protein> _mockProteins = [
    const Protein(
      name: 'Insulin',
      formula: 'C254H377N65O75S6',
      description: 'A hormone that regulates blood sugar levels',
      atomCount: 777,
    ),
    const Protein(
      name: 'Hemoglobin',
      formula: 'C2952H4664N812O832S8Fe4',
      description: 'Oxygen-carrying protein in red blood cells',
      atomCount: 9272,
    ),
    const Protein(
      name: 'Collagen',
      formula: 'C4300H6600N1200O1300',
      description: 'Structural protein found in connective tissues',
      atomCount: 13400,
    ),
    const Protein(
      name: 'DNA Polymerase',
      formula: 'C1500H2400N400O450S12',
      description: 'Enzyme responsible for DNA replication',
      atomCount: 4762,
    ),
  ];

  // Simulate fetching proteins from an API
  Future<List<Protein>> fetchProteins() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // In a real app, you would make an HTTP request here:
    // final response = await http.get(Uri.parse('https://api.example.com/proteins'));
    // if (response.statusCode == 200) {
    //   final List<dynamic> jsonData = json.decode(response.body);
    //   return jsonData.map((json) => Protein.fromJson(json)).toList();
    // } else {
    //   throw Exception('Failed to load proteins');
    // }
    
    return _mockProteins;
  }

  // Search proteins by name
  Future<List<Protein>> searchProteins(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (query.isEmpty) {
      return _mockProteins;
    }
    
    return _mockProteins
        .where((protein) => 
            protein.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
