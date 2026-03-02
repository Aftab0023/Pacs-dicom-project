# Requirements Document: Enterprise PACS Roadmap

## Introduction

This document defines the requirements for transforming the current basic PACS system (Orthanc + .NET 8 Web API + MSSQL + OHIF viewer) into a full enterprise-grade hospital deployment. The roadmap is organized into three phases: Enterprise Readiness, Hospital Production Level, and Advanced Enterprise. The system must maintain compatibility with existing infrastructure while adding enterprise features for multi-modality workflows, HL7 integration, advanced security, high availability, and multi-site capabilities.

## Glossary

- **PACS**: Picture Archiving and Communication System - the complete imaging system
- **Orthanc**: Open-source DICOM server providing storage and routing
- **OHIF**: Open Health Imaging Foundation web viewer
- **MWL**: Modality Worklist - DICOM service for scheduling studies
- **RIS**: Radiology Information System - manages radiology department operations
- **HL7**: Health Level 7 - healthcare messaging standard
- **ADT**: Admission, Discharge, Transfer - HL7 message type
- **ORM**: Order Message - HL7 message type for orders
- **ORU**: Observation Result - HL7 message type for results
- **VNA**: Vendor Neutral Archive - centralized medical image storage
- **DICOM_MWL_SCP**: DICOM Modality Worklist Service Class Provider
- **Study_Router**: Component that routes studies based on rules
- **HL7_Listener**: Service that receives and processes HL7 messages
- **Audit_Logger**: Component that records system events for compliance
- **Storage_Tier_Manager**: Component managing hot/warm/cold storage
- **Report_Generator**: Component creating structured radiology reports
- **Backup_Service**: Component handling backup and disaster recovery
- **Monitoring_System**: Component tracking system health and performance
- **Authentication_Service**: Component managing user authentication and SSO

## Requirements

### Phase 1: Enterprise Readiness

### Requirement 1: Enhanced Modality Worklist

**User Story:** As a radiology technologist, I want the PACS to provide a DICOM Modality Worklist service, so that imaging modalities can retrieve scheduled procedures and automatically populate patient demographics.

#### Acceptance Criteria

1. THE DICOM_MWL_SCP SHALL listen on a configurable DICOM port for C-FIND requests from modalities
2. WHEN a modality queries the worklist, THE DICOM_MWL_SCP SHALL return scheduled procedures matching the query parameters
3. WHEN a procedure is scheduled in the backend database, THE DICOM_MWL_SCP SHALL make it available in the worklist within 5 seconds
4. THE DICOM_MWL_SCP SHALL support filtering by patient ID, patient name, scheduled date, modality type, and accession number
5. WHEN a study is received with a matching accession number, THE PACS SHALL automatically link it to the scheduled procedure
6. THE DICOM_MWL_SCP SHALL log all worklist queries for audit purposes

### Requirement 2: RIS Integration Architecture

**User Story:** As a hospital administrator, I want the PACS to integrate with our RIS, so that scheduling and patient data flows seamlessly between systems.

#### Acceptance Criteria

1. THE PACS SHALL provide a REST API endpoint for receiving procedure scheduling data from the RIS
2. WHEN the RIS sends a new procedure order, THE PACS SHALL create a worklist entry and return a confirmation within 2 seconds
3. WHEN a study is completed and reported, THE PACS SHALL send a notification to the RIS with study status
4. THE PACS SHALL support bidirectional synchronization of procedure status updates
5. IF the RIS connection fails, THEN THE PACS SHALL queue updates and retry with exponential backoff up to 24 hours

### Requirement 3: Advanced Study Routing

**User Story:** As a PACS administrator, I want to configure automatic study routing rules, so that studies are assigned to the correct radiologists based on modality, body part, and urgency.

#### Acceptance Criteria

1. THE Study_Router SHALL evaluate routing rules when a study is received via DICOM C-STORE
2. WHEN multiple rules match a study, THE Study_Router SHALL apply the rule with the highest priority
3. THE Study_Router SHALL support routing based on modality type, study description, referring physician, patient location, and time of day
4. WHEN a study matches a routing rule, THE Study_Router SHALL assign it to the specified radiologist or group within 10 seconds
5. THE Study_Router SHALL support load balancing across multiple radiologists in a group
6. WHERE urgent studies are flagged, THE Study_Router SHALL prioritize them and send notifications

### Requirement 4: Granular RBAC Permissions

**User Story:** As a security administrator, I want fine-grained role-based access control, so that users only access studies and functions appropriate to their role.

#### Acceptance Criteria

1. THE Authentication_Service SHALL support permissions at the study, series, and instance level
2. THE Authentication_Service SHALL enforce permissions for viewing, downloading, deleting, and sharing studies
3. WHEN a user attempts an action, THE Authentication_Service SHALL verify they have the required permission before allowing it
4. THE Authentication_Service SHALL support department-based access restrictions
5. THE Authentication_Service SHALL support time-based access restrictions for temporary users
6. THE Authentication_Service SHALL log all permission checks and denials for audit purposes

### Requirement 5: Comprehensive Audit Logging

**User Story:** As a compliance officer, I want comprehensive audit logs with retention policies, so that we can meet HIPAA requirements and investigate security incidents.

#### Acceptance Criteria

1. THE Audit_Logger SHALL record all user authentication attempts with timestamp, username, IP address, and result
2. THE Audit_Logger SHALL record all study access events including view, download, print, and share operations
3. THE Audit_Logger SHALL record all configuration changes with before and after values
4. THE Audit_Logger SHALL record all DICOM network operations including sender AE title and IP address
5. THE Audit_Logger SHALL store logs in a tamper-evident format with cryptographic signatures
6. THE Audit_Logger SHALL retain logs for a configurable period with automatic archival to cold storage
7. THE Audit_Logger SHALL support querying logs by user, date range, action type, and patient identifier

### Requirement 6: Performance Optimization

**User Story:** As a radiologist, I want fast study loading for large CT and MRI datasets, so that I can read studies efficiently without waiting.

#### Acceptance Criteria

1. WHEN a user opens a study, THE PACS SHALL deliver the first image within 2 seconds over a 100 Mbps connection
2. THE PACS SHALL support progressive loading where initial images display while remaining images load in background
3. THE PACS SHALL cache frequently accessed studies in memory for sub-second retrieval
4. THE PACS SHALL compress DICOM images using lossless compression to reduce storage and transfer time
5. WHEN multiple users access the same study, THE PACS SHALL serve it from cache without re-reading from disk
6. THE PACS SHALL support concurrent retrieval of at least 50 studies without performance degradation

### Requirement 7: Secure DICOM and HTTPS

**User Story:** As a security administrator, I want all DICOM and web traffic encrypted, so that patient data is protected in transit.

#### Acceptance Criteria

1. THE PACS SHALL support DICOM TLS for all DICOM network operations
2. THE PACS SHALL enforce HTTPS for all web API endpoints with TLS 1.2 or higher
3. THE PACS SHALL reject unencrypted DICOM connections when secure mode is enabled
4. THE PACS SHALL support certificate-based authentication for DICOM peers
5. THE PACS SHALL validate DICOM peer certificates against a trusted certificate authority
6. THE PACS SHALL log all connection attempts including encryption status

### Requirement 8: Storage Optimization and Tiering

**User Story:** As a PACS administrator, I want automatic storage tiering, so that recent studies are fast to access while older studies are moved to cheaper storage.

#### Acceptance Criteria

1. THE Storage_Tier_Manager SHALL classify storage into hot (SSD), warm (HDD), and cold (archive) tiers
2. WHEN a study is received, THE Storage_Tier_Manager SHALL store it in hot storage
3. WHEN a study has not been accessed for 30 days, THE Storage_Tier_Manager SHALL move it to warm storage
4. WHEN a study has not been accessed for 1 year, THE Storage_Tier_Manager SHALL move it to cold storage
5. WHEN a user accesses a cold study, THE Storage_Tier_Manager SHALL retrieve it within 60 seconds
6. THE Storage_Tier_Manager SHALL maintain metadata in the database regardless of storage tier
7. THE Storage_Tier_Manager SHALL support configurable tiering policies per modality type

### Phase 2: Hospital Production Level

### Requirement 9: HL7 Integration

**User Story:** As a hospital IT administrator, I want the PACS to process HL7 messages, so that patient demographics and orders flow automatically from the HIS/EMR.

#### Acceptance Criteria

1. THE HL7_Listener SHALL listen on a configurable TCP port for HL7 messages
2. WHEN an ADT^A01 (patient admission) message is received, THE HL7_Listener SHALL create or update the patient record
3. WHEN an ORM^O01 (order) message is received, THE HL7_Listener SHALL create a worklist entry for the ordered procedure
4. WHEN an ORU^R01 (result) message is received, THE HL7_Listener SHALL update the study status
5. THE HL7_Listener SHALL send HL7 acknowledgment messages within 1 second of receiving a message
6. IF message processing fails, THEN THE HL7_Listener SHALL send a negative acknowledgment with error details
7. THE HL7_Listener SHALL queue messages and process them in order with at-least-once delivery guarantee

### Requirement 10: HL7 Message Queue

**User Story:** As a system administrator, I want HL7 messages queued reliably, so that no messages are lost during system maintenance or failures.

#### Acceptance Criteria

1. THE HL7_Listener SHALL persist incoming messages to a durable queue before processing
2. WHEN the PACS is restarted, THE HL7_Listener SHALL resume processing queued messages
3. THE HL7_Listener SHALL support configurable retry policies with exponential backoff
4. THE HL7_Listener SHALL move messages to a dead letter queue after 5 failed processing attempts
5. THE HL7_Listener SHALL provide an admin interface for viewing and reprocessing failed messages
6. THE HL7_Listener SHALL maintain message ordering within a single patient context

### Requirement 11: Structured Reporting

**User Story:** As a radiologist, I want to create structured reports using templates, so that reports are consistent and contain all required elements.

#### Acceptance Criteria

1. THE Report_Generator SHALL provide templates for common study types including chest X-ray, CT head, and MRI spine
2. WHEN a radiologist creates a report, THE Report_Generator SHALL present the appropriate template based on study modality and body part
3. THE Report_Generator SHALL support required fields, optional fields, and conditional fields based on findings
4. THE Report_Generator SHALL validate that all required fields are completed before allowing report finalization
5. THE Report_Generator SHALL support free-text sections for additional findings
6. THE Report_Generator SHALL store reports in both structured format and rendered text format
7. THE Report_Generator SHALL support report templates with dropdown selections, checkboxes, and measurements

### Requirement 12: Teleradiology Readiness

**User Story:** As a teleradiology provider, I want to securely access studies remotely, so that I can provide after-hours coverage from home.

#### Acceptance Criteria

1. THE PACS SHALL support secure remote access via VPN or zero-trust network architecture
2. THE PACS SHALL enforce multi-factor authentication for remote users
3. THE PACS SHALL support bandwidth-adaptive streaming for remote users on slower connections
4. THE PACS SHALL provide a web-based viewer that works without installing client software
5. THE PACS SHALL log all remote access sessions with IP address and geographic location
6. THE PACS SHALL support study distribution to external PACS systems via DICOM Q/R or DICOMweb

### Requirement 13: Multi-Modality Workflow

**User Story:** As a radiology department manager, I want optimized workflows for different modality types, so that each modality's unique requirements are supported.

#### Acceptance Criteria

1. THE PACS SHALL support modality-specific hanging protocols for CT, MR, XR, US, NM, and PET
2. THE PACS SHALL support multi-frame DICOM objects for ultrasound cine loops
3. THE PACS SHALL support PET-CT fusion viewing with synchronized scrolling
4. THE PACS SHALL support nuclear medicine dynamic studies with time-based playback
5. THE PACS SHALL support mammography-specific layouts with prior comparison views
6. THE PACS SHALL support 3D reconstruction and MPR for CT and MR studies

### Requirement 14: Storage Scaling Strategy

**User Story:** As a PACS administrator, I want a clear storage scaling strategy, so that the system can grow as imaging volume increases.

#### Acceptance Criteria

1. THE PACS SHALL support adding storage capacity without system downtime
2. THE PACS SHALL distribute new studies across available storage pools using a configurable strategy
3. THE PACS SHALL monitor storage utilization and alert when capacity exceeds 80%
4. THE PACS SHALL support migrating studies between storage pools without changing study UIDs
5. THE PACS SHALL maintain consistent performance as storage scales beyond 100 TB
6. THE PACS SHALL support both local storage and network-attached storage (NAS)

### Requirement 15: Backup and Disaster Recovery

**User Story:** As a hospital administrator, I want automated backups and disaster recovery procedures, so that we can recover from hardware failures or disasters.

#### Acceptance Criteria

1. THE Backup_Service SHALL perform incremental backups of all studies daily
2. THE Backup_Service SHALL perform full backups of the database weekly
3. THE Backup_Service SHALL verify backup integrity by performing test restores monthly
4. THE Backup_Service SHALL store backups in a geographically separate location
5. THE Backup_Service SHALL support point-in-time recovery for the database
6. THE Backup_Service SHALL maintain backup retention for 7 years to meet regulatory requirements
7. IF a restore is needed, THEN THE Backup_Service SHALL provide documented procedures with RTO of 4 hours and RPO of 24 hours

### Requirement 16: Monitoring and Observability

**User Story:** As a system administrator, I want comprehensive monitoring and alerting, so that I can proactively address issues before they impact users.

#### Acceptance Criteria

1. THE Monitoring_System SHALL collect metrics for CPU, memory, disk I/O, and network throughput every 30 seconds
2. THE Monitoring_System SHALL track application metrics including study ingestion rate, query response time, and active user sessions
3. THE Monitoring_System SHALL alert when disk space falls below 20% available
4. THE Monitoring_System SHALL alert when study ingestion fails for more than 5 minutes
5. THE Monitoring_System SHALL alert when API response time exceeds 5 seconds
6. THE Monitoring_System SHALL provide dashboards showing system health, study volume trends, and user activity
7. THE Monitoring_System SHALL retain metrics for 90 days for trend analysis

### Requirement 17: High Availability Setup

**User Story:** As a hospital CTO, I want the PACS to be highly available, so that radiologists can access studies 24/7 without interruption.

#### Acceptance Criteria

1. THE PACS SHALL support active-passive failover with automatic failover within 2 minutes
2. THE PACS SHALL replicate the database to a standby server with less than 5 seconds lag
3. THE PACS SHALL use a load balancer to distribute web traffic across multiple API servers
4. THE PACS SHALL detect failed components and route traffic to healthy components automatically
5. THE PACS SHALL maintain session state to prevent user disruption during failover
6. THE PACS SHALL achieve 99.9% uptime measured monthly

### Phase 3: Advanced Enterprise

### Requirement 18: Vendor Neutral Archive Evolution

**User Story:** As an enterprise imaging director, I want the PACS to function as a VNA, so that we can store all medical images regardless of department or vendor.

#### Acceptance Criteria

1. THE PACS SHALL store images from radiology, cardiology, pathology, and other departments in a unified archive
2. THE PACS SHALL support non-DICOM formats including JPEG, PNG, PDF, and video files with DICOM wrapping
3. THE PACS SHALL maintain original image fidelity without lossy compression unless explicitly configured
4. THE PACS SHALL support XDS (Cross-Enterprise Document Sharing) for sharing with external systems
5. THE PACS SHALL provide a unified search interface across all image types and departments
6. THE PACS SHALL support department-specific viewers while using shared storage

### Requirement 19: Multi-Site Architecture

**User Story:** As a healthcare system CIO, I want to deploy PACS across multiple hospital sites, so that each site has local performance while sharing studies enterprise-wide.

#### Acceptance Criteria

1. THE PACS SHALL support deploying independent PACS instances at each hospital site
2. THE PACS SHALL automatically route studies between sites based on patient location and physician affiliation
3. WHEN a user at Site A queries for a study stored at Site B, THE PACS SHALL retrieve it transparently
4. THE PACS SHALL cache remote studies locally after first access for faster subsequent retrieval
5. THE PACS SHALL support configurable routing rules for automatic study distribution
6. THE PACS SHALL maintain a global study index showing which site stores each study

### Requirement 20: High Availability and Failover

**User Story:** As a reliability engineer, I want active-active failover across sites, so that the system remains available even if an entire site goes offline.

#### Acceptance Criteria

1. THE PACS SHALL support active-active deployment where both sites handle production traffic simultaneously
2. WHEN one site fails, THE PACS SHALL automatically route all traffic to the remaining site within 30 seconds
3. THE PACS SHALL replicate critical studies between sites based on configurable policies
4. THE PACS SHALL synchronize the database across sites with conflict resolution for concurrent updates
5. THE PACS SHALL support split-brain detection and automatic recovery
6. THE PACS SHALL achieve 99.99% uptime measured annually across the multi-site deployment

### Requirement 21: Cloud and Hybrid Deployment

**User Story:** As a cloud architect, I want to deploy PACS components in the cloud, so that we can leverage cloud scalability and reduce on-premises infrastructure.

#### Acceptance Criteria

1. THE PACS SHALL support deployment on Azure, AWS, or Google Cloud Platform
2. THE PACS SHALL support hybrid deployment with on-premises Orthanc and cloud-based API and database
3. THE PACS SHALL use cloud object storage (Azure Blob, S3, GCS) for long-term study archival
4. THE PACS SHALL support auto-scaling of API servers based on load
5. THE PACS SHALL encrypt data at rest using cloud-native encryption services
6. THE PACS SHALL support cloud-based disaster recovery with automated failover
7. THE PACS SHALL optimize costs by using cloud storage tiers for hot, warm, and cold data

### Requirement 22: Cross-Site Study Access

**User Story:** As a radiologist, I want to access studies from any site in the healthcare system, so that I can provide consultations and compare with prior studies regardless of location.

#### Acceptance Criteria

1. WHEN a user searches for studies, THE PACS SHALL query all sites and return a unified result set within 3 seconds
2. THE PACS SHALL indicate which site stores each study in the search results
3. WHEN a user opens a study from a remote site, THE PACS SHALL stream it with acceptable performance over WAN links
4. THE PACS SHALL prefetch related priors from remote sites when a study is opened
5. THE PACS SHALL support offline access to cached studies when WAN connectivity is lost
6. THE PACS SHALL synchronize user preferences and worklists across all sites

### Requirement 23: Distributed Caching and CDN

**User Story:** As a performance engineer, I want distributed caching, so that frequently accessed studies load quickly regardless of user location.

#### Acceptance Criteria

1. THE PACS SHALL cache studies in a distributed cache (Redis, Memcached) shared across API servers
2. THE PACS SHALL use a CDN for serving static viewer assets and frequently accessed images
3. THE PACS SHALL implement cache warming for studies likely to be accessed based on scheduling data
4. THE PACS SHALL evict least-recently-used studies from cache when capacity is reached
5. THE PACS SHALL maintain cache consistency when studies are updated or deleted
6. THE PACS SHALL achieve 90% cache hit rate for studies accessed within 24 hours of creation

### Requirement 24: Advanced Security

**User Story:** As a CISO, I want advanced security features including 2FA and SSO, so that we meet enterprise security standards and reduce password-related risks.

#### Acceptance Criteria

1. THE Authentication_Service SHALL support two-factor authentication using TOTP (Google Authenticator, Authy)
2. THE Authentication_Service SHALL support single sign-on via SAML 2.0 or OpenID Connect
3. THE Authentication_Service SHALL integrate with LDAP or Active Directory for user provisioning
4. THE Authentication_Service SHALL enforce password complexity requirements and expiration policies
5. THE Authentication_Service SHALL support automatic account lockout after 5 failed login attempts
6. THE Authentication_Service SHALL support session timeout with configurable idle and absolute timeouts
7. THE Authentication_Service SHALL log all authentication events for security monitoring
