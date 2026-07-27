#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

void main() async {
  print('🧪 Testando APIs de Produção do GabiFlow\n');
  
  // Testar múltiplos tenants conhecidos
  final tenants = ['samuel', 'paulocamara', 'gabinete'];
  
  for (final tenant in tenants) {
    print('📍 Testando tenant: $tenant');
    await testTenantAPIs(tenant);
    print('');
  }
}

Future<void> testTenantAPIs(String subdomain) async {
  final baseUrl = 'https://$subdomain.gabiflow.com.br';
  
  // 1. Verificar tenant
  print('  ✓ Verificando tenant...');
  try {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('$baseUrl/api/check-tenant?subdomain=$subdomain'),
    );
    request.headers.add('Accept', 'application/json');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      print('    ✅ Tenant existe: ${data['exists']}');
      print('    📋 Tenant ID: ${data['tenantId']}');
    } else {
      print('    ❌ Erro: Status ${response.statusCode}');
    }
    client.close();
  } catch (e) {
    print('    ❌ Erro: $e');
  }
  
  // 2. Testar endpoint de login (sem credenciais reais, apenas verificar se responde)
  print('  ✓ Verificando endpoint de login...');
  try {
    final client = HttpClient();
    final request = await client.postUrl(
      Uri.parse('$baseUrl/api/auth/login'),
    );
    request.headers.add('Content-Type', 'application/json');
    request.headers.add('Accept', 'application/json');
    request.write(jsonEncode({
      'email': 'teste@teste.com',
      'password': 'teste123',
      'tenant_id': subdomain,
    }));
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 401) {
      print('    ✅ Endpoint de login respondendo (401 esperado para credenciais inválidas)');
    } else if (response.statusCode == 200) {
      print('    ✅ Endpoint de login funcionando');
    } else {
      print('    ⚠️  Status: ${response.statusCode}');
    }
    client.close();
  } catch (e) {
    print('    ❌ Erro: $e');
  }
  
  // 3. Testar endpoint mobile/dashboard (se existir)
  print('  ✓ Verificando endpoint mobile/dashboard...');
  try {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('$baseUrl/api/mobile/dashboard'),
    );
    request.headers.add('Accept', 'application/json');
    request.headers.add('X-Tenant-ID', subdomain);
    
    final response = await request.close();
    
    if (response.statusCode == 401) {
      print('    ✅ Endpoint mobile/dashboard protegido (requer autenticação)');
    } else if (response.statusCode == 200) {
      print('    ✅ Endpoint mobile/dashboard disponível');
    } else if (response.statusCode == 404) {
      print('    ⚠️  Endpoint mobile/dashboard não existe (usar fallback)');
    } else {
      print('    ⚠️  Status: ${response.statusCode}');
    }
    client.close();
  } catch (e) {
    print('    ❌ Erro: $e');
  }
}