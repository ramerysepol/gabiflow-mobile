import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Subdomain do tenant para teste
  const subdomain = 'samuel'; // Substitua pelo subdomain correto
  const baseUrl = 'https://$subdomain.gabiflow.com.br';
  
  // Token JWT (substitua pelo token real obtido após login)
  const token = 'SEU_TOKEN_AQUI';
  
  // Headers padrão
  final headers = {
    'Authorization': 'Bearer $token',
    'X-Tenant-ID': subdomain,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  print('Testando APIs do GabiFlow...\n');
  print('Base URL: $baseUrl\n');
  
  // Teste 1: Munícipes
  print('1. Testando API de Munícipes...');
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/constituents?limit=1'),
      headers: headers,
    );
    print('   Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('   ✓ API de munícipes funcionando');
      print('   Estrutura: ${data.keys.toList()}');
    } else {
      print('   ✗ Erro: ${response.body}');
    }
  } catch (e) {
    print('   ✗ Erro na requisição: $e');
  }
  
  // Teste 2: Demandas
  print('\n2. Testando API de Demandas...');
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/demands?limit=1'),
      headers: headers,
    );
    print('   Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('   ✓ API de demandas funcionando');
      print('   Estrutura: ${data.keys.toList()}');
    } else {
      print('   ✗ Erro: ${response.body}');
    }
  } catch (e) {
    print('   ✗ Erro na requisição: $e');
  }
  
  // Teste 3: Eventos
  print('\n3. Testando API de Eventos...');
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/events?limit=1'),
      headers: headers,
    );
    print('   Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('   ✓ API de eventos funcionando');
      print('   Estrutura: ${data.keys.toList()}');
    } else {
      print('   ✗ Erro: ${response.body}');
    }
  } catch (e) {
    print('   ✗ Erro na requisição: $e');
  }
  
  print('\nTeste concluído!');
  print('IMPORTANTE: Substitua o token e subdomain pelos valores reais antes de executar.');
}