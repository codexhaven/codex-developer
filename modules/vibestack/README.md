
# VibeStack-Builder Documentation

This directory contains the core reference documentation for the VibeStack framework. VibeStack is the mandatory development stack for all web application projects managed by this agent, ensuring consistency across all builds.

## Components of VibeStack

1. Next.js 14+: Provides the framework foundation with App Router support, server-side rendering, and API routes.
2. TypeScript: Ensures strict type safety, which is mandatory for all development to reduce runtime errors.
3. Tailwind CSS: Used for styling via utility classes, keeping the codebase clean and maintainable.
4. Shadcn UI: The designated component library for accessible, high-quality, and customizable UI elements.
5. Supabase: The unified backend platform providing PostgreSQL database, real-time subscriptions, and authentication.
6. Recharts: The standard for data visualization within all VibeStack projects.
7. pnpm: The mandatory package manager for dependency management, chosen for its efficiency and strictness.

## Feature Implementation Cards

### 1. Responsive UI
VibeStack projects prioritize mobile-first development. We utilize Tailwind's breakpoint system (sm, md, lg, xl) to ensure all components and layouts function seamlessly across mobile, tablet, and desktop devices.

### 2. Secure Authentication
Integration with Supabase Auth allows for robust user management. We enforce protected routes using Next.js Middleware and ensure that session data is handled safely on both the client and server sides.

### 3. Data-Driven Components
Recharts allows us to build complex, responsive data visualizations. By mapping Supabase query results directly to chart components, we create interactive dashboards that update in real-time.

## Developer Workflow

1. Initialization: Start all projects with `pnpm create next-app@latest` and install Shadcn CLI.
2. Architecture: Maintain a strictly modular `components/` directory.
3. Database: Document every table and relation in `db/schema.sql`.
4. Verification: Always run the mandatory VibeStack verification checklist before committing code.

## Mandatory Standards

We explicitly prohibit Flask, plain HTML/CSS, or vanilla JavaScript. By sticking to this refined stack, we maintain high engineering standards and ensure that every project is easily maintainable and scalable.