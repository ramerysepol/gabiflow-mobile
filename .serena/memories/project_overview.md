# GabiFlow Mobile - Project Overview

## Purpose
GabiFlow Mobile is a Flutter application that serves as a mobile client for the GabiFlow parliamentary management system. It provides mobile access to gabinete (parliamentary office) management features for deputies and their staff.

## Main Features
- Multi-tenant system with isolated data per gabinete
- Authentication with JWT tokens
- Dashboard with statistics and metrics
- Constituent management (munícipes)
- Demands/requests management
- Events and calendar
- Financial tracking
- Electoral data access
- Collaborators management
- WhatsApp integration capabilities

## Integration
- Connects to existing GabiFlow backend at `/Users/iremarlopes/Desktop/gabiflow-local`
- Uses PostgreSQL database at 192.168.40.50:5432
- Multi-tenant architecture with per-tenant databases
- RESTful API integration with JWT authentication

## Key Technical Details
- Flutter SDK: ^3.8.1
- Target platforms: iOS and Android
- State management: Riverpod
- Navigation: go_router
- Storage: Hive, Flutter Secure Storage, SharedPreferences
- Network: Dio with interceptors
- Clean Architecture with feature-based structure

## Security
- JWT token-based authentication with refresh tokens
- Secure storage for sensitive data
- Biometric authentication support
- Multi-tenant isolation with tenant ID in headers