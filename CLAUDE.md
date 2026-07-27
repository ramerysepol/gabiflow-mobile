# 📱 GabiFlow Mobile - Diretrizes do Projeto

## ⚠️ REGRAS CRÍTICAS - NUNCA VIOLAR
1. **NUNCA ALTERAR TABELAS DO BANCO DE DADOS** - O app mobile é apenas cliente
2. **NUNCA MODIFICAR APIs DO BACKEND** - Usar apenas as APIs existentes
3. **SEMPRE CONSULTAR** a tabela `system_tenants` no banco `dados_eleitorais` para validar tenants
4. **BACKEND LOCALIZAÇÃO**: `/Users/iremarlopes/Desktop/gabiflow-local`
5. **NUNCA CRIAR OU MODIFICAR ARQUIVOS NO DIRETÓRIO gabiflow-local** - Este diretório contém o sistema desktop e não deve ser alterado
6. **NUNCA USAR DADOS MOCK** - Sempre usar dados reais do banco de dados através das APIs do backend
7. **SEMPRE VERIFICAR AS ROTAS CORRETAS DAS APIs** - Consultar a estrutura real em gabiflow-local/app/api
8. **NUNCA ATUALIZAR APIs EXISTENTES EM gabiflow-local** - Se precisar criar alguma API nova, criar apenas em `/api/mobile/`

## 🎯 Visão Geral
O GabiFlow Mobile é o aplicativo móvel complementar ao sistema web GabiFlow, desenvolvido em Flutter para oferecer acesso rápido e funcionalidades otimizadas para dispositivos móveis aos gabinetes parlamentares.

## 🏢 Arquitetura de Integração com Backend Existente

### Informações do Backend GabiFlow Desktop
- **Localização**: `/Users/iremarlopes/Desktop/gabiflow-local`
- **Stack**: Next.js, Node.js, PostgreSQL
- **Multi-tenant**: Por subdomínio (ex: samuel.gabiflow.com.br)
- **Autenticação**: JWT com access_token e refresh_token
- **Banco Principal**: PostgreSQL em 192.168.40.50:5432
- **Bancos**:
  - `dados_eleitorais`: Banco universal com tabela `system_tenants`
  - `gabiflow_{tenant}`: Banco individual por gabinete

### Tabela system_tenants (banco dados_eleitorais)
```sql
CREATE TABLE system_tenants (
  id VARCHAR(50) PRIMARY KEY,
  subdomain VARCHAR(100) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  parlamentar_nome VARCHAR(255) NOT NULL,
  parlamentar_cargo VARCHAR(100) NOT NULL,
  parlamentar_partido VARCHAR(50),
  parlamentar_estado CHAR(2),
  parlamentar_municipio VARCHAR(255),
  theme_primary_color VARCHAR(7) DEFAULT '#2563eb',
  theme_logo_url VARCHAR(500),
  database_name VARCHAR(100) NOT NULL,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  extra_config JSONB DEFAULT '{}'::jsonb
);
```

## 🔐 Fluxo de Autenticação Multi-tenant Mobile

### Primeiro Acesso
1. **Tela de Configuração Inicial**:
   - Solicitar URL do tenant (ex: `samuel.gabiflow.com.br`)
   - Extrair subdomain da URL
   - Consultar tabela `system_tenants` no banco `dados_eleitorais`
   - Validar se tenant existe e está ativo
   - Salvar configuração local (SecureStorage)

2. **Login do Usuário**:
   - Email e senha
   - Enviar para `/api/auth/login` com tenant_id
   - Receber JWT tokens (access e refresh)
   - Salvar tokens no SecureStorage

3. **Requisições Autenticadas**:
   - Incluir header `Authorization: Bearer {access_token}`
   - Incluir header `X-Tenant-ID: {tenant_id}`
   - Auto-renovar token quando necessário

### Mudança de Tenant
- Limpar dados do app ou reinstalar
- Processo garante isolamento completo entre tenants

## 🏗️ Arquitetura e Estrutura

### Stack Tecnológica
- **Framework**: Flutter 3.x
- **Linguagem**: Dart
- **Gerenciamento de Estado**: Provider + Riverpod
- **Armazenamento Local**: Hive/SharedPreferences
- **HTTP Client**: Dio com interceptors
- **Autenticação**: JWT com refresh token
- **Push Notifications**: Firebase Cloud Messaging

### Estrutura de Pastas
```
gabiflow-mobile/
├── lib/
│   ├── main.dart                 # Entrada da aplicação
│   ├── app.dart                  # Configuração do app
│   ├── config/
│   │   ├── api_config.dart       # URLs e configurações da API
│   │   ├── theme.dart            # Tema e cores
│   │   └── constants.dart        # Constantes do app
│   ├── models/
│   │   ├── user_model.dart       # Modelo de usuário
│   │   ├── constituent_model.dart # Modelo de munícipe
│   │   ├── demand_model.dart     # Modelo de demanda
│   │   ├── event_model.dart      # Modelo de evento
│   │   └── tenant_model.dart     # Modelo de tenant
│   ├── services/
│   │   ├── api/
│   │   │   ├── auth_service.dart
│   │   │   ├── constituent_service.dart
│   │   │   ├── demand_service.dart
│   │   │   └── base_service.dart
│   │   ├── storage/
│   │   │   ├── secure_storage.dart
│   │   │   └── cache_service.dart
│   │   └── native/
│   │       ├── biometric_service.dart
│   │       └── notification_service.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── tenant_provider.dart
│   │   └── sync_provider.dart
│   ├── screens/
│   │   ├── splash/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── constituents/
│   │   ├── demands/
│   │   ├── events/
│   │   └── settings/
│   ├── widgets/
│   │   ├── common/
│   │   ├── forms/
│   │   └── cards/
│   └── utils/
│       ├── validators.dart
│       ├── formatters.dart
│       └── helpers.dart
├── assets/
│   ├── images/
│   ├── fonts/
│   └── icons/
├── test/
├── android/
├── ios/
└── pubspec.yaml
```

## 🔌 Integração com APIs Existentes

### Base URL Configuration
```dart
class ApiConfig {
  // Desenvolvimento
  static const String devBaseUrl = 'http://192.168.40.50:3001';
  static const String devWsUrl = 'ws://192.168.40.50:3001';
  
  // Produção
  static const String prodBaseUrl = 'https://gabiflow.com.br';
  static const String prodWsUrl = 'wss://gabiflow.com.br';
  
  // Headers padrão
  static Map<String, String> headers(String? token, String? tenantId) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
    if (tenantId != null) 'X-Tenant-ID': tenantId,
  };
}
```

### APIs Disponíveis para Integração (Backend Existente)

#### 1. **Verificação de Tenant** (`/api/check-tenant/`)
- `GET /?subdomain={subdomain}` - Verifica se tenant existe
  - Response: `{ exists: boolean, tenant?: {...} }`

#### 2. **Autenticação** (`/api/auth/`)
- `POST /login` - Login com email/senha
  - Body: `{ email, password, tenant_id }`
  - Response: `{ access_token, refresh_token, user }`
- `POST /logout` - Logout
- `POST /refresh` - Renovar token
  - Body: `{ refresh_token }`
- `GET /me` - Dados do usuário logado
  - Headers: `Authorization: Bearer {token}`

#### 3. **Gestão de Munícipes** (`/api/constituents/`)
- `GET /` - Listar munícipes (com paginação)
  - Query: `page, limit, search`
- `POST /` - Criar munícipe
- `GET /{id}` - Detalhes do munícipe
- `PUT /{id}` - Atualizar munícipe
- `DELETE /{id}` - Remover munícipe
- `GET /tags` - Listar tags disponíveis
- `POST /labels` - Gerar etiquetas

#### 4. **Demandas** (`/api/demands/`)
- `GET /` - Listar demandas
  - Query: `status, priority, constituent_id`
- `POST /` - Criar demanda
- `GET /{id}` - Detalhes da demanda
- `PUT /{id}` - Atualizar demanda
- `POST /{id}/notes` - Adicionar nota
- `POST /{id}/attachments` - Adicionar anexo
- `GET /{id}/activities` - Histórico de atividades

#### 5. **Agenda/Eventos** (`/api/events/`)
- `GET /` - Listar eventos
  - Query: `start_date, end_date`
- `POST /` - Criar evento
- `GET /{id}` - Detalhes do evento
- `PUT /{id}` - Atualizar evento
- `DELETE /{id}` - Remover evento

#### 6. **Comunicação WhatsApp** (`/api/whatsapp/`)
- `POST /send` - Enviar mensagem WhatsApp
  - Body: `{ to, message, template_id? }`

#### 7. **Templates WhatsApp** (`/api/settings/whatsapp-templates/`)
- `GET /` - Listar templates
- `POST /` - Criar template
- `PUT /{id}` - Atualizar template
- `DELETE /{id}` - Remover template

#### 8. **Inteligência Artificial** (`/api/ai/`)
- `POST /suggest` - Obter sugestões
  - Body: `{ context, type }`
- `POST /analyze` - Analisar texto
  - Body: `{ text, analysis_type }`
- `POST /whatsapp-message` - Gerar mensagem
  - Body: `{ context, tone, recipient_name }`
- `POST /correct-portuguese` - Correção ortográfica
  - Body: `{ text }`

#### 9. **Dashboard** (`/api/dashboard/`)
- `GET /` - Métricas do dashboard
  - Response: estatísticas de demandas, munícipes, eventos

#### 10. **Usuários** (`/api/users/`)
- `GET /` - Listar usuários do gabinete
- `POST /` - Criar novo usuário
- `PUT /{id}` - Atualizar usuário
- `GET /me/permissions` - Permissões do usuário atual

## 📱 Funcionalidades do App

### 1. **Módulo de Autenticação**
- [ ] Login com email/senha
- [ ] Login com biometria (após primeiro acesso)
- [ ] Recuperação de senha
- [ ] Detecção automática de tenant
- [ ] Modo offline com cache de credenciais

### 2. **Dashboard Principal**
- [ ] Cards com resumo do dia
- [ ] Atalhos para ações rápidas
- [ ] Notificações pendentes
- [ ] Gráficos de desempenho
- [ ] Busca global

### 3. **Gestão de Munícipes**
- [ ] Lista com busca e filtros
- [ ] Cadastro rápido com câmera
- [ ] Importação de contatos
- [ ] QR Code para identificação
- [ ] Histórico de interações
- [ ] Etiquetas e categorização

### 4. **Gestão de Demandas**
- [ ] Lista com status visuais
- [ ] Criação com fotos/áudio
- [ ] Geolocalização automática
- [ ] Timeline de atualizações
- [ ] Notificações de mudanças
- [ ] Modo offline com sync

### 5. **Agenda Inteligente**
- [ ] Visualização dia/semana/mês
- [ ] Sincronização com calendário nativo
- [ ] Lembretes automáticos
- [ ] Check-in em eventos
- [ ] Navegação para local
- [ ] Lista de presença

### 6. **Comunicação**
- [ ] Envio de WhatsApp individual
- [ ] Envio em massa
- [ ] Templates personalizados
- [ ] Histórico de mensagens
- [ ] Agendamento de envios

### 7. **Recursos Especiais**
- [ ] Modo Evento (cadastro em massa)
- [ ] Scanner de documentos
- [ ] Gravador de notas de voz
- [ ] Compartilhamento rápido
- [ ] Widget para tela inicial

### 8. **Configurações**
- [ ] Perfil do usuário
- [ ] Preferências de notificação
- [ ] Tema claro/escuro
- [ ] Sincronização
- [ ] Sobre e ajuda

## 🔐 Segurança e Multi-tenant

### Fluxo de Autenticação
1. **Login Inicial**:
   - Usuário informa email/senha
   - App detecta tenant pelo email
   - Conecta ao banco específico
   - Retorna JWT + refresh token

2. **Persistência**:
   - Tokens salvos em secure storage
   - Biometria para acesso rápido
   - Auto-refresh antes de expirar

3. **Multi-tenant**:
   - Tenant ID em todas requisições
   - Isolamento completo de dados
   - Cache separado por tenant

### Segurança de Dados
```dart
// Exemplo de serviço seguro
class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }
  
  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
  
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

## 💾 Estratégia Offline

### Sincronização Inteligente
1. **Cache de Dados**:
   - Últimos 100 munícipes acessados
   - Demandas abertas
   - Agenda dos próximos 7 dias

2. **Fila de Operações**:
   - Operações salvas localmente
   - Sync automático ao conectar
   - Resolução de conflitos

3. **Indicadores Visuais**:
   - Status de sincronização
   - Dados offline marcados
   - Última atualização

## 🎨 Design e UX

### Princípios de Design
- **Material Design 3**: Seguir guidelines do Google
- **Cores do Tenant**: Personalização por gabinete
- **Acessibilidade**: Fontes ajustáveis, alto contraste
- **Responsivo**: Adaptar a tablets

### Tema Base
```dart
class AppTheme {
  static ThemeData lightTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      fontFamily: 'Inter',
    );
  }
  
  static ThemeData darkTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Inter',
    );
  }
}
```

## 📦 Dependências Principais

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.0
  riverpod: ^2.4.0
  
  # HTTP & API
  dio: ^5.3.0
  retrofit: ^4.0.0
  
  # Storage
  hive: ^2.2.0
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.0
  
  # UI Components
  flutter_native_splash: ^2.3.0
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  
  # Utilities
  intl: ^0.18.0
  url_launcher: ^6.2.0
  image_picker: ^1.0.0
  
  # Native Features
  local_auth: ^2.1.0
  geolocator: ^10.1.0
  permission_handler: ^11.0.0
  
  # Notifications
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.1.0
```

## 📋 Modelos de Dados (Baseados no Sistema Existente)

### User Model
```dart
class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String tenant;
  final String? avatar;
  final DateTime createdAt;
  
  // Construtor e métodos...
}
```

### Constituent Model
```dart
class Constituent {
  final int id;
  final String name;
  final String? cpf;
  final String? email;
  final String? phone;
  final String? whatsapp;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? notes;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Construtor e métodos...
}
```

### Demand Model
```dart
class Demand {
  final int id;
  final int constituentId;
  final String title;
  final String description;
  final String status; // pending, in_progress, completed, cancelled
  final String priority; // low, medium, high, urgent
  final String? category;
  final int? assignedToId;
  final DateTime? deadline;
  final List<DemandNote> notes;
  final List<DemandAttachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Construtor e métodos...
}
```

### Event Model
```dart
class Event {
  final int id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final String? type;
  final List<int> participantIds;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Construtor e métodos...
}
```

### Tenant Model
```dart
class Tenant {
  final String id;
  final String subdomain;
  final String name;
  final String parlamentarNome;
  final String parlamentarCargo;
  final String? parlamentarPartido;
  final String? parlamentarEstado;
  final String? parlamentarMunicipio;
  final String themePrimaryColor;
  final String? themeLogoUrl;
  final String databaseName;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Construtor e métodos...
}
```

## 🚀 Roadmap de Desenvolvimento

### Fase 1: MVP (8 semanas)
- [ ] Setup inicial Flutter e estrutura de pastas
- [ ] Tela de configuração inicial (tenant URL)
- [ ] Integração com API de verificação de tenant
- [ ] Autenticação JWT (login/logout/refresh)
- [ ] Dashboard com métricas básicas
- [ ] Lista e busca de munícipes
- [ ] Cadastro básico de munícipes
- [ ] Lista e filtros de demandas
- [ ] Criação e edição de demandas
- [ ] Sincronização básica online

### Fase 2: Recursos Essenciais (6 semanas)
- [ ] Agenda e eventos
- [ ] Integração WhatsApp
- [ ] Modo offline completo
- [ ] Notificações push
- [ ] Busca e filtros

### Fase 3: Recursos Avançados (6 semanas)
- [ ] Modo evento
- [ ] IA integrada
- [ ] Analytics
- [ ] Widgets
- [ ] Personalização por tenant

### Fase 4: Polish e Lançamento (4 semanas)
- [ ] Testes extensivos
- [ ] Otimizações
- [ ] Documentação
- [ ] Deploy nas lojas
- [ ] Treinamento

## 🧪 Estratégia de Testes

### Tipos de Testes
1. **Unitários**: Services e utils
2. **Widgets**: Componentes isolados
3. **Integração**: Fluxos completos
4. **E2E**: Casos de uso reais

### Cobertura Mínima
- 80% para services
- 70% para widgets
- 90% para utils

## 📱 Publicação nas Lojas

### Google Play Store
- [ ] Conta developer ($25)
- [ ] Screenshots e descrições
- [ ] Classificação etária
- [ ] Políticas de privacidade

### Apple App Store
- [ ] Conta developer ($99/ano)
- [ ] Certificados e provisioning
- [ ] App Store Connect
- [ ] Review guidelines

## 🔧 Scripts Úteis

```bash
# Desenvolvimento
flutter run                          # Rodar em debug
flutter run --release               # Rodar em release
flutter build apk --release         # Build Android
flutter build ios --release         # Build iOS

# Testes
flutter test                        # Rodar testes
flutter test --coverage             # Com cobertura

# Análise
flutter analyze                     # Análise estática
flutter format .                    # Formatar código

# Limpeza
flutter clean                       # Limpar build
flutter pub cache repair            # Reparar cache
```

## 📞 Contatos e Suporte

- **Documentação API**: https://api.gabiflow.com.br/docs
- **Status do Sistema**: https://status.gabiflow.com.br
- **Suporte**: suporte@gabiflow.com.br

## 🔧 Configuração de Desenvolvimento

### Ambiente de Desenvolvimento
```bash
# 1. Clonar o projeto
git clone https://github.com/gabiflow/gabiflow-mobile.git
cd gabiflow-mobile

# 2. Instalar dependências
flutter pub get

# 3. Configurar variáveis de ambiente
cp .env.example .env
# Editar .env com as URLs corretas

# 4. Rodar o app
flutter run
```

### Arquivo .env
```
# Desenvolvimento
DEV_API_URL=http://192.168.40.50:3001
DEV_WS_URL=ws://192.168.40.50:3001

# Produção
PROD_API_URL=https://gabiflow.com.br
PROD_WS_URL=wss://gabiflow.com.br

# Configurações
ENVIRONMENT=development
API_TIMEOUT=30000
```

## 📝 Processo de Desenvolvimento Sugerido

### 1. Configuração Inicial do Tenant
```dart
class TenantSetupScreen extends StatefulWidget {
  // Tela mostrada apenas no primeiro acesso
  // Campo para inserir URL do tenant (ex: samuel.gabiflow.com.br)
  // Botão "Verificar e Configurar"
  // Validação via API /api/check-tenant
  // Salvar configuração no SecureStorage
}
```

### 2. Fluxo de Login
```dart
class LoginScreen extends StatefulWidget {
  // Mostrar logo e nome do gabinete (do tenant configurado)
  // Campos email e senha
  // Botão login chama POST /api/auth/login
  // Salvar tokens no SecureStorage
  // Redirecionar para Dashboard
}
```

### 3. Interceptor HTTP para Autenticação
```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Adicionar access_token no header Authorization
    // Adicionar tenant_id no header X-Tenant-ID
    // Continuar requisição
  }
  
  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    // Se erro 401, tentar refresh token
    // Se refresh falhar, redirecionar para login
  }
}
```

### 4. Service de API Base
```dart
class ApiService {
  late Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: Environment.apiUrl,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
    ));
    
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LogInterceptor());
  }
  
  // Métodos genéricos GET, POST, PUT, DELETE
}
```

## 🎯 Resumo do Planejamento

### Arquitetura
- **Frontend**: Flutter com Provider/Riverpod para gerenciamento de estado
- **Backend**: APIs existentes do GabiFlow Desktop (não modificar)
- **Banco**: PostgreSQL existente (apenas consulta via APIs)
- **Autenticação**: JWT com tokens salvos localmente

### Fluxo Principal
1. **Primeiro Acesso**: Configurar URL do tenant
2. **Validação**: Verificar tenant na tabela system_tenants
3. **Login**: Autenticação JWT com tenant_id
4. **Uso**: Todas requisições incluem token e tenant_id
5. **Mudança de Tenant**: Limpar dados ou reinstalar

### Pontos Críticos
- Nunca alterar estrutura do banco de dados
- Nunca modificar APIs do backend
- Sempre incluir X-Tenant-ID nas requisições
- Manter isolamento completo entre tenants
- Usar SecureStorage para dados sensíveis

## 🎨 Design System Ultra-Moderno

### Filosofia de Design
- **Neumorfismo 2.0**: Sombras suaves e elementos flutuantes
- **Glassmorphism**: Transparências e blur effects elegantes
- **Material You (Material 3)**: Design adaptativo com cores dinâmicas
- **Microinterações**: Animações fluidas em cada toque
- **Dark Mode Nativo**: Interface adaptável ao sistema

### Tecnologias de Ponta
- **Flutter 3.24+** com Dart 3.5
- **Riverpod 2.5** com Generators
- **Dio 5.x** para HTTP com interceptors
- **Hive** para cache local
- **Flutter Secure Storage** para dados sensíveis
- **Lottie** para animações complexas
- **FL Chart** para gráficos interativos
- **Google ML Kit** para OCR e reconhecimento
- **WebSocket** para real-time updates

## 📱 Interfaces e Funcionalidades Detalhadas

### 1. Splash Screen
- Logo animado com Lottie
- Progress indicator com shimmer effect
- Verificação automática de tenant salvo

### 2. Configuração de Tenant
- Input field com autocomplete
- QR Code scanner para configuração rápida
- Validação em tempo real via API
- Animações de sucesso/erro

### 3. Login
- Campos com validação visual
- Biometria após primeiro login
- Remember me com secure storage
- Animação de loading personalizada

### 4. Dashboard
- Cards neumórficos com estatísticas
- Gráficos animados e interativos
- Pull to refresh com animação
- FAB expandível para ações rápidas

### 5. Munícipes
- Lista com lazy loading
- Search com debounce e AI suggestions
- Swipe actions (WhatsApp, ligar, editar)
- Filtros por tags e localização

### 6. Demandas
- Kanban board com drag & drop
- Timeline visual de atividades
- Upload de múltiplos arquivos
- Geolocalização automática

### 7. Agenda
- Calendar widget customizado
- Sincronização com calendário nativo
- Notificações inteligentes
- Check-in por geofencing

### 8. Financeiro
- Dashboard com gráficos 3D
- Categorização automática
- Exportação de relatórios
- Previsões com ML

## 🚀 Plano de Desenvolvimento Sequencial

### FASE 1: FUNDAÇÃO (Semana 1-2)
#### Etapa 1.1: Setup e Arquitetura
- [ ] Criar projeto Flutter com estrutura Clean Architecture
- [ ] Configurar flavors (dev, staging, prod)
- [ ] Setup de dependências base
- [ ] Configurar análise estática e linting
- [ ] Criar estrutura de pastas

#### Etapa 1.2: Core e Configurações
- [ ] Implementar gerenciamento de ambiente (.env)
- [ ] Criar constants e configurações
- [ ] Setup do tema dinâmico (Material You)
- [ ] Implementar design tokens
- [ ] Criar widgets base (cards, buttons, inputs)

#### Etapa 1.3: Serviços Base
- [ ] Implementar Dio com interceptors
- [ ] Criar serviço de storage seguro
- [ ] Setup do Hive para cache
- [ ] Implementar logger personalizado
- [ ] Criar error handling global

### FASE 2: AUTENTICAÇÃO (Semana 3-4)
#### Etapa 2.1: Tenant Configuration
- [ ] Tela de configuração de tenant
- [ ] Integração com API check-tenant
- [ ] Salvar configuração local
- [ ] QR Code scanner
- [ ] Validações e feedback visual

#### Etapa 2.2: Login Flow
- [ ] Tela de login com design moderno
- [ ] Integração com API de autenticação
- [ ] Gerenciamento de tokens JWT
- [ ] Implementar refresh token
- [ ] Setup biometria

#### Etapa 2.3: Session Management
- [ ] Auto-login com tokens salvos
- [ ] Logout e limpeza de dados
- [ ] Middleware de autenticação
- [ ] Tratamento de sessão expirada
- [ ] Deep linking para login

### FASE 3: DASHBOARD E NAVEGAÇÃO (Semana 5-6)
#### Etapa 3.1: Estrutura Principal
- [ ] Bottom navigation customizada
- [ ] Drawer com informações do usuário
- [ ] Sistema de rotas com go_router
- [ ] Animações de transição
- [ ] Scaffold base reutilizável

#### Etapa 3.2: Dashboard
- [ ] Cards de estatísticas animados
- [ ] Integração com API dashboard
- [ ] Gráficos interativos
- [ ] Pull to refresh
- [ ] Skeleton loading

#### Etapa 3.3: Notificações
- [ ] Setup Firebase Cloud Messaging
- [ ] Notification handler
- [ ] Badge counter
- [ ] Local notifications
- [ ] Preferências de notificação

### FASE 4: MÓDULO MUNÍCIPES (Semana 7-9)
#### Etapa 4.1: Listagem
- [ ] Lista infinita com pagination
- [ ] Search com debounce
- [ ] Filtros avançados
- [ ] Ordenação dinâmica
- [ ] Export para PDF/Excel

#### Etapa 4.2: Detalhes e CRUD
- [ ] Tela de detalhes com Hero animation
- [ ] Formulário de cadastro/edição
- [ ] Upload de documentos
- [ ] Validações complexas
- [ ] Histórico de interações

#### Etapa 4.3: Recursos Avançados
- [ ] QR Code para cadastro rápido
- [ ] Importação de contatos
- [ ] Geolocalização e mapa
- [ ] Tags e categorização
- [ ] Comunicação direta (WhatsApp/Call)

### FASE 5: MÓDULO DEMANDAS (Semana 10-12)
#### Etapa 5.1: Listagem e Kanban
- [ ] View alternável (lista/kanban)
- [ ] Drag and drop entre status
- [ ] Filtros por prioridade/status
- [ ] Timeline de atividades
- [ ] Badges e indicadores visuais

#### Etapa 5.2: CRUD de Demandas
- [ ] Formulário com campos dinâmicos
- [ ] Upload múltiplo de arquivos
- [ ] Editor de texto rico
- [ ] Vinculação com munícipe
- [ ] Sistema de notas

#### Etapa 5.3: Features Avançadas
- [ ] Sugestões por IA
- [ ] Templates de demanda
- [ ] Workflow customizável
- [ ] Notificações de mudanças
- [ ] Relatórios e métricas

### FASE 6: MÓDULO AGENDA (Semana 13-14)
#### Etapa 6.1: Calendário
- [ ] Calendar widget customizado
- [ ] Visualizações dia/semana/mês
- [ ] Sincronização com calendário nativo
- [ ] Drag to reschedule
- [ ] Recurring events

#### Etapa 6.2: Eventos
- [ ] CRUD de eventos
- [ ] Convites e participantes
- [ ] Lembretes customizáveis
- [ ] Check-in automático
- [ ] Anexos e documentos

### FASE 7: MÓDULOS COMPLEMENTARES (Semana 15-17)
#### Etapa 7.1: Colaboradores
- [ ] Lista de usuários do gabinete
- [ ] Perfis e permissões
- [ ] Status online/offline
- [ ] Chat interno básico
- [ ] Atribuição de tarefas

#### Etapa 7.2: Financeiro
- [ ] Dashboard financeiro
- [ ] Lançamentos e categorias
- [ ] Gráficos e relatórios
- [ ] Exportação de dados
- [ ] Previsões básicas

#### Etapa 7.3: Dados Eleitorais
- [ ] Consulta de candidatos
- [ ] Resultados por região
- [ ] Análises e gráficos
- [ ] Mapas interativos
- [ ] Cache inteligente

### FASE 8: RECURSOS AVANÇADOS (Semana 18-19)
#### Etapa 8.1: Offline Mode
- [ ] Sync engine robusto
- [ ] Conflict resolution
- [ ] Queue de operações
- [ ] Indicadores de sync
- [ ] Background sync

#### Etapa 8.2: AI/ML Features
- [ ] OCR para documentos
- [ ] Sugestões inteligentes
- [ ] Análise preditiva
- [ ] Classificação automática
- [ ] Voice commands

### FASE 9: POLIMENTO (Semana 20-21)
#### Etapa 9.1: Performance
- [ ] Otimização de imagens
- [ ] Lazy loading avançado
- [ ] Code splitting
- [ ] Memory profiling
- [ ] Battery optimization

#### Etapa 9.2: UX/UI Polish
- [ ] Micro-interações
- [ ] Animações refinadas
- [ ] Feedback háptico
- [ ] Accessibility (a11y)
- [ ] Onboarding tutorial

### FASE 10: LANÇAMENTO (Semana 22-24)
#### Etapa 10.1: Testes
- [ ] Unit tests (>80% coverage)
- [ ] Widget tests
- [ ] Integration tests
- [ ] E2E tests
- [ ] Beta testing

#### Etapa 10.2: Deploy
- [ ] Build optimization
- [ ] App signing
- [ ] Store listings
- [ ] Screenshots e vídeos
- [ ] Launch campaign

## 📊 Métricas de Sucesso
- Performance: 60fps constantes
- Crash-free rate: >99.5%
- App size: <50MB
- Offline capability: 100%
- User satisfaction: >4.5 estrelas

---

*Este documento serve como guia completo para o desenvolvimento do GabiFlow Mobile, garantindo consistência com o sistema web e aproveitamento máximo das APIs existentes.*
*Atualizado em: 04/08/2025*

## ⚠️ CUIDADOS EXTREMOS COM O BACKEND

### Regras Fundamentais
1. **NUNCA** alterar a estrutura existente do sistema desktop em gabiflow-local
2. **NUNCA** modificar endpoints existentes que são usados pelo sistema desktop
3. **NUNCA** alterar esquemas de banco de dados ou tabelas existentes
4. **NUNCA** modificar arquivos fora da pasta `/api/mobile/` em gabiflow-local

### 📍 LOCALIZAÇÃO DOS ENDPOINTS MOBILE
**IMPORTANTE**: Os endpoints específicos do mobile estão localizados em:
- **Diretório**: `/Users/iremarlopes/Desktop/gabiflow-local/app/api/mobile/`
- **Estrutura atual**:
  - `/api/mobile/dashboard/route.ts` - Dashboard mobile (GET)

### Criação de Endpoints para Mobile
- Endpoints exclusivos para o app mobile devem ser criados em rotas separadas: `/api/mobile/*`
- Sempre garantir que modificações no backend não afetem o funcionamento do sistema desktop
- Testar extensivamente antes de publicar qualquer mudança
- Qualquer endpoint novo deve ser isolado e não interferir com rotas existentes
- Usar os mesmos middlewares de autenticação e multi-tenant existentes
- Documentar claramente que o endpoint é exclusivo para mobile
- **TODOS OS ENDPOINTS MOBILE DEVEM SER CRIADOS DENTRO DE**: `/Users/iremarlopes/Desktop/gabiflow-local/app/api/mobile/`

### Endpoints Mobile Existentes
1. **Dashboard Mobile** - `GET /api/mobile/dashboard`
   - Retorna estatísticas consolidadas para o dashboard do app
   - Inclui: totalConstituents, newConstituentsToday, totalDemands, openDemands, resolvedDemandsToday, upcomingEvents, eventsThisWeek, messagestoday, messagesSent, recentActivities

2. **IA Command Center Eleitoral** - `/api/mobile/eleitoral/ia/*` (todos com `authenticateMobile`)
   - `POST /api/mobile/eleitoral/ia/chat` — chat streaming SSE com tool use (reutiliza `runEleitoralChat` de `lib/ai/eleitoral-ia`). Body: `{ pergunta, contexto?, historico? }`. Eventos: thinking, tool_use, tool_result, text_delta, visualization, done, error
   - `GET /api/mobile/eleitoral/ia/briefing?sequencial=&ano=&uf=` — briefing territorial (stats, top municípios, mesorregiões, gabinete, oportunidades)
   - `GET /api/mobile/eleitoral/ia/insight-dia?sequencial=&ano=` — insight diário gerado por IA
   - `GET /api/mobile/eleitoral/ia/alertas?sequencial=&ano=` — alertas cruzando TSE × gabinete
   - `GET /api/mobile/eleitoral/ia/radar-territorial?sequencial=&ano=` — score de influência por município
   - No Flutter: feature `lib/features/command_center/` (rotas `/home/eleitoral/ia` e `/home/eleitoral/ia/chat`)

3. **Análise e Partidos** (paridade com o dashboard desktop)
   - `GET /api/mobile/eleitoral/estatisticas?ano=&estado=&cargo=` — KPIs, gênero, situação, ranking de partidos, mais votados
   - `GET /api/mobile/eleitoral/partido/{sigla}?ano=&estado=&cargo=` — detalhe do partido (totais, gênero, top candidatos, top municípios)
   - No Flutter: `AnalisePage` (`/home/eleitoral/analise`), `PartidoDetalheSheet` (drilldown nos rankings/análise), `SimuladorPage` (`/home/eleitoral/candidato/:seq/simulador`, client-side), comparação com até 4 candidatos, mapa com modo heatmap + labels top-10 + resumo

### Exemplo de Estrutura Segura
```
gabiflow-local/
├── app/
│   ├── api/
│   │   ├── [rotas existentes - NÃO MODIFICAR]
│   │   └── mobile/           # Diretório EXCLUSIVO para endpoints mobile
│   │       ├── dashboard/    # Dashboard mobile (CRIADO)
│   │       ├── constituents/ # Para criar se necessário
│   │       ├── demands/      # Para criar se necessário
│   │       └── ...
```

### ⚠️ REGRA CRÍTICA PARA MEMÓRIA
**SE A MEMÓRIA FOR LIMPA**: Para encontrar os endpoints mobile criados especificamente para o app:
1. Sempre procurar em: `/Users/iremarlopes/Desktop/gabiflow-local/app/api/mobile/`
2. NUNCA alterar nada fora desta pasta
3. Todos os endpoints mobile começam com `/api/mobile/`
4. Use `grep -r "api/mobile" /Users/iremarlopes/Desktop/gabiflow-local` para encontrar todos os endpoints mobile