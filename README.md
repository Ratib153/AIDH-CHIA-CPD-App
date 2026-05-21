# CHIA CPD Journaling Mobile Application

## Overview
This project is a mobile application designed to support Certified Health Informatician Australasia (CHIA) professionals in recording, managing, and submitting their Continuing Professional Development (CPD) activities.

The app simplifies the current journaling process by replacing manual Excel-based tracking with an intuitive, mobile-friendly solution.

## Flutter Frontend Prototype Setup

This repository now includes a Flutter frontend implementation of the CPD Tracker UI prototype.

### 1) Install Flutter
- Follow the official guide: https://docs.flutter.dev/get-started/install

### 2) Generate native folders (first time only)
- Run in the project root:
  - `flutter create .`

### 3) Install packages
- `flutter pub get`

### 4) Run on Android / iOS
- Android: `flutter run -d android`
- iOS (macOS only): `flutter run -d ios`

---

## Problem Statement
Currently, CHIA professionals are required to track their CPD activities using spreadsheets. This creates several challenges:

- The process is time-consuming and difficult to manage
- Users must manually enter and organise their activities
- Many professionals already track CPD for other health disciplines, leading to duplicated effort
- The complexity discourages users from completing recertification

This creates a barrier to maintaining CHIA certification and reduces long-term engagement.

---

## Solution
This application provides a simple and accessible mobile platform that allows users to:

- Record CPD activities easily
- Track progress towards the required 60 CPD points
- View a dashboard of completed and remaining requirements
- Export CPD journals for submission
- Manage multiple CPD reporting needs in one place

---

## Key Features

- Cross-platform mobile app (iOS and Android)
- Dashboard showing CPD progress and category limits
- Add activities manually or via automated input (e.g. QR code scanning)
- Export CPD reports for submission
- Reset journal cycles while preserving past records
- Simple, user-friendly design focused on accessibility

---

## Objectives

- Improve user experience for CPD tracking
- Increase CHIA recertification rates
- Reduce administrative burden on professionals
- Provide a scalable and cost-effective solution

---

## Technical Considerations

- The app may function independently or integrate with Salesforce
- Data may be stored locally or synced with backend systems
- Must comply with Australian data regulations
- Designed to be low-cost and easy to maintain

---

## Scope

### Critical Features
- iOS and Android compatibility
- Structured around CHIA CPD requirements
- Activity capture functionality
- Export functionality
- Secure data storage

### High Priority
- Alignment with other CPD programs
- Simple and future-proof design
- Editable backend by non-technical users

### Nice to Have
- Salesforce integration

---

## Stakeholders

- Australasian Institute of Digital Health (AIDH)
- CHIA Certified Professionals
- Development Team

---

## Team
Shreeya Niraula 
Mohd Ratib
Joshua Mirenda
Mehdi Tabibi 
Mohd Junaid Shareef

---
