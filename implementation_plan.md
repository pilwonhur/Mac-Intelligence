# Implementation Plan: Mac Intelligence MVP

This document outlines the step-by-step assembly of the Mac Intelligence application, transitioning from technical spikes to a cohesive, premium macOS product.

## Phase 1: Foundation & Architecture (Current)
- [x] **1.1 Project Scaffolding:** Initialize folder structure (Models, Views, Services, Utilities).
- [x] **1.2 App Entry Point:** Setup `MacIntelligenceApp` and `AppState` (ObservableObject).
- [x] **1.3 Ghost Window Shell:** Integrate the validated `GhostPanel` (NSPanel) into the SwiftUI lifecycle.
- [x] **1.4 Design System:** Define the premium visual language (Gradients, Glassmorphism, Typography).

## Phase 2: Core Integration
- [x] **2.1 Hotkey Service:** Port Spike #3 (Carbon) into a robust singleton service.
- [x] **2.2 Text Capture Engine:** Port Spike #1.8 (Hyper-Hybrid) into a consolidated `CaptureService`.
- [x] **2.3 Browser Scraper:** Port Spike #4 into the `CaptureService` for enhanced context.

## Phase 3: AI & Persistence
- [x] **3.1 Keychain Integration:** Securely store API keys.
- [ ] **3.2 LLM Service:** Implement OpenAI/Claude/Gemini API connectors.
- [ ] **3.3 Conversation Logic:** Manage prompt construction and stream handling.

## Phase 4: UI/UX Refinement
- [ ] **4.1 Interactive Chat UI:** Build the floating chat bubble and message thread.
- [ ] **4.2 Settings Panel:** Build the configuration interface (Hotkeys, Models, Theme).
- [ ] **4.3 Animations:** Implement smooth entry/exit transitions for the Ghost Window.

## Phase 5: Polish & Deployment
- [ ] **5.1 Error Handling:** User-friendly alerts for permissions and API issues.
- [ ] **5.2 Performance Tuning:** Optimize memory usage for the non-activating panel.
- [ ] **5.3 Final Sandbox Check:** Ensure app integrity for macOS security.
