# GabiFlow Mobile - Backend Integration Guidelines

## CRITICAL RULES - NEVER VIOLATE
1. **NEVER** alter the backend structure at `/Users/iremarlopes/Desktop/gabiflow-local`
2. **NEVER** modify existing API endpoints used by the desktop system
3. **NEVER** change database schemas or tables
4. **ALWAYS** use `/api/mobile/*` endpoints for mobile-specific features
5. **ALWAYS** consult `system_tenants` table in `dados_eleitorais` database

## Backend Location and Structure
- **Backend Path**: `/Users/iremarlopes/Desktop/gabiflow-local`
- **Mobile API Path**: `/Users/iremarlopes/Desktop/gabiflow-local/app/api/mobile/`
- **Database Host**: 192.168.40.50:5432
- **Database Structure**:
  - `dados_eleitorais`: Universal database with `system_tenants` table
  - `gabiflow_{tenant}`: Individual database per gabinete

## Mobile-Specific Endpoints
All mobile endpoints are under `/api/mobile/`:
- `GET /api/mobile/dashboard` - Dashboard statistics

## API Request Requirements
Every API request must include:
```dart
headers: {
  'Authorization': 'Bearer $accessToken',
  'X-Tenant-ID': tenantId,
  'Content-Type': 'application/json',
}
```

## Available Backend APIs (DO NOT MODIFY)
1. **Check Tenant**: `GET /api/check-tenant/?subdomain={subdomain}`
2. **Auth**: `/api/auth/login`, `/api/auth/logout`, `/api/auth/refresh`, `/api/auth/me`
3. **Constituents**: `/api/constituents/*`
4. **Demands**: `/api/demands/*`
5. **Events**: `/api/events/*`
6. **Dashboard**: `/api/dashboard/`
7. **Users**: `/api/users/*`
8. **WhatsApp**: `/api/whatsapp/*`
9. **AI**: `/api/ai/*`

## Multi-Tenant Flow
1. User enters tenant URL (e.g., `samuel.gabiflow.com.br`)
2. Extract subdomain
3. Verify tenant exists in `system_tenants` table
4. Save tenant configuration
5. Include tenant_id in all subsequent requests

## Development vs Production
```dart
// Development
const devBaseUrl = 'http://192.168.40.50:3001';

// Production  
const prodBaseUrl = 'https://gabiflow.com.br';
```

## Creating New Mobile Endpoints
If a mobile-specific endpoint is needed:
1. Create ONLY in `/app/api/mobile/` directory
2. Follow existing patterns
3. Use same auth middleware
4. Document as mobile-only
5. Test thoroughly without breaking desktop

## Error Handling
- 401: Token expired - refresh token
- 403: Forbidden - check tenant access
- 404: Not found - verify endpoint/resource
- 500: Server error - retry with backoff

## Important Database Tables
### system_tenants (dados_eleitorais database)
```sql
- id: Tenant identifier
- subdomain: Unique subdomain
- name: Tenant name
- parlamentar_nome: Parliament member name
- database_name: Specific database for tenant
- active: Whether tenant is active
- theme_primary_color: Custom theme color
```

## Security Considerations
- JWT tokens expire - implement auto-refresh
- Secure storage for sensitive data
- Tenant isolation is critical
- Never expose tenant data to other tenants
- Always validate tenant_id server-side