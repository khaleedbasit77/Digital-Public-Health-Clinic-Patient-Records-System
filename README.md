# Digital Public Health Clinic Patient Records System

A comprehensive blockchain-based patient records management system built with Clarity smart contracts for secure, transparent, and efficient healthcare data management.

## System Overview

This system consists of five interconnected smart contracts that manage different aspects of patient care:

### 1. Medical History Management (`medical-history.clar`)
- Secure storage of patient health information
- Medical record creation and updates
- Diagnosis and treatment history tracking
- Privacy-focused access controls

### 2. Appointment Scheduling (`appointment-scheduling.clar`)
- Clinic visit booking system
- Appointment status management
- Scheduling conflict prevention
- Automated reminder system

### 3. Prescription Tracking (`prescription-tracking.clar`)
- Medication order recording
- Refill history management
- Dosage and frequency tracking
- Prescription status monitoring

### 4. Insurance Billing (`insurance-billing.clar`)
- Claims processing and submission
- Copayment collection tracking
- Insurance verification
- Billing status management

### 5. Referral Coordination (`referral-coordination.clar`)
- Specialist appointment management
- Referral request processing
- Follow-up care coordination
- Inter-provider communication

## Key Features

- **Privacy & Security**: Patient data encrypted and access-controlled
- **Immutable Records**: Blockchain-based permanent record keeping
- **Interoperability**: Standardized data formats for system integration
- **Audit Trail**: Complete transaction history for compliance
- **Role-Based Access**: Different permissions for patients, doctors, and staff

## Data Types

### Patient Information
- Patient ID (unique identifier)
- Personal details (name, contact, demographics)
- Insurance information
- Emergency contacts

### Medical Records
- Diagnoses and conditions
- Treatment plans and outcomes
- Medication history
- Allergies and adverse reactions

### Appointments
- Date and time scheduling
- Provider assignments
- Visit types and purposes
- Status tracking

## Security Model

- **Patient Consent**: Explicit permission required for data access
- **Provider Authentication**: Verified healthcare professional access only
- **Data Minimization**: Only necessary information stored and shared
- **Encryption**: Sensitive data protected at rest and in transit

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for contract deployment

### Installation

1. Clone the repository
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. Deploy contracts: `clarinet deploy`

### Usage

Each contract can be interacted with independently:

\`\`\`clarity
;; Create a new patient record
(contract-call? .medical-history create-patient-record patient-id medical-data)

;; Schedule an appointment
(contract-call? .appointment-scheduling book-appointment patient-id provider-id date-time)

;; Issue a prescription
(contract-call? .prescription-tracking create-prescription patient-id medication-data)
\`\`\`

## Testing

The system includes comprehensive test coverage using Vitest:

- Unit tests for each contract function
- Integration tests for cross-contract workflows
- Edge case and error condition testing
- Performance and gas optimization tests

Run tests with: `npm test`

## Compliance

This system is designed to support compliance with:

- HIPAA (Health Insurance Portability and Accountability Act)
- HITECH (Health Information Technology for Economic and Clinical Health)
- State and local healthcare privacy regulations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For technical support or questions about implementation, please open an issue in the repository or contact the development team.
