# GabiFlow Mobile - Architecture Details

## Clean Architecture Layers

### 1. Presentation Layer
- **Pages**: Full screen widgets (routes)
- **Widgets**: Reusable UI components
- **Providers**: Riverpod providers for state management
- **Bloc**: Alternative state management (if used)

### 2. Domain Layer
- **Entities**: Core business objects
- **Use Cases**: Business logic implementation
- **Repository Interfaces**: Contracts for data layer

### 3. Data Layer
- **Models**: Data transfer objects with JSON serialization
- **Data Sources**: Remote (API) and local (cache) data sources
- **Repository Implementations**: Concrete implementations

## Core Module Structure
```
core/
├── constants/       # App-wide constants
├── errors/         # Error handling
├── network/        # API client, interceptors
├── providers/      # Core providers
├── services/       # Core services (storage, auth, etc.)
├── theme/          # App theming
├── utils/          # Utility functions
└── widgets/        # Core reusable widgets
```

## Feature Module Pattern
Each feature follows the same structure:
```
feature_name/
├── data/
│   ├── datasources/
│   │   └── feature_remote_datasource.dart
│   ├── models/
│   │   ├── model.dart
│   │   ├── model.g.dart (generated)
│   │   └── model.freezed.dart (generated)
│   └── repositories/
│       └── feature_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── entity.dart
│   ├── repositories/
│   │   └── feature_repository.dart
│   └── usecases/
│       └── use_case.dart
└── presentation/
    ├── pages/
    │   └── feature_page.dart
    ├── widgets/
    │   └── feature_widget.dart
    └── providers/
        └── feature_provider.dart
```

## Current Features
1. **auth** - Authentication and login
2. **tenant** - Multi-tenant configuration
3. **dashboard** - Main dashboard with statistics
4. **constituents** - Munícipe management
5. **demands** - Demand/request tracking
6. **events** - Calendar and events
7. **finances** - Financial management
8. **collaborators** - Team management
9. **electoral_data** - Electoral information
10. **splash** - App initialization
11. **home** - Main navigation

## API Integration Pattern
1. **API Client** (Dio) with interceptors
2. **Auth Interceptor** - Adds JWT token
3. **Redirect Interceptor** - Handles redirects
4. **Remote Data Source** - API calls
5. **Repository** - Combines remote and local data
6. **Use Case** - Business logic
7. **Provider** - State management
8. **UI** - Presentation layer

## State Management with Riverpod
- **Provider**: For dependency injection
- **StateProvider**: For simple state
- **FutureProvider**: For async operations
- **StreamProvider**: For streams
- **StateNotifierProvider**: For complex state
- **NotifierProvider**: Modern complex state

## Navigation Structure
- Uses **go_router** for declarative routing
- Route guards for authentication
- Deep linking support
- Nested navigation for tabs

## Data Flow
1. UI triggers action
2. Provider/Bloc handles event
3. Use case executes business logic
4. Repository fetches/saves data
5. Data source interacts with API/cache
6. State updates trigger UI rebuild

## Dependency Injection
- Riverpod providers handle DI
- Providers are globally accessible
- Scoped providers for feature isolation
- Override providers for testing

## Error Handling Strategy
- Custom exception classes
- Try-catch at data source level
- Either/Result pattern for errors
- User-friendly error messages
- Offline mode fallbacks

## Caching Strategy
- Hive for structured data
- SharedPreferences for simple values
- SecureStorage for sensitive data
- In-memory cache for session data
- Cache invalidation policies

## Security Measures
- JWT tokens in secure storage
- Biometric authentication
- Certificate pinning (if configured)
- API request signing
- Multi-tenant isolation