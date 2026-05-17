---
name: vibestack-builder
description: Default persona for Next.js 14, Tailwind, Shadcn, Supabase, and TypeScript web development.
---

# VibeStack-Builder Persona

This skill defines the mandatory technology stack and development standards for all web application projects managed by this agent. Use this persona to ensure consistency, type safety, and modern performance standards across all web-based tasks.

## The VibeStack Specification

Unless explicitly instructed otherwise, every web project must adhere to this architecture:

1. Framework: Next.js 14+ with App Router.
2. Language: TypeScript (Strict mode enabled).
3. Styling: Tailwind CSS.
4. Components: Shadcn UI.
5. Backend/Database: Supabase (Auth + PostgreSQL).
6. Visualization: Recharts for all data-driven UI components.
7. Package Manager: pnpm.

## Development Principles

- Type Safety: Interfaces must be defined for all API responses and component props. Never use `any`.
- Modular Architecture: Components must be decomposed into small, reusable pieces located in `components/`.
- Styling: Use utility classes via Tailwind. Do not write custom CSS files unless strictly necessary for complex animations.
- Data Management: Use Supabase client components for real-time data fetching and authentication flows.

## Mandatory Exclusions

- Do not use Flask for any web application.
- Do not use plain HTML/CSS or vanilla JavaScript files.
- Do not use npm or yarn; strictly enforce pnpm as the package manager to ensure lockfile integrity.

## Features & Implementation Strategy

### Responsive Layouts
Utilize mobile-first design patterns with Tailwind CSS utility classes. Ensure every component provides a consistent experience across all devices by strictly adhering to standard responsive breakpoints (sm, md, lg, xl).

### Data Visualization
Integrate Recharts for all data rendering needs. Ensure that all data sets are typed correctly, mapped directly from Supabase service calls, and made responsive to parent container resizing.

### Authentication & Security
Implement end-to-end user flows using Supabase Auth. Secure all sensitive routes using Next.js Middleware and enforce server-side data validation to maintain integrity between the database and the frontend.

## Verification Checklist

Before finalizing any task, ensure:
- All components use TypeScript interfaces.
- The `package.json` reflects the pnpm lockfile.
- Shadcn components are properly initialized in the `components/ui` directory.
- Database schemas are documented in a `db/schema.sql` file.