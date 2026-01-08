# Technical Research: Comparable Solutions (Coffee Online Store Platform + Integrations)

> Note (2026-01-08): Network access was not available while producing this report, so everything that depends on external documentation is treated as **Hypothesized** until you validate it against the linked primary sources.

## 0) Seed inputs used
- `docs/briefs/coffee-online-store-research-brief.md`
- `docs/research/coffee-online-store-technical-research.md` (prior draft)

## 1) Scope
- **System category:** Direct-to-consumer ecommerce store for coffee + gear (variants, promotions, shipping/pickup, optional subscriptions)
- **Comparables (3–8):**
  - Shopify — https://www.shopify.com/
  - Shopify (headless patterns via Storefront/Admin APIs) — https://shopify.dev/
  - WooCommerce — https://github.com/woocommerce/woocommerce
  - BigCommerce — https://www.bigcommerce.com/
  - Medusa (open-source headless) — https://github.com/medusajs/medusa
  - Saleor (open-source headless) — https://github.com/saleor/saleor
- **Features to analyze (5–12):**
  - Catalog + variants/options (grind/size/roast)
  - Cart + pricing + promotions
  - Checkout + payments (keep PCI scope minimal)
  - Order state machine + refunds
  - Inventory decrement + oversell/backorder rules
  - Fulfillment: shipping labels + tracking, or local pickup
  - Taxes calculation
  - Subscriptions (pause/skip/cancel)
  - Admin operations + RBAC + audit trail
  - Notifications (email/SMS)
- **Hard constraints (from the brief):** secure sessions + CSRF protection; webhook signature verification; idempotency; admin required; SEO for catalog; basic observability.
- **Timebox:** ~60 minutes, offline (no verified web access)

## 2) Executive technical summary (decision-ready)
- **Convergence:** Most successful “ship fast” setups converge on an off-the-shelf commerce core (Shopify / BigCommerce / WooCommerce) and avoid building checkout/payment capture from scratch; custom work is concentrated in brand UX and edge workflows.
- **What varies:** The biggest variance is where the “source of truth” lives (platform vs your DB) and how much of the checkout/order state machine you own (fully managed vs webhook-driven custom order service).
- **Key tradeoff for this project:** If you need unusual coffee-specific ops (roast-to-order lead times, bundles/quiz personalization, subscription flexibility), headless or custom becomes attractive—but it increases your webhook/eventing surface and operational burden.

## 3) Comparable-by-comparable snapshot

| Comparable | Likely stack | Architecture notes | Key integrations | Confidence | Sources |
|---|---|---|---|---:|---|
| Shopify (SaaS) | Proprietary platform; storefront templating + admin UI | “Platform owns” catalog, checkout, payments; apps extend via APIs/webhooks | Payments (Shopify Payments/partners), tax/shipping apps, email | M | https://www.shopify.com/ |
| Shopify headless | Custom storefront + Shopify APIs | You own frontend + some domain glue; Shopify remains commerce SoT | Same as above; plus your infra/observability | L | https://shopify.dev/ |
| WooCommerce | WordPress + plugin ecosystem | You own hosting/security; plugins cover tax/shipping/subscriptions | Many plugins for gateways/shipping/tax | M | https://github.com/woocommerce/woocommerce |
| BigCommerce | Proprietary SaaS | Similar “platform owns” commerce; can do headless | Payments + tax/shipping apps | L | https://www.bigcommerce.com/ |
| Medusa | Node-based OSS headless (hypothesized) | Self-hosted commerce backend; you build storefront + admin ops UX | Payment/shipping modules + your providers | L | https://github.com/medusajs/medusa |
| Saleor | OSS headless (Python/GraphQL commonly; hypothesized) | Self-hosted commerce; GraphQL-first; you build UX | Payment/shipping via integrations | L | https://github.com/saleor/saleor |

## 4) Evidence log (claims ledger)

| Claim | Status | Comparable(s) | Evidence | Notes |
|---|---|---|---|---|
| Hosted checkout keeps you out of raw PAN handling for most flows | Hypothesized | Shopify/BigCommerce/Stripe-based custom | https://stripe.com/docs/checkout | Confirm PCI scope language (SAQ) and hosted-vs-embedded implications |
| Webhooks must be verified via signatures and be idempotent under retries | Hypothesized | All | https://docs.stripe.com/webhooks/signatures ; https://docs.stripe.com/idempotency ; https://shopify.dev/ | Confirm retry semantics and header names per platform |
| Shopify supports subscriptions via purchase options/subscription APIs | Hypothesized | Shopify | https://shopify.dev/docs/apps/build/purchase-options/subscriptions | Confirm lifecycle events and limitations |
| Shipping labels + tracking are typically done via a broker API (Shippo/EasyPost) rather than direct carriers | Hypothesized | Custom/headless; sometimes platforms | https://docs.goshippo.com/ ; https://www.easypost.com/docs/api | Confirm webhook/event hooks for tracking updates |
| Tax calc is usually delegated to Stripe Tax / TaxJar / Avalara rather than built in-house | Hypothesized | Custom/headless | https://docs.stripe.com/tax ; https://developers.taxjar.com/ ; https://developer.avalara.com/ | Region determines feasibility and pricing |

## 5) Feature deep dives (how it works)

### Feature: Catalog + variants/options (grind/size/roast)
- **What the user sees:** product listing + product detail; option selectors; price/image changes per variant.
- **Likely components:** storefront UI; catalog API; media storage/CDN; search (optional).
- **Data flow (happy path):**
  1. Storefront requests product list (pagination + filters).
  2. Product detail fetch returns variants/options + availability + pricing rules.
  3. Option selections resolve to a specific variant SKU and price.
- **Failure modes:** stale inventory display; variant mismatch; missing images; cache staleness on price changes.
- **State/data model:** `Product` → `Variant` (SKU), `Option`/`OptionValue`, `Price` (currency), `Media`.
- **Performance/scaling notes:** CDN-cache product pages; edge caching for listings; precompute variant resolution; avoid N+1 image lookups.
- **Security/privacy notes:** low PII; ensure admin endpoints are access-controlled and audited.
- **Verified vs hypothesized:** all platform-specific limits/fields are hypothesized until you check platform docs.
- **Sources:** https://shopify.dev/ ; https://github.com/woocommerce/woocommerce ; https://github.com/medusajs/medusa ; https://github.com/saleor/saleor

### Feature: Cart + pricing + promotions
- **What the user sees:** add to cart, quantity changes, discount codes, estimated shipping/tax.
- **Likely components:** cart service (platform or custom); pricing engine; session storage (cookie + server state).
- **Data flow (happy path):**
  1. Client adds `variant_id` + quantity to cart.
  2. Server recomputes totals from authoritative prices/promos.
  3. Client renders totals; proceeds to checkout.
- **Failure modes:** price drift at checkout; invalid promo codes; concurrency issues from multiple tabs.
- **State/data model:** `Cart` (id, currency, items), `CartItem` (variant_id, qty, unit_price_snapshot), `Discount` (code, rules).
- **Performance/scaling notes:** store cart in DB or Redis; price recomputation on every mutation; keep totals deterministic and explainable.
- **Security/privacy notes:** validate all prices server-side; rate-limit promo code attempts.
- **Verified vs hypothesized:** cart primitives differ per platform; confirm “draft order”/“checkout session” models.
- **Sources:** https://stripe.com/docs/checkout ; https://shopify.dev/

### Feature: Checkout + payments (minimal PCI scope)
- **What the user sees:** address, shipping method, payment, confirmation.
- **Likely components:** hosted checkout (platform) or Stripe Checkout; webhook receiver; order service/DB; email sender.
- **Data flow (happy path, custom app w/ hosted checkout):**
  1. Server creates a checkout session (line items, totals, customer email).
  2. Client redirects to hosted checkout.
  3. Provider confirms payment, emits webhook.
  4. Webhook handler verifies signature, ensures idempotency, creates/updates `Order`.
  5. Confirmation email is sent after durable order creation.
- **Failure modes:** webhook arrives before user returns; retries cause duplicates; partial failures (payment succeeded but order not recorded); mismatched totals.
- **State/data model:** `PaymentIntent`/`CheckoutSession` IDs; `Order` with `payment_status`; idempotency key stored per event.
- **Performance/scaling notes:** webhook handlers must be fast; push heavy work to background jobs; use durable storage for dedupe.
- **Security/privacy notes:** signature verification; replay protection; least-privilege API keys; don’t log sensitive PII.
- **Verified vs hypothesized:** exact event types and “best practice” flows must be validated from Stripe/platform docs.
- **Sources:** https://stripe.com/docs/checkout ; https://docs.stripe.com/webhooks/signatures ; https://docs.stripe.com/idempotency

### Feature: Order state machine + refunds
- **What the user sees:** order confirmation, status tracking, refunds/updates.
- **Likely components:** order DB; admin UI; payment provider; notification pipeline.
- **Data flow (happy path):**
  1. `Order` created with `payment_status=paid` (or `authorized`) after webhook.
  2. Fulfillment updates status (`fulfilled/shipped`).
  3. Refunds create `Refund` records and adjust totals; emit customer notifications.
- **Failure modes:** partial refunds; chargebacks/disputes; fulfillment updates missing due to integration downtime.
- **State/data model:** `Order` (status, totals), `OrderItem`, `Refund` (amount, reason), `Fulfillment` (carrier, tracking, timestamps).
- **Performance/scaling notes:** append-only event log (optional) helps audit; keep state transitions explicit.
- **Security/privacy notes:** admin RBAC; audit trail; prevent refund abuse (permissions + approvals).
- **Verified vs hypothesized:** platform-specific order states and webhooks must be confirmed.
- **Sources:** https://docs.stripe.com/ ; https://shopify.dev/

### Feature: Inventory decrement + oversell/backorder rules
- **What the user sees:** “in stock”/“out of stock” messaging; backorder lead times (optional).
- **Likely components:** inventory service; reservation logic; reconciliation job.
- **Data flow (happy path):**
  1. On checkout session creation: optionally reserve stock (soft lock).
  2. On payment success: decrement stock; on failure/timeout: release reservation.
  3. Nightly reconciliation compares “sold” vs inventory counts (if you have warehouse truth elsewhere).
- **Failure modes:** double decrement; oversell during spikes; stale reservations; manual adjustments.
- **State/data model:** `InventoryItem` (on_hand, reserved, available), `InventoryReservation` (cart_id, qty, expires_at), `StockAdjustment`.
- **Performance/scaling notes:** concurrency control per SKU (row locks or atomic counters); prefer monotonic adjustments + reconciliation.
- **Security/privacy notes:** admin-only mutations; audit adjustments.
- **Verified vs hypothesized:** platform “inventory” semantics vary; confirm whether reservations exist or if you only get “best effort”.
- **Sources:** https://shopify.dev/ ; https://github.com/medusajs/medusa ; https://github.com/saleor/saleor

### Feature: Fulfillment (shipping labels + tracking) OR local pickup
- **What the user sees:** shipping rates; tracking links; pickup scheduling instructions.
- **Likely components:** shipping rate/label service; webhook receiver for tracking updates; admin fulfillment workflow.
- **Data flow (shipping, custom):**
  1. Address validation + shipping rates returned during checkout.
  2. After payment, create shipment + purchase label via Shippo/EasyPost.
  3. Store tracking number; send “shipped” email.
  4. Tracking webhooks update shipment milestones.
- **Failure modes:** carrier API downtime; label purchase fails; address validation false positives; tracking webhook drop.
- **State/data model:** `Shipment` (carrier, label_url, tracking_number, status), `Fulfillment` (packed_at, shipped_at).
- **Performance/scaling notes:** async label generation; retries with backoff; idempotent shipment creation.
- **Security/privacy notes:** protect label URLs; don’t expose full addresses in logs.
- **Verified vs hypothesized:** exact API flows depend on provider and chosen carriers.
- **Sources:** https://docs.goshippo.com/ ; https://www.easypost.com/docs/api

### Feature: Taxes calculation
- **What the user sees:** tax line items at checkout; tax on invoice/receipt.
- **Likely components:** tax provider API; product tax codes; jurisdiction rules.
- **Data flow (custom):**
  1. Compute tax quote for cart + destination.
  2. Persist quote inputs (to explain totals).
  3. On payment, record finalized tax amounts and provider IDs for reporting.
- **Failure modes:** wrong nexus settings; rounding differences; tax changes after order; exemptions.
- **State/data model:** `TaxQuote` (inputs + outputs), `OrderTaxLine` (jurisdiction, rate, amount), `CustomerExemption` (optional).
- **Performance/scaling notes:** cache tax quotes per cart revision; avoid calling provider on every keystroke.
- **Security/privacy notes:** minimize address retention; treat tax provider keys as high sensitivity.
- **Verified vs hypothesized:** which provider supports your region and product types must be validated.
- **Sources:** https://docs.stripe.com/tax ; https://developers.taxjar.com/ ; https://developer.avalara.com/

### Feature: Subscriptions (pause/skip/cancel)
- **What the user sees:** recurring delivery schedule, skip/pause, address changes, payment updates.
- **Likely components:** subscription billing provider; subscription state machine; proration/next-billing calculation; customer portal.
- **Data flow (typical):**
  1. Customer creates subscription (plan + cadence + shipping info).
  2. Billing provider charges on schedule and emits events.
  3. Your system updates “next shipment” and generates fulfillment orders.
  4. Customer changes schedule; system reconciles billing and fulfillment.
- **Failure modes:** payment retries; skipped shipment but charged; schedule drift; cancellation timing.
- **State/data model:** `Subscription` (status, cadence, next_charge_at, next_ship_at), `SubscriptionItem`, `SubscriptionEvent`.
- **Performance/scaling notes:** event-driven; treat provider events as source for billing state; keep fulfillment derived.
- **Security/privacy notes:** protect customer portal; ensure authorization for subscription mutations.
- **Verified vs hypothesized:** subscription feature completeness varies sharply by platform/provider; validate early.
- **Sources:** https://shopify.dev/docs/apps/build/purchase-options/subscriptions

## 6) “Glue” patterns across comparables
- **Auth:** storefront often supports guest checkout; admin requires strong auth + RBAC; SaaS platforms provide admin auth; custom apps typically use cookie sessions with CSRF protection.
- **Payments:** hosted checkout + webhook-driven order recording is a common low-PCI pattern; idempotency and signature verification are the correctness foundation. (See Stripe links in Section 4.)
- **Async + retries:** expect webhook retries; use durable dedupe keys (event ID) and queue background jobs for email/label creation.
- **Storage:** platform options externalize storage; custom/headless commonly use a relational DB for orders/inventory + object storage/CDN for images.
- **Search:** platform search is often “good enough”; custom storefronts add Algolia/Meilisearch/Elasticsearch when filters and speed matter. (Hypothesized.)
- **Observability:** structured logs + error reporting; webhook endpoints need high-cardinality correlation IDs and clear “processed/ignored” outcomes.
- **Deployment:** SaaS reduces infra; headless/custom typically use a CDN/edge for storefront plus a regionally deployed API + worker queue.

## 7) Reference architecture proposal (for our project)

### Path A: SaaS-first (recommended default for fastest MVP)
- **Components:** Shopify storefront (theme or headless) + Shopify admin + minimal custom service for anything bespoke (e.g., loyalty, roast scheduling).
- **Interfaces:** Shopify Admin/Storefront APIs + webhooks into a small integration service (optional).
- **Data model sketch:** treat Shopify as SoT for products/orders; mirror only what you must (e.g., analytics events, roast queue items).
- **Operational plan:** avoid custom infra early; add an integration service only when there’s a concrete gap.

### Path C: Custom app (when you truly need ownership/control)
- **Components:** Next.js storefront + admin; API service; worker/queue; Postgres; object storage; payment provider; tax provider; shipping broker.
- **Interfaces:** REST/GraphQL internally; webhooks inbound from payment/shipping; outbound emails/SMS.
- **Data model sketch:** `Product/Variant`, `Cart`, `Order/OrderItem`, `Payment`, `Refund`, `InventoryItem/Reservation`, `Shipment`, `Customer`, `AdminUser/Role`, `AuditEvent`.
- **Operational plan:** treat webhooks as a separate “ingest boundary”; implement replay-safe processing; add backups and runbooks early.

## 8) Technology shortlist to prototype

| Area | Candidate | Why | Risks | Sources |
|---|---|---|---|---|
| Payments | Stripe Checkout | Hosted checkout; strong webhook tooling | Event-driven complexity; reconcile edge cases | https://stripe.com/docs/checkout |
| Webhook security | Stripe signature verification + idempotency | Correctness under retries | Easy to get wrong without tests | https://docs.stripe.com/webhooks/signatures ; https://docs.stripe.com/idempotency |
| Shipping | Shippo or EasyPost | Broker simplifies multi-carrier labels/tracking | Costs; carrier coverage | https://docs.goshippo.com/ ; https://www.easypost.com/docs/api |
| Tax | Stripe Tax vs TaxJar vs Avalara | Delegate rules + rates | Region/product-fit variability | https://docs.stripe.com/tax ; https://developers.taxjar.com/ ; https://developer.avalara.com/ |
| Commerce core (build-ish) | Medusa or Saleor | Faster than full custom if you self-host | Still a real platform to operate | https://github.com/medusajs/medusa ; https://github.com/saleor/saleor |

## 9) PoCs to de-risk (fast validations)

| PoC | Purpose | Steps | Timebox | Pass criteria |
|---|---|---|---:|---|
| Checkout + webhook → order | Prove you can’t double-create orders | Create hosted checkout; implement signature verify + dedupe; replay webhook fixtures | 4–8h | 0 duplicate orders across 20 replays |
| Shipping label purchase | Validate fulfillment workflow | Create shipment from an order; buy label; store tracking; handle webhook updates | 1 day | Label + tracking link generated reliably |
| Inventory concurrency | Avoid oversell | Implement per-SKU locking or atomic decrement; simulate 50 parallel checkouts | 4–8h | No negative inventory; consistent reservations |
| Subscription lifecycle | Decide “now vs later” | Create subscription; pause/skip; generate next shipment; handle payment failure | 1–2 days | Correct shipment schedule under changes |
| Tax quoting | Validate totals | Compute tax for 5 real carts + addresses; verify rounding | 2–4h | Totals match provider and receipts |

## 10) References (with access date)
Because network access was unavailable, these are the intended primary references to validate next (not yet accessed/verified in this environment):
- Shopify — https://www.shopify.com/ (planned access 2026-01-08)
- Shopify developer docs — https://shopify.dev/ (planned access 2026-01-08)
- Shopify subscription docs — https://shopify.dev/docs/apps/build/purchase-options/subscriptions (planned access 2026-01-08)
- WooCommerce repo — https://github.com/woocommerce/woocommerce (planned access 2026-01-08)
- BigCommerce — https://www.bigcommerce.com/ (planned access 2026-01-08)
- Medusa repo — https://github.com/medusajs/medusa (planned access 2026-01-08)
- Saleor repo — https://github.com/saleor/saleor (planned access 2026-01-08)
- Stripe Checkout — https://stripe.com/docs/checkout (planned access 2026-01-08)
- Stripe webhook signatures — https://docs.stripe.com/webhooks/signatures (planned access 2026-01-08)
- Stripe idempotency — https://docs.stripe.com/idempotency (planned access 2026-01-08)
- Stripe Tax — https://docs.stripe.com/tax (planned access 2026-01-08)
- TaxJar developer docs — https://developers.taxjar.com/ (planned access 2026-01-08)
- Avalara developer docs — https://developer.avalara.com/ (planned access 2026-01-08)
- Shippo docs — https://docs.goshippo.com/ (planned access 2026-01-08)
- EasyPost docs — https://www.easypost.com/docs/api (planned access 2026-01-08)

## 11) Next actions
1. Confirm brief unknowns: fulfillment (shipping/pickup/both), region(s), subscriptions now vs later.
2. Choose platform path: Shopify SaaS (fastest MVP) vs headless/custom (max control).
3. Run PoC #1 (checkout + webhook idempotency) before building the rest of the app.
4. Choose shipping/tax provider based on region and run PoCs #2 and #5.
5. If subscriptions are in MVP, run PoC #4 immediately (it’s the highest-leverage risk reducer).
