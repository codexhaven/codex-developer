#!/usr/bin/env bash
# Plugin: PostHog Analytics Init
# Hook: after-build
set -e
PROJECT="${1:-$REPODIR}"
echo "PLUGIN: posthog-init — Adding analytics..."

mkdir -p "$PROJECT/lib/analytics"

cat > "$PROJECT/lib/analytics/posthog.ts" << 'POSTHOG'
import posthog from 'posthog-js';
import { PostHogProvider } from 'posthog-js/react';

if (typeof window !== 'undefined') {
  posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY!, {
    api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST || 'https://us.i.posthog.com',
    capture_pageview: true,
  });
}

export { posthog, PostHogProvider };
POSTHOG

echo "  PostHog: analytics provider ready"
echo "  Add NEXT_PUBLIC_POSTHOG_KEY to .env.local"
echo "  Wrap layout.tsx with <PostHogProvider>"
