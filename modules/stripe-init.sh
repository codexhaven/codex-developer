#!/usr/bin/env bash
# Plugin: Stripe Payments Init
# Hook: before-build
# Creates Stripe checkout integration files
set -e

PROJECT="${1:-$REPODIR}"
echo "PLUGIN: stripe-init — Setting up Stripe payments..."

# Create Stripe webhook handler
mkdir -p "$PROJECT/app/api/webhooks/stripe"

cat > "$PROJECT/lib/stripe.ts" << 'STRIPE'
import Stripe from 'stripe';

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2024-06-20',
  typescript: true,
});

export async function createCheckoutSession(priceId: string, userId: string) {
  return stripe.checkout.sessions.create({
    payment_method_types: ['card'],
    line_items: [{ price: priceId, quantity: 1 }],
    mode: 'subscription',
    success_url: `${process.env.NEXT_PUBLIC_URL}/dashboard?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${process.env.NEXT_PUBLIC_URL}/billing`,
    client_reference_id: userId,
  });
}
STRIPE

cat > "$PROJECT/app/api/webhooks/stripe/route.ts" << 'WEBHOOK'
import { stripe } from '@/lib/stripe';
import { NextResponse } from 'next/server';

export async function POST(req: Request) {
  const body = await req.text();
  const sig = req.headers.get('stripe-signature')!;
  try {
    const event = stripe.webhooks.constructEvent(body, sig, process.env.STRIPE_WEBHOOK_SECRET!);
    switch (event.type) {
      case 'checkout.session.completed':
        // Handle subscription activation
        break;
    }
    return NextResponse.json({ received: true });
  } catch (err) {
    return NextResponse.json({ error: 'Webhook error' }, { status: 400 });
  }
}
WEBHOOK

echo "  Stripe: checkout + webhooks ready"
echo "  Add STRIPE_SECRET_KEY and STRIPE_WEBHOOK_SECRET to .env.local"
