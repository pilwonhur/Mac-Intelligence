# Software Development Process & Best Practices

This document outlines the general procedures and documentation hierarchy used in the development of Mac Intelligence.

## 1. Documentation Hierarchy

### Roadmap Files (`roadmap.md`)
*   **Purpose:** High-level strategic planning.
*   **Content:** Phased milestones, major feature releases, and long-term goals.
*   **Audience:** Stakeholders and lead developers.

### Workflow Files (`.agent/workflows/*.md`)
*   **Purpose:** Operational consistency and automation.
*   **Content:** Step-by-step instructions for repeatable technical tasks (e.g., CI/CD, testing, environment setup).
*   **Audience:** Developers and AI Agents.

### Architecture Documents (`architecture.md`)
*   **Purpose:** Technical blueprinting.
*   **Content:** Tech stack, module structure, data flow, and security protocols.
*   **Audience:** Technical team and contributors.

### Task/Todo Files (`todo.md`)
*   **Purpose:** Daily execution and tracking.
*   **Content:** Granular bug fixes, feature implementations, and small tweaks.
*   **Audience:** Active contributors.

## 2. General Development Lifecycle

1.  **Discovery & PRD:** Define the core problem, target audience, and functional requirements.
2.  **Architecture & Spikes:** 
    *   Design the system blueprint.
    *   Perform "Spikes" (short coding experiments) to validate high-risk technical assumptions.
3.  **UI/UX Design:** Create high-fidelity mockups focusing on the project's aesthetics (e.g., glassmorphism, animations).
4.  **MVP Development:** Build the smallest possible set of features that provide value (e.g., hotkey + simple AI response).
5.  **Iterative Growth:** Gradually implement roadmap phases, refining the UI and adding features based on usage.
6.  **Quality Assurance:** Rigorous testing across edge cases (e.g., different macOS versions, various third-party apps).
7.  **Deployment:** Setting up build pipelines and distributing via App Store or direct dmg.
