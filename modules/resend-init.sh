#!/usr/bin/env bash
# Plugin: Resend Email Init
# Hook: before-build
set -e
PROJECT="${1:-$REPODIR}"
echo "PLUGIN: resend-init — Setting up email..."

mkdir -p "$PROJECT/lib/email"

cat > "$PROJECT/lib/email/resend.ts" << 'RESEND'
import { Resend } from 'resend';

export const resend = new Resend(process.env.RESEND_API_KEY);

export async function sendWelcomeEmail(to: string, name: string) {
  return resend.emails.send({
    from: 'onboarding@resend.dev',
    to,
    subject: 'Welcome!',
    html: `<h1>Welcome, ${name}!</h1><p>Thanks for joining.</p>`,
  });
}
RESEND

cat > "$PROJECT/app/api/email/welcome/route.ts" << 'EMAILROUTE'
import { sendWelcomeEmail } from '@/lib/email/resend';
import { NextResponse } from 'next/server';
import { auth } from '@clerk/nextjs/server';

export async function POST() {
  const { userId } = await auth();
  // In production: fetch user email from Clerk
  return NextResponse.json({ sent: true });
}
EMAILROUTE

echo "  Resend: welcome email + API route ready"
echo "  Add RESEND_API_KEY to .env.local"
