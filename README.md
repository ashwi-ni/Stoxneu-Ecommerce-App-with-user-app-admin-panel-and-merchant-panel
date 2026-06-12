# 📱 Stoxneu – Multi-Vendor E-Commerce Platform

[![Flutter](https://shields.io)](https://flutter.dev)
[![Node.js](https://shields.io)](https://nodejs.org)
[![MySQL](https://shields.io)](https://www.mysql.com)
[![AWS](https://shields.io)](https://amazon.com)

> Modern, full-scale B2C multi-vendor marketplace platform built for high scalability, secure ecosystem interactions, and cross-platform performance.

## 🔗 Project Overview
Stoxneu replicates a production-grade marketplace experience (similar to Amazon/Flipkart) featuring standard customer mobile apps, isolated merchant workspaces, and centralized administrative controls.

*   **Target Market:** India (Architected for global localization scaling)
*   **Supported Platforms:** Android, iOS, and Web Administration Panel
---

## ⚙️ Tech Stack Architecture

### Frontend Ecosystem
*   **Mobile Framework:** Flutter (Dart)
*   **State Management:** BLoC
*   **API Interceptor/Integration:** RESTful Client
*   **Real-time Push Notifications:** Firebase Cloud Messaging (FCM)

### Backend & Cloud Infrastructure
*   **Runtime Framework:** Node.js 
*   **Primary Database:** MySQL (Relational Layer)
*   **Admin/Merchant Web Panels:** Node.js + Tailwind CSS
---
## 👥 System Roles & Core Features

### 1. Customer App (Flutter)
*   **Auth Engines:** Secure Phone OTP validation, Email/Password, and Google OAuth 2.0.
*   **Discovery Engine:** Category filter architecture (Computers, Clothing, Electronics, Shoes, Watches) with dynamic pricing & review sorting algorithms.
*   **Commerce Funnel:** Live cart management, dynamic coupon application fields, and payment routing.
*   **Self Service:** Post-purchase tracking timelines, wallet transaction logs, and review workflows.

### 2. Merchant Workspace Portal
*   **Onboarding:** Dedicated seller registration pipelines with document KYC validation states.
*   **Inventory Control:** Direct image uploading pipeline, SKU level adjustments, and pricing control engines.
*   **Order Fulfillment:** Workflow transitions from Order Received > Dispatched (Airway Bill Tracking Attachment) > Delivered.
*   **Financial Settlement:** Earnings accounting dash with on-demand secure payout initiation request workflows.

### 3. System Administration Dashboard
*   **Approval Gates:** Guardrails to strictly review/approve pending merchant profiles and raw product catalogs.
*   **Financial Rule Engine:** Global commission configuration structures parsed dynamically per transaction.
*   **CMS Management:** Real-time carousel banner configuration updates and statutory policy edits.
*   **Data Reporting:** Advanced analytics reports tracking net performance metrics, tax collection, and customer distributions.

---

## 🗄️ Database Design (High-Level Entity Schema)
The system data structure relies on tightly normalized relationships mapping across core entities:
```text
[users] ────< [orders] ────< [order_items] >──── [products] >──── [categories]
                │                                    │
[payments] ─────┘                            [merchants] ────> [payouts]
```

---

## 🔒 Security & Performance Features
*   **Stateless Security:** Strict JWT implementation coupled with fine-grained Role-Based Access Control (RBAC).
*   **Infrastructure Protection:** Cryptographic password hashing blocks alongside rigorous API Gateway level rate-limiting.
*   **Load Mitigation:** Aggressive Redis API query response caching alongside dedicated Image CDN workflows using lazy-loading mechanisms.

---

## 🗺️ Project Roadmap & Phases

```mermaid
gantt
    title Stoxneu Project Implementation Phases
    dateFormat  X
    axisFormat %d weeks
    
    section Phase 1
    Planning & UI/UX Design       :active, p1, 0, 2
    section Phase 2
    Backend APIs & Flutter Setup  :p2, after p1, 10
    section Phase 3
    Admin & Merchant Web Panels   :p3, after p2, 4
    section Phase 4
    Security & Integration Testing:p4, after p3, 2
    section Phase 5
    Play Store & App Store Launch :p5, after p4, 1
```

---

## 🚀 Local Development Setup

### Backend (NestJS Setup)
1. Navigate to the server folder: `cd backend`
2. Install dependencies: `npm install`
3. Configure environment parameters inside a `.env` file template:
   ```env
   DATABASE_URL=postgresql://user:password@localhost:5432/stoxneu
   JWT_SECRET=your_jwt_encryption_key
   REDIS_URL=redis://localhost:6379
   ```
4. Start development instance: `npm run start:dev`

### Frontend (Flutter Setup)
1. Initialize project path: `cd mobile_app`
2. Fetch target dependencies: `flutter pub get`
3. Launch target environment target emulator: `flutter run`

---

## OutPut
<img width="401" height="857" alt="ecom2" src="https://github.com/user-attachments/assets/a21a00ed-8849-46e2-ab69-c0dd8e7c526f" />
<img width="400" height="852" alt="ecom1" src="https://github.com/user-attachments/assets/484802ff-8a23-4060-9147-dba545027eb1" />
<img width="390" height="857" alt="popup" src="https://github.com/user-attachments/assets/640a10b5-8625-49b0-b873-4d1ce307236e" />
<img width="395" height="837" alt="ecom3" src="https://github.com/user-attachments/assets/ce34c356-ea37-4b65-829a-a9b1efe7fbfc" />
<img width="402" height="854" alt="ecom5" src="https://github.com/user-attachments/assets/b63b2009-505b-4120-b309-ab384f81ba5c" />
<img width="398" height="844" alt="ecom4" src="https://github.com/user-attachments/assets/fc6b0ea1-cb93-4586-b663-ad97b1dc0b72" />
<img width="398" height="864" alt="myorder" src="https://github.com/user-attachments/assets/c75292a0-0dcd-4915-a95a-7d8b016a3d6e" />
<img width="401" height="851" alt="pay" src="https://github.com/user-attachments/assets/7949162c-4b45-4749-9277-c75af84062eb" />
<img width="396" height="857" alt="wishlist" src="https://github.com/user-attachments/assets/8f17bd43-9be5-4cb0-a48c-74ab90a904eb" />
<img width="396" height="856" alt="profile" src="https://github.com/user-attachments/assets/0cac39f1-f4d2-4ace-b9ef-7325d62ea901" />
<img width="395" height="849" alt="help" src="https://github.com/user-attachments/assets/9c542795-44b6-421e-b119-d7fec3c39b54" />
<img width="396" height="857" alt="address" src="https://github.com/user-attachments/assets/a9dc9469-0b64-44bb-80f6-ce96d959e516" />



