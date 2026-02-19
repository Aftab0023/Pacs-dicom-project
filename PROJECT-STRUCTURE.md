# Project Structure Overview

Complete file structure with descriptions for the PACS Medical Imaging System.

## Root Level Files

```
├── .gitignore                              # Git ignore patterns for version control
├── docker-compose.yml                      # Docker orchestration config for all services
├── README.md                               # Main project documentation and overview
├── ARCHITECTURE.md                         # System architecture and design documentation
├── DEPLOYMENT.md                           # Deployment instructions and guidelines
├── FEATURES.md                             # List of implemented features
├── PROJECT_SUMMARY.md                      # High-level project summary
├── SYSTEM-ARCHITECTURE-EXPLAINED.md        # Detailed architecture explanation
├── SYSTEM-STATUS.md                        # Current system status and health
├── QUICKSTART.md                           # Quick start guide for developers
├── QUICK-START-TESTING.md                  # Quick testing procedures
├── QUICK-FIX.md                            # Common fixes and troubleshooting
├── TESTING.md                              # Testing documentation and procedures
├── TESTING-WORKFLOW.md                     # Testing workflow guidelines
├── FRONTEND-ERROR-CHECK.md                 # Frontend error checking guide
├── OHIF-VIEWER-FINAL-FIX.md               # OHIF viewer integration fixes
├── VIEWER-FIXED.md                         # Viewer component fixes documentation
├── WORKING-OHIF-LINKS.md                   # Working OHIF viewer links reference
├── WORKLIST-DATA-GUIDE.md                  # Worklist data structure guide
├── WORKLIST-FIX.md                         # Worklist component fixes
├── WORKLIST-SUCCESS.md                     # Worklist implementation success notes
```

## Database Files

```
database/
├── init.sql                                # Database initialization script
└── create-tables.sql                       # SQL schema for all database tables
```

## SQL Scripts (Root)

```
├── add-bulk-data.sql                       # Script to add bulk test data
├── add-new-orthanc-study.sql              # Script to add Orthanc study data
├── add-sample-data.sql                     # Original sample data script
├── add-sample-data-fixed.sql              # Fixed version of sample data script
└── insert-test-study.sql                   # Insert test study for development
```

## PowerShell Scripts

```
├── fix-login.ps1                           # Script to fix login issues
├── generate-hash.ps1                       # Generate password hashes for users
├── init-database.ps1                       # Initialize database with schema
├── test-ohif-direct.ps1                    # Test OHIF viewer directly
├── test-worklist.ps1                       # Test worklist functionality
├── test-worklist-with-new-data.ps1        # Test worklist with new data
├── test-updated-worklist.ps1              # Test updated worklist features
├── trigger-webhook.ps1                     # Trigger Orthanc webhook manually
└── upload-sample-dicoms.ps1               # Upload sample DICOM files
```

## Backend (.NET Core)

```
backend/
├── PACS.sln                                # Visual Studio solution file
├── SETUP.md                                # Backend setup instructions
│
├── PACS.API/                               # Web API project (entry point)
│   ├── PACS.API.csproj                    # API project configuration
│   ├── Program.cs                          # Application entry point and configuration
│   ├── appsettings.json                    # Application settings and connection strings
│   ├── Dockerfile                          # Docker container configuration for API
│   ├── init-db.sh                          # Database initialization shell script
│   │
│   └── Controllers/                        # API endpoint controllers
│       ├── AuthController.cs               # Authentication and authorization endpoints
│       ├── WorklistController.cs           # Worklist management endpoints
│       ├── ReportController.cs             # Medical report CRUD endpoints
│       └── OrthancWebhookController.cs     # Webhook receiver for Orthanc events
│
├── PACS.Core/                              # Domain layer (business logic)
│   ├── PACS.Core.csproj                   # Core project configuration
│   │
│   ├── Entities/                           # Domain models and entities
│   │   ├── User.cs                         # User entity (doctors, radiologists)
│   │   ├── Patient.cs                      # Patient demographic information
│   │   ├── Study.cs                        # Medical imaging study entity
│   │   ├── Series.cs                       # DICOM series entity
│   │   ├── Instance.cs                     # DICOM instance entity
│   │   ├── Report.cs                       # Medical report entity
│   │   └── AuditLog.cs                     # Audit trail entity
│   │
│   ├── DTOs/                               # Data Transfer Objects
│   │   ├── AuthDTOs.cs                     # Authentication request/response DTOs
│   │   ├── StudyDTOs.cs                    # Study-related DTOs
│   │   ├── ReportDTOs.cs                   # Report-related DTOs
│   │   └── OrthancDTOs.cs                  # Orthanc integration DTOs
│   │
│   └── Interfaces/                         # Service contracts
│       ├── IAuthService.cs                 # Authentication service interface
│       ├── IStudyService.cs                # Study management service interface
│       ├── IReportService.cs               # Report service interface
│       ├── IOrthancService.cs              # Orthanc integration service interface
│       └── IAuditService.cs                # Audit logging service interface
│
└── PACS.Infrastructure/                    # Data access and external services
    ├── PACS.Infrastructure.csproj          # Infrastructure project configuration
    │
    ├── Data/
    │   └── PACSDbContext.cs                # Entity Framework database context
    │
    └── Services/                           # Service implementations
        ├── AuthService.cs                  # Authentication logic implementation
        ├── StudyService.cs                 # Study management implementation
        ├── ReportService.cs                # Report CRUD implementation
        ├── OrthancService.cs               # Orthanc API integration
        └── AuditService.cs                 # Audit logging implementation
```

## Frontend (React + TypeScript)

```
frontend/
├── package.json                            # NPM dependencies and scripts
├── tsconfig.json                           # TypeScript compiler configuration
├── tsconfig.node.json                      # TypeScript config for Node tools
├── vite.config.ts                          # Vite build tool configuration
├── tailwind.config.js                      # Tailwind CSS configuration
├── tailwind-custom-example.js              # Custom Tailwind example
├── postcss.config.js                       # PostCSS configuration
├── index.html                              # HTML entry point
├── Dockerfile                              # Docker container for frontend
├── nginx.conf                              # Nginx web server configuration
├── .env                                    # Environment variables (API URLs)
├── README.md                               # Frontend documentation
├── layout-custom-example.tsx               # Custom layout example component
│
└── src/
    ├── main.tsx                            # React application entry point
    ├── App.tsx                             # Root application component with routing
    ├── index.css                           # Global styles and Tailwind imports
    ├── vite-env.d.ts                       # Vite environment type definitions
    │
    ├── components/
    │   └── Layout.tsx                      # Main layout wrapper with navigation
    │
    ├── contexts/
    │   └── AuthContext.tsx                 # Authentication state management context
    │
    ├── pages/
    │   ├── Login.tsx                       # User login page
    │   ├── Dashboard.tsx                   # Main dashboard with statistics
    │   ├── Worklist.tsx                    # Study worklist with filters
    │   ├── StudyViewer.tsx                 # Study details and series viewer
    │   ├── OHIFViewer.tsx                  # OHIF medical image viewer integration
    │   └── Reporting.tsx                   # Report creation and management
    │
    └── services/
        └── api.ts                          # Axios API client and endpoints
```

## Orthanc Configuration

```
orthanc/
├── orthanc.json                            # Orthanc PACS server configuration
├── webhook.lua                             # Lua webhook script for events
└── webhook.py                              # Python webhook script alternative
```

## Technology Stack

### Backend
- .NET Core 8.0 - Web API framework
- Entity Framework Core - ORM for database access
- PostgreSQL - Relational database
- JWT - Authentication tokens

### Frontend
- React 18 - UI framework
- TypeScript - Type-safe JavaScript
- Vite - Build tool and dev server
- Tailwind CSS - Utility-first CSS framework
- React Router - Client-side routing
- Axios - HTTP client
- OHIF Viewer - Medical image viewer

### Infrastructure
- Docker & Docker Compose - Containerization
- Orthanc - Open-source DICOM server
- Nginx - Web server for frontend
- PostgreSQL - Database server

## Key Integrations

1. **Orthanc PACS** - Stores and manages DICOM medical images
2. **OHIF Viewer** - Web-based DICOM image viewer
3. **Webhook System** - Real-time study notifications from Orthanc
4. **JWT Authentication** - Secure API access
5. **Audit Logging** - Track all system actions

## Development Workflow

1. Backend runs on port 5000 (API)
2. Frontend runs on port 3000 (Dev) / 80 (Production)
3. Orthanc runs on port 8042 (DICOM server)
4. PostgreSQL runs on port 5432 (Database)
5. OHIF Viewer accessible via frontend integration

## Architecture Pattern

The backend follows Clean Architecture principles:
- **API Layer** - Controllers handle HTTP requests
- **Core Layer** - Business logic and domain models
- **Infrastructure Layer** - Data access and external services

The frontend follows Component-Based Architecture:
- **Pages** - Route-level components
- **Components** - Reusable UI elements
- **Contexts** - Global state management
- **Services** - API communication layer
