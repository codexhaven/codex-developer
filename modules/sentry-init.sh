#!/usr/bin/env bash
# Plugin: Sentry Error Tracking Init
# Hook: after-build
set -e
PROJECT="${1:-$REPODIR}"
echo "PLUGIN: sentry-init — Adding error tracking..."

cat > "$PROJECT/lib/sentry.ts" << 'SENTRY'
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 1.0,
  environment: process.env.NODE_ENV || 'development',
});

export { Sentry };
SENTRY

cat > "$PROJECT/app/error.tsx" << 'SENTRY_ERROR'
'use client';
import { useEffect } from 'react';

export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  useEffect(() => { console.error(error); }, [error]);
  return (
    <div>
      <h2>Something went wrong!</h2>
      <button onClick={reset}>Try again</button>
    </div>
  );
}
SENTRY_ERROR

echo "  Sentry: error tracking + error boundary ready"
echo "  Add NEXT_PUBLIC_SENTRY_DSN to .env.local"
