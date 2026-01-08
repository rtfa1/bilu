# Research Agent Brief
Using `research-brief` skill to turn “app to sell coffee online” into a research handoff.

## 1) Problem Statement
Build an online coffee-selling application that lets customers browse products, place orders, pay securely, and lets admins manage catalog, inventory, and fulfillment. Produce research on feasible architectures, build-vs-buy options, and key integrations (payments, tax, shipping/pickup, notifications), with clear tradeoffs and a recommended approach.

## 2) Target Users & Core Flows
### Customer flows
- Browse catalog (coffee beans, gear, subscriptions), search/filter, view product details.
- Configure product options (grind size, roast level, bag size), add to cart.
- Checkout (guest + optional account), pay, receive confirmation.
- Track order status; view order history; manage addresses/payment methods (via provider vaulting).
- Optional: subscribe (weekly/monthly), skip/pause, manage subscription.

### Admin/ops flows
- Manage products, variants/options, pricing, promotions, inventory.
- Manage orders (status, refunds, cancellations), fulfillment (shipping labels or pickup scheduling).
- Customer support view (order lookup, resend confirmation).
- Basic analytics (orders, revenue, inventory alerts).

## 3) Functional Requirements (MVP)
- Product catalog with variants/options, images, descriptions, pricing.
- Cart + checkout with payment processing (PCI handled by payment provider).
- Order creation, status tracking, email/SMS notifications.
- Admin dashboard for catalog + orders.
- Inventory tracking (simple stock counts; decrement on paid orders).
- Shipping or local pickup (at least one fulfillment mode) with address validation.
- Taxes calculation (basic fixed rate OR external tax service; research required).
- Authentication (customer optional; admin required) + role-based access control.
- Basic CMS needs (homepage, FAQs, policies) either built-in or integrated.

## 4) Non-Functional Requirements (Targets)
- Security: OWASP baseline; secure sessions; CSRF protection; rate limiting; audit logs for admin actions.
- Payments: avoid handling card data directly; use hosted checkout or payment elements + tokenization.
- Performance: p95 page load < 2s on broadband for catalog pages; p95 API < 300ms for typical queries.
- Reliability: graceful degradation if ancillary services fail (email, analytics).
- SEO + accessibility: indexable catalog pages; WCAG AA for storefront.
- Observability: structured logs, basic tracing, error reporting, admin activity logs.
- Privacy: minimize PII; clear data retention policy; encrypted secrets; encryption at rest where available.

## 5) Data Model (Initial Sketch)
- `Product`, `Variant` (options like grind/size), `Price`, `InventoryItem`
- `Cart`, `CartItem`
- `Order`, `OrderItem`, `Payment` (provider IDs only), `Refund`
- `Customer`, `Address`
- `Fulfillment` (shipping/pickup), `Shipment` (carrier label/tracking)
- `Promotion`/`Discount` (optional MVP)
- `AdminUser`, `Role`, `AuditEvent`

## 6) Architecture Options to Research (with Pros/Cons)
### Option A: SaaS commerce (Shopify/WooCommerce/etc.)
- Pros: fastest, built-in tax/shipping, admin UX, reliability.
- Cons: customization limits, ongoing platform constraints, less control over data/workflows.

### Option B: Headless commerce + custom frontend
- Frontend: Next.js/Remix + storefront UI; Backend: headless platform APIs.
- Pros: flexible UX while leveraging commerce features.
- Cons: integration complexity, costs, platform coupling.

### Option C: Custom web app (monolith)
- Example: Next.js (App Router) + server actions/API routes + Postgres; payments via Stripe; email via SES/SendGrid.
- Pros: full control, simpler mental model than microservices.
- Cons: you own tax/shipping edge cases; more engineering time.

### Option D: Mobile-first (React Native/Flutter) + backend
- Pros: push notifications, loyalty features.
- Cons: higher build effort; web still needed for discovery/SEO in many cases.

Deliver a recommendation based on constraints (team size, timeline, customization, budget sensitivity, scale).

## 7) Key Integrations to Research
- Payments: Stripe (Checkout vs Elements), PayPal, Apple Pay/Google Pay support.
- Tax: Stripe Tax, TaxJar, Avalara; nexus considerations depending on region.
- Shipping: Shippo, EasyPost, carrier APIs; label purchase + tracking webhooks.
- Email/SMS: SendGrid/Mailgun/SES; Twilio.
- Address validation: Google Places/Loqate; or shipping provider validation.
- Analytics/monitoring: Sentry, OpenTelemetry, managed logs.
- Identity: email/password + magic links; admin MFA options.

## 8) Security / Compliance Considerations
- PCI: ensure SAQ-A scope via hosted checkout or provider-managed fields; no raw PAN storage.
- Webhooks: signature verification, idempotency keys, replay protection.
- Auth: secure cookie sessions, password hashing (Argon2/bcrypt), MFA for admins.
- Data privacy: PII access minimization, GDPR/CCPA considerations if applicable.
- Fraud: basic checks (AVS/CVC via provider), velocity limits, risk scoring options.

## 9) Unknowns / Decisions Needed (Explicit)
- Fulfillment mode: shipping, local pickup, or both?
- Region(s) of operation (tax rules, privacy compliance).
- Product complexity: variants (grind/size), subscriptions, bundles, gift cards.
- Inventory rules: oversell allowed? backorders? roast-to-order lead times?
- Branding/content needs: blog/recipes, CMS requirements.
- Expected scale and peak traffic (affects hosting/caching choices).
- Required integrations (accounting, CRM, loyalty).

## 10) Research Questions (What the Research Agent Should Answer)
1. Which platform approach (A/B/C/D) best fits a small team building a coffee storefront with variants + possible subscriptions?
2. What is the simplest secure payment integration that keeps PCI scope minimal while supporting refunds and webhooks?
3. Best-practice order state machine (created/paid/fulfilled/shipped/canceled/refunded) for this domain.
4. Tax + shipping integration: recommended services and pitfalls for the chosen region(s).
5. Data model + API design patterns for cart/checkout that avoid race conditions and double-charges.
6. Hosting/deployment baseline (Vercel/Fly/Render/AWS) with cost/ops tradeoffs.
7. Security checklist and threat model for storefront + admin (top risks and mitigations).

## 11) Evaluation Plan (How to Choose)
- Build 1–2 small prototypes:
  - Catalog + cart + Stripe Checkout + webhook-driven order creation.
  - Admin “manage orders + inventory decrement” loop.
- Compare options on: implementation time, customization headroom, operational complexity, compliance scope, total integration surface area.
- Validate with test cases: double-submit checkout, webhook retries, refund flows, inventory concurrency, failed email/SMS, carrier API downtime.
- Produce a recommended architecture + phased roadmap (MVP → v1) with risks and mitigations.

## 12) Clarifying Questions (Answering These Changes the Recommendation)
1. Platform: `web only` / `web + mobile app`?
2. Fulfillment: `shipping` / `local pickup` / `both`?
3. Region: `US` / `EU` / `UK` / `other` (which)?
4. Products: do you need `subscriptions` (recurring) now or later?
5. Customization level: `basic storefront` / `highly custom UX (quiz, bundles, personalization)`?
6. Admin needs: `simple` / `advanced (multi-location inventory, staff roles, audit logs, returns)`?
7. Timeline/team: `1–2 weeks` / `1–2 months` / `3+ months`, and how many devs?

