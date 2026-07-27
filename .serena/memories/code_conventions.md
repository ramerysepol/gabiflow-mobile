# GabiFlow Mobile - Code Conventions and Style

## Project Structure
- **Clean Architecture** with feature-based organization
- **Domain-Driven Design** principles
- Separation of concerns with data, domain, and presentation layers

## Directory Structure Pattern
```
lib/
├── core/           # Core functionality shared across features
├── features/       # Feature modules
│   └── [feature]/
│       ├── data/
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/
│           ├── pages/
│           ├── widgets/
│           ├── providers/
│           └── bloc/
└── shared/         # Shared utilities

```

## Naming Conventions
- **Files**: snake_case (e.g., `user_model.dart`)
- **Classes**: PascalCase (e.g., `UserModel`)
- **Variables/Functions**: camelCase (e.g., `getUserData`)
- **Constants**: camelCase or SCREAMING_SNAKE_CASE for constants
- **Private members**: Prefix with underscore (`_privateVariable`)

## Code Style Rules (from analysis_options.yaml)
- **Strict type checking**: strict-casts, strict-inference, strict-raw-types enabled
- **Single quotes** for strings (`'string'` not `"string"`)
- **Const constructors** wherever possible
- **Final fields** for immutable properties
- **Avoid print statements** (use logger instead)
- **Curly braces** required for control flow
- **Type annotations** always declare return types
- **No unnecessary containers** in widgets
- **Sort child properties last** in widgets

## Data Models
- Use **Freezed** for immutable data classes
- Use **json_serializable** for JSON parsing
- Generated files pattern: `*.g.dart`, `*.freezed.dart`
- Models should have `fromJson` and `toJson` methods

## State Management
- **Riverpod** for dependency injection and state management
- Use **Providers** for business logic
- Prefer **FutureProvider** for async operations
- Use **StateNotifierProvider** for complex state

## Error Handling
- Custom error classes for domain errors
- Try-catch blocks for network operations
- Proper error messages for user feedback

## Testing Conventions
- Test files in `test/` directory mirroring `lib/` structure
- Test file naming: `*_test.dart`
- Minimum 80% code coverage for critical features

## Documentation
- Use `///` for documentation comments
- Document public APIs and complex logic
- TODO comments are ignored by linter

## Git Conventions
- Feature branches from main
- Commit messages in present tense
- Prefix commits with type (feat:, fix:, refactor:, etc.)

## Import Organization
1. Dart imports
2. Flutter imports
3. Package imports
4. Relative imports (feature files)

## Widget Best Practices
- Use `const` constructors when possible
- Prefer composition over inheritance
- Extract complex widgets to separate files
- Use keys for widget identification when needed