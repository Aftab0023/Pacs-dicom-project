# PACS Frontend

React + TypeScript + Vite frontend for the PACS system.

## Features

- Modern medical UI with dark theme
- JWT authentication
- Role-based access control
- Worklist management
- Study viewer integration
- Reporting module
- Responsive design

## Setup

### Install Dependencies

```bash
npm install
```

### Environment Variables

Create `.env` file:

```
VITE_API_URL=http://localhost:5000/api
```

### Development

```bash
npm run dev
```

Frontend will be available at: http://localhost:3000

### Build for Production

```bash
npm run build
```

## Pages

### Login
- Email/password authentication
- JWT token management
- Demo credentials displayed

### Dashboard
- Quick stats overview
- Navigation to main features
- User information display

### Worklist
- Study list with filtering
- Search by patient, MRN, accession
- Filter by modality, status
- Pagination support
- Priority flagging
- Quick actions (View, Report)

### Study Viewer
- Patient demographics
- Study information
- Series list
- OHIF viewer integration
- Navigation to reporting

### Reporting
- Clinical history input
- Findings documentation
- Impression/conclusion
- Save draft functionality
- Finalize report
- View previous reports
- PDF download

## Components

### Layout
- Navigation bar
- User profile display
- Logout functionality
- Responsive design

### Protected Routes
- Authentication check
- Automatic redirect to login
- Token validation

## API Integration

All API calls are centralized in `src/services/api.ts`:

- `authApi` - Authentication endpoints
- `worklistApi` - Study management
- `reportApi` - Report CRUD operations

## Styling

- Tailwind CSS for utility-first styling
- Custom medical theme colors
- Dark mode optimized for radiology
- Responsive breakpoints

## OHIF Viewer Integration

The system integrates with OHIF Viewer for DICOM image viewing:

- DICOMweb protocol
- Study UID-based launching
- Orthanc backend integration
- Multi-series support

## Default Credentials

- Admin: admin@pacs.local / Admin123!
- Radiologist: radiologist@pacs.local / Radio123!
