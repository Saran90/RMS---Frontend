# Implementation Plan: RMS Flutter Frontend — Staff/Owner Management Portal

## Overview

This plan builds the Staff/Owner Management Portal bottom-up: foundation packages first (models, API client, auth, core UI), then the navigation shell, then feature screens in dependency order. Each task is independently implementable and references the specific requirements and design sections it satisfies. Property-based tests are placed close to the implementations they validate.

---

## Tasks

- [x] 1. Bootstrap monorepo structure and package scaffolding
  - Create root `pubspec.yaml` with `workspace:` entries for all sub-packages
  - Scaffold `apps/staff_portal/pubspec.yaml`, `apps/customer_app/pubspec.yaml`
  - Scaffold `packages/models/pubspec.yaml`, `packages/api_client/pubspec.yaml`, `packages/auth/pubspec.yaml`, `packages/core_ui/pubspec.yaml`
  - Add `path:` dependency entries in root and consumer pubspecs per the package dependency graph in Design §Architecture
  - Configure `analysis_options.yaml` and `l10n.yaml` at root
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 2. Create `apps/customer_app` stub
  - [x] 2.1 Scaffold the customer app entry point
    - Write `apps/customer_app/lib/main.dart` with a minimal `MaterialApp` that compiles without errors
    - Ensure `apps/customer_app/pubspec.yaml` has no path reference to `apps/staff_portal` or shared packages
    - _Requirements: 1.4_


- [x] 3. Implement `packages/models` — domain models and enums
  - [x] 3.1 Define enums and base types
    - Write `OrderStatus`, `TableStatus`, `KdsItemStatus`, `DietaryType`, `StaffRole`, `OrderType` enums in `packages/models/lib/src/enums.dart`
    - Write `PaginatedResponse<T>` and `PaginationMeta` freezed classes
    - _Requirements: 1.5_
  - [x] 3.2 Implement core freezed domain models
    - Implement `MenuItem`, `Order`, `Bill`, `Table`, `Staff`, `KdsItem`, `Subscription`, `Restaurant` with `freezed` + `json_serializable`
    - Run `build_runner` to generate `.freezed.dart` and `.g.dart` files
    - _Requirements: 1.5_
  - [x] 3.3 Write property test for model serialization round-trip (Property 1)
    - **Property 1: Model Serialization Round-Trip**
    - Use `fast_check` to generate arbitrary valid instances of each domain model and assert `fromJson(instance.toJson()) == instance`
    - Tag: `// Feature: rms-flutter-frontend, Property 1: Model round-trip`
    - **Validates: Requirements 1.5**

- [x] 4. Implement `packages/api_client` — Dio ApiClient and interceptors
  - [x] 4.1 Implement `ApiClient` with `RequestIdInterceptor`
    - Create `ApiClient` class backed by Dio with 30-second connect/receive/send timeouts
    - Implement `RequestIdInterceptor` that injects `X-Request-ID: <UUID v4>` on every request
    - Expose typed `get`, `post`, `patch`, `delete` methods and `ApiException` class
    - _Requirements: 1.6, 18.6, 18.8_
  - [x] 4.2 Implement `AuthInterceptor` with Mutex-guarded token refresh
    - Attach `Authorization: Bearer <token>` header from `TokenRepository`
    - On 401: acquire mutex lock, call `POST /api/v1/auth/refresh` once, save new tokens, retry original request; if refresh fails emit `TokenRefreshFailed`
    - Queue concurrent 401 requests to reuse the new token without triggering multiple refreshes
    - _Requirements: 18.1, 18.2_
  - [x] 4.3 Implement `ErrorInterceptor`
    - Map 4xx (non-401) responses to `ApiException` using server `message` field or fallback generic message
    - Map 5xx responses to `ApiException` with "Server error, please try again"
    - Map timeouts to `ApiException` with "Request timed out"
    - _Requirements: 18.3, 18.4, 18.5, 18.6_
  - [x] 4.4 Write property test for request tracing header (Property 13)
    - **Property 13: Request Tracing Header**
    - Use `fast_check` with mock HTTP handler: for any sequence of concurrent API calls, assert every request contains `X-Request-ID` matching the UUID v4 pattern and no two concurrent requests share the same value
    - Tag: `// Feature: rms-flutter-frontend, Property 13: Request tracing header`
    - **Validates: Requirements 18.8**


- [x] 5. Implement `packages/auth` — TokenRepository and AuthBloc
  - [x] 5.1 Implement `TokenRepository` with `flutter_secure_storage`
    - Implement `saveBaseToken`, `saveTenantToken`, `getBaseToken`, `getTenantToken`, `clearAll`, `isTenantTokenValid` (checks JWT `exp` claim)
    - _Requirements: 2.7, 2.8, 2.9_
  - [x] 5.2 Implement `AuthBloc` state machine
    - Handle `AppStarted`, `LoginRequested`, `RegisterRequested`, `RestaurantSelected`, `LogoutRequested`, `TokenRefreshFailed`, `ChangePasswordRequested` events
    - Emit `AuthInitial`, `AuthLoading`, `Unauthenticated`, `BaseAuthenticated`, `TenantAuthenticated(role)`, `AuthError` states
    - Extract and store `StaffRole` from Tenant_JWT claims in `TenantAuthenticated` state
    - Handle missing or unrecognised role claim by emitting `AuthError` and redirecting to Login
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.8, 2.9, 16.1, 16.2_

- [x] 6. Implement `packages/core_ui` — theme, responsive layout, and shared widgets
  - [x] 6.1 Define `AppTheme` and `ScreenBreakpoints`
    - Implement `AppTheme` with light-mode `ThemeData`, `TextTheme`, `ColorScheme`, and spacing constants satisfying 4.5:1 contrast ratio for normal text and 3:1 for large text
    - Define `ScreenBreakpoints.compact = 600`, `ScreenBreakpoints.medium = 1024`
    - _Requirements: 17.1, 17.2, 17.3, 20.3_
  - [x] 6.2 Implement `ResponsiveLayout` widget
    - Accept `compact`, `medium`, `expanded` slots and render correct slot based on `MediaQuery` width against breakpoints
    - _Requirements: 17.1, 17.2, 17.3_
  - [x] 6.3 Write property test for responsive breakpoint consistency (Property 14)
    - **Property 14: Responsive Layout Breakpoint Consistency**
    - Use `fast_check` to generate arbitrary double screen widths; pump `ResponsiveLayout` at each width and assert the rendered nav widget type matches the correct breakpoint bucket with no gaps or overlaps
    - Tag: `// Feature: rms-flutter-frontend, Property 14: Breakpoint consistency`
    - **Validates: Requirements 17.1, 17.2, 17.3**
  - [x] 6.4 Implement shared widgets
    - Implement `AppScaffold`, `ErrorStateWidget`, `RetryButton`, `LoadingSkeletonCard`, `ConfirmationDialog`
    - Implement `DietaryBadge` (veg: green circle, non_veg: brown circle, vegan: green leaf, egg: yellow circle per FSSAI)
    - Implement `StatusBadge`, `OfflineBanner`, `PaginatedListView`
    - Implement `FormValidator.submitAndFocus()` helper that moves focus to first erring field before any other UI update
    - Ensure all interactive widgets have minimum 48×48 dp touch targets and non-empty semantic labels
    - _Requirements: 7.11, 17.1–17.3, 19.1, 20.1, 20.2, 20.4_
  - [x] 6.5 Write property test for form focus on validation failure (Property 15)
    - **Property 15: Form Focus on Validation Failure**
    - Use `fast_check` to generate forms with errors on arbitrary field positions; assert focus is on the first erring field before any other UI update
    - Tag: `// Feature: rms-flutter-frontend, Property 15: Form focus on error`
    - **Validates: Requirements 20.4**


- [x] 7. Checkpoint — Foundation packages complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Implement `apps/staff_portal` — navigation shell and GoRouter
  - [x] 8.1 Implement `AppRouter` with all routes and redirect guards
    - Declare all routes: `/login`, `/register`, `/restaurant-selector`, `/onboarding`, `/dashboard`, `/menu`, `/tables`, `/orders`, `/orders/:id`, `/kds`, `/billing`, `/billing/:id`, `/staff`, `/inventory`, `/reports`, `/settings`
    - Implement redirect guards: no valid Tenant_JWT → `/login`; has Base_JWT but no Tenant_JWT → `/restaurant-selector`; role lacks permission → `/dashboard` with "Access Denied" message
    - Wire `AuthBloc` stream to `GoRouter.refreshListenable` so guards re-evaluate on state change
    - _Requirements: 2.8, 2.9, 3.3, 15.8, 16.7, 16.8_
  - [x] 8.2 Implement role-based navigation item visibility
    - Read `StaffRole` from `AuthBloc` state and show/hide nav items per Req 16.3–16.6
    - Integrate `ResponsiveLayout` into `AppScaffold`: bottom nav (< 600 dp), nav rail (600–1023 dp), side drawer (≥ 1024 dp)
    - _Requirements: 16.3, 16.4, 16.5, 16.6, 17.1, 17.2, 17.3_
  - [x] 8.3 Write property test for role-based navigation invariant (Property 4)
    - **Property 4: Role-Based Navigation Invariant**
    - Use `fast_check` to generate arbitrary `StaffRole` values; pump the nav shell and assert the exact set of visible nav items matches the role's permitted set and that restricted route navigation is blocked with redirect to `/dashboard`
    - Tag: `// Feature: rms-flutter-frontend, Property 4: Role navigation`
    - **Validates: Requirements 16.3, 16.4, 16.5, 16.6, 16.7**
  - [x] 8.4 Implement offline awareness with `connectivity_plus`
    - Create `ConnectivityCubit` using `connectivity_plus` that emits online/offline states
    - Show `OfflineBanner` on every screen when offline; dismiss automatically on reconnect
    - Disable all write actions while offline; show "internet connection required" tooltip on tap of any disabled control
    - _Requirements: 19.1, 19.2, 19.3, 19.4_
  - [x] 8.5 Write property test for offline write suppression (Property 6)
    - **Property 6: Offline Write Suppression**
    - Use `fast_check` to generate arbitrary write actions attempted while connectivity state is offline; assert no outgoing HTTP request is emitted and tooltip is shown
    - Tag: `// Feature: rms-flutter-frontend, Property 6: Offline suppression`
    - **Validates: Requirements 19.2, 19.4**


- [x] 9. Implement Authentication screens
  - [x] 9.1 Implement Register screen and `AuthRepository`
    - Create `AuthRepository` with `register`, `login`, `changePassword`, `refresh` methods delegating to `ApiClient`
    - Build Register screen form (name, email, password ≥ 8 chars) with inline validation; on success navigate to `/login`
    - _Requirements: 2.1_
  - [x] 9.2 Implement Login screen
    - Build Login screen form (email, password) connected to `AuthBloc` `LoginRequested` event
    - On HTTP 401 display inline error without clearing email field
    - On success navigate to `/restaurant-selector`
    - _Requirements: 2.2, 2.3_
  - [x] 9.3 Implement Change Password screen
    - Build Change Password form (current password, new password ≥ 8 chars) connected to `AuthBloc` `ChangePasswordRequested` event
    - Show validation error on new password < 8 chars before network call; show inline error on wrong current password
    - Display confirmation message on success
    - _Requirements: 2.4, 2.5, 2.6_
  - [x] 9.4 Write property test for short password validation (Property 2)
    - **Property 2: Short Password Validation**
    - Use `fast_check` to generate strings of length 0–7; assert validation error appears and no HTTP call is made
    - Tag: `// Feature: rms-flutter-frontend, Property 2: Short password rejection`
    - **Validates: Requirements 2.6**

- [x] 10. Implement Restaurant Selector screen
  - [x] 10.1 Implement `RestaurantRepository` and `RestaurantBloc`
    - Create `RestaurantRepository` with `getRestaurants()` and `selectRestaurant(id)` delegating to `ApiClient`
    - `RestaurantBloc` loads restaurant list on init; on empty list shows "create restaurant" prompt
    - _Requirements: 3.1, 3.2, 3.5, 3.6_
  - [x] 10.2 Build Restaurant Selector screen UI
    - Display restaurant list with loading indicator, error + retry, empty-state prompt
    - On selection call `POST /api/v1/restaurants/:id/select`, store Tenant_JWT, navigate to `/dashboard`; on token-save failure stay on screen with error message
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_


- [x] 11. Implement Onboarding and Subscription wizard
  - [x] 11.1 Implement `OnboardingRepository` and `OnboardingBloc`
    - Create `OnboardingRepository` with `createRestaurant`, `createSubscription`, `verifyPayment` methods
    - `OnboardingBloc` drives step transitions: restaurant details → plan selection → payment → confirmation
    - Skip flow if active subscription already exists, routing directly to Dashboard
    - _Requirements: 4.1, 4.2, 4.5, 4.6, 4.7, 4.9_
  - [x] 11.2 Build multi-step wizard UI with step indicator
    - Step 1 — Restaurant Details form (name, address, GST number) with required-field validation
    - Step 2 — Plan Selection listing available `Subscription_Plan` options
    - Step 3 — Razorpay payment sheet via `razorpay_flutter` plugin; on success call verification endpoint; on failure or dismissal stay on Plan Selection with error
    - Step 4 — Confirmation screen; step indicator visible at all times
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8_
  - [x] 11.3 Write unit tests for required field validation (Property 3 — onboarding fields)
    - **Property 3 (partial): Required Field Validation — No Network Call on Missing Input**
    - Covers Create Restaurant form missing name / address / GST number
    - Tag: `// Feature: rms-flutter-frontend, Property 3: Required field validation`
    - **Validates: Requirements 4.3**

- [x] 12. Implement Dashboard screen
  - [x] 12.1 Implement `DashboardRepository` and `DashboardBloc` with 60-second polling
    - Create `DashboardRepository` with `getSummaryStats()` and `getActiveOrders()` methods
    - `DashboardBloc` fetches both on load; starts `Stream.periodic(60s)` polling while screen is active
    - _Requirements: 5.1, 5.2, 5.7_
  - [x] 12.2 Build Dashboard screen UI
    - Display metric cards (total orders, total revenue, table occupancy) with `LoadingSkeletonCard` while loading; replace all skeletons only after all data loaded
    - Display active orders list (sorted newest-first for statuses pending/confirmed/preparing/ready/served)
    - Show error card with retry button on summary error; show error message in orders area on orders error
    - Navigate to `/orders/:id` on order tap (only when no error card shown)
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_


- [x] 13. Implement Menu Management — Categories
  - [x] 13.1 Implement `MenuRepository` (categories) and `MenuCategoryBloc`
    - Create `MenuRepository.getCategories()`, `createCategory()`, `updateCategory()`, `deleteCategory()` methods
    - `MenuCategoryBloc` manages optimistic delete state (category stays visible with delete disabled while request in flight)
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10_
  - [x] 13.2 Build Menu Categories screen UI
    - Display category list in display-order sequence with loading/error/retry states
    - Add/Edit category form with name (1–100 chars) and optional description; keep form open on error
    - Confirm deletion via `ConfirmationDialog`; disable delete action while request in flight; remove category on success; show error and keep on error
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10_

- [x] 14. Implement Menu Management — Items, Variants, and Modifier Groups
  - [x] 14.1 Implement `MenuRepository` (items) and `MenuItemBloc`
    - Add `getItems()`, `createItem()`, `updateItem()`, `toggleAvailability()` to `MenuRepository`
    - `MenuItemBloc` handles optimistic availability toggle; reverts on API error
    - _Requirements: 7.1, 7.2, 7.3, 7.5, 7.6, 7.7_
  - [x] 14.2 Build Menu Items screen UI
    - Display items grouped by category (alpha by category name) with name, base price, `DietaryBadge`, availability toggle
    - Optimistic toggle update within 500 ms; revert and show error on failure
    - _Requirements: 7.1, 7.6, 7.7, 7.11_
  - [x] 14.3 Build Add/Edit Item form with variant and modifier group editors
    - Required-field validation (name, category_id, base_price, dietary_type) before network call; retain form data on error
    - Variant editor: 1–20 variants, size_label (1–50 chars), price_delta (-999.99–9999.99)
    - Modifier group editor: group_name, min_select (0–20), max_select (1–20), 1–30 options each with modifier_name (1–50 chars), price_delta (0.00–9999.99); block save when max_select < min_select
    - _Requirements: 7.2, 7.3, 7.4, 7.5, 7.8, 7.9, 7.10_
  - [x] 14.4 Write property test for required field validation (Property 3 — item form)
    - **Property 3 (partial): Required Field Validation — No Network Call on Missing Input**
    - Use `fast_check` to generate partial item form inputs with any combination of required fields missing; assert field-level validation error and no HTTP call
    - Tag: `// Feature: rms-flutter-frontend, Property 3: Required field validation`
    - **Validates: Requirements 7.4**
  - [x] 14.5 Write property test for modifier group validation invariant (Property 9)
    - **Property 9: Modifier Group Validation Invariant**
    - Use `fast_check` to generate arbitrary integer pairs (min_select, max_select); assert the group is saveable iff max_select >= min_select
    - Tag: `// Feature: rms-flutter-frontend, Property 9: Modifier group validation`
    - **Validates: Requirements 7.10**
  - [x] 14.6 Write property test for state revert on API failure (Property 5 — availability toggle)
    - **Property 5 (partial): State Revert on API Failure**
    - Use `fast_check` with arbitrary toggle states and injected API error responses; assert UI reverts to prior state and non-empty error is shown
    - Tag: `// Feature: rms-flutter-frontend, Property 5: State revert on API failure`
    - **Validates: Requirements 7.7**


- [x] 15. Implement Table Management
  - [x] 15.1 Implement `TableRepository` and `TableBloc`
    - Create `TableRepository` with `getTables()`, `updateTableStatus()`, `bulkCreateTables()` methods
    - `TableBloc` refreshes Floor_View after bulk create; handles partial-refresh failure gracefully
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.7_
  - [x] 15.2 Build Floor_View widget
    - Render each table as a colour-coded tile (green/red/yellow/grey per Table_Status)
    - Support pinch-to-zoom (0.5×–3.0×) and pan when > 12 tables; equal-width tiles, minimum 64×64 dp, vertical scroll for overflow
    - _Requirements: 8.1, 8.6, 17.6_
  - [x] 15.3 Build table bottom sheet and QR code display
    - Bottom sheet shows table number, status, current order reference (if any), and status-transition actions per current status
    - QR code widget encodes customer self-order URL for the selected table
    - Bulk Create Tables form: count (1–50), prefix (1–10 chars)
    - _Requirements: 8.2, 8.3, 8.5_

- [x] 16. Checkpoint — Foundation screens complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 17. Implement Order Management
  - [x] 17.1 Implement `OrderRepository` and `OrderBloc` with 30-second polling
    - Create `OrderRepository` with `getOrders(page, limit, filters)`, `createOrder()`, `updateOrderStatus()` methods
    - `OrderBloc` starts `Stream.periodic(30s)` polling while Orders screen is active
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.7, 9.8, 9.11_
  - [x] 17.2 Build Orders list screen with pagination and filters
    - Display orders with order number, type badge, status badge, total amount using `PaginatedListView`
    - Implement filter bar (order_type, Order_Status); reset to page 1 on filter change
    - Infinite scroll: load next page on bottom-scroll; show "No more orders" indicator when last page reached
    - _Requirements: 9.1, 9.2, 9.3, 9.4_
  - [x] 17.3 Write property test for pagination completeness (Property 7)
    - **Property 7: Pagination Completeness**
    - Use `fast_check` to generate arbitrary sequences of paginated response pages; assert total item count across pages equals `pagination.total` and no further requests are made after the last page
    - Tag: `// Feature: rms-flutter-frontend, Property 7: Pagination completeness`
    - **Validates: Requirements 9.1, 9.3, 9.4**
  - [x] 17.4 Build Create Order form
    - Fields: order_type, items (≥ 1), table_id (required for dine_in only)
    - On `POST /api/v1/tenant/orders` success navigate to Order Detail; on validation error display field errors without navigating
    - _Requirements: 9.5, 9.6, 9.10_
  - [x] 17.5 Build Order Detail screen
    - Display all items with variants, modifiers, quantities, per-item totals
    - Status-transition buttons call `PATCH /api/v1/tenant/orders/:id/status`; refresh order on success; show error and retain current status on failure
    - _Requirements: 9.7, 9.8, 9.9_


- [x] 18. Implement Kitchen Display System (KDS)
  - [x] 18.1 Implement `KdsRepository` and `KdsBloc` with 15-second polling
    - Create `KdsRepository` with `getStationFeed(stationId)` and `updateKdsItemStatus(orderItemId, status)` methods
    - `KdsBloc` starts `Stream.periodic(15s)` polling; merge strategy retains existing item cards until new feed arrives (prevents flicker)
    - Expose `injectFeedUpdate(List<KdsItem> items)` for future FCM upgrade
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_
  - [x] 18.2 Build KDS screen UI
    - Display item cards grouped by station: order number, item name, quantity, elapsed time since order creation
    - Start button → status `started` (badge grey→amber); Done button → status `done` (remove card)
    - On status update failure: retain previous status, show 3-second auto-dismissing error snackbar
    - On polling failure: show non-blocking warning indicator without removing existing items
    - Grid layout (≥ 2 columns per station) when screen width ≥ 600 dp; single-column list when < 600 dp
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.8, 17.4, 17.5_
  - [x] 18.3 Write property test for KDS elapsed-time overdue invariant (Property 8)
    - **Property 8: KDS Elapsed-Time Overdue Invariant**
    - Use `fast_check` to generate arbitrary elapsed durations; pump KDS item card widget and assert red border AND overdue label appear together iff elapsed > 10 minutes; neither element appears alone
    - Tag: `// Feature: rms-flutter-frontend, Property 8: KDS overdue invariant`
    - **Validates: Requirements 10.7**
  - [x] 18.4 Write property test for state revert on API failure (Property 5 — KDS status update)
    - **Property 5 (partial): State Revert on API Failure**
    - Use `fast_check` with arbitrary KDS item statuses and injected API error responses; assert item status reverts to prior value and error snackbar is shown
    - Tag: `// Feature: rms-flutter-frontend, Property 5: State revert on API failure`
    - **Validates: Requirements 10.5**


- [x] 19. Implement Billing and POS
  - [x] 19.1 Implement `BillingRepository` and `BillingBloc`
    - Create `BillingRepository` with `generateBill(orderId)`, `recordPayment(billId, mode, amount)`, `splitBill(billId, diners)`, `voidBill(billId, reason)` methods
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.7, 11.9, 11.10, 11.11_
  - [x] 19.2 Build Billing/POS screen and bill display
    - Generate bill via `POST /api/v1/tenant/billing/bills`; display subtotal, GST breakdown by slab (one line per distinct slab), total
    - Payment form: select mode (cash/UPI/card), enter amount; show change-due amount when cash > total before confirmation
    - Validate payment amount ≥ outstanding total (no split in progress) before submitting
    - Void bill flow: require void reason, confirm via `ConfirmationDialog`, call void endpoint
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.10, 11.11, 11.13_
  - [x] 19.3 Write property test for payment underpayment rejection (Property 11)
    - **Property 11: Payment Underpayment Rejection**
    - Use `fast_check` to generate arbitrary (payment amount, bill total) pairs where amount < total; assert validation error appears and no HTTP call is made
    - Tag: `// Feature: rms-flutter-frontend, Property 11: Payment underpayment`
    - **Validates: Requirements 11.6**
  - [x] 19.4 Build Split Bill and Print Bill flows
    - Split Bill: require diners ≥ 2; validate sum of sub-bill parts equals original total before submission; display each sub-bill with subtotal and GST breakdown on success
    - Print Bill: render `Print_Payload` JSON into formatted receipt widget; trigger device print dialog via `printing` package
    - _Requirements: 11.7, 11.8, 11.9, 11.12_
  - [x] 19.5 Write property test for bill split total invariant (Property 10)
    - **Property 10: Bill Split Total Invariant**
    - Use `fast_check` to generate arbitrary bill totals and split configurations; assert configurations whose parts do not sum to original total are rejected with validation error before submission
    - Tag: `// Feature: rms-flutter-frontend, Property 10: Bill split total`
    - **Validates: Requirements 11.8**


- [x] 20. Implement Staff Management
  - [x] 20.1 Implement `StaffRepository` and `StaffBloc`
    - Create `StaffRepository` with `getStaff()`, `inviteStaff(email, role)`, `updateStaffRole(id, role)`, `deactivateStaff(id)`, `getShifts()`, `saveShift()` methods
    - _Requirements: 12.1, 12.2, 12.3, 12.6, 12.7, 12.10_
  - [x] 20.2 Build Staff Management screen UI
    - Display staff list with name, email, Role badge, active/inactive status; loading/error/retry states
    - Invite Staff form with email validation before network call; show confirmation message on success without navigating
    - Edit Role action calls `PATCH /api/v1/tenant/staff/:id`; refresh list on success
    - Deactivate action calls `POST /api/v1/tenant/staff/:id/deactivate`; reflect inactive status on success; show error on failure without status change
    - Hide Invite, Edit Role, Deactivate controls for non-owner/manager roles
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7, 12.8, 12.9_
  - [x] 20.3 Write property test for required field validation (Property 3 — staff invite email)
    - **Property 3 (partial): Required Field Validation — No Network Call on Missing Input**
    - Use `fast_check` to generate invalid email formats and blank email values; assert validation error appears and no HTTP call is made
    - Tag: `// Feature: rms-flutter-frontend, Property 3: Required field validation`
    - **Validates: Requirements 12.4**
  - [x] 20.4 Build Shift Scheduling view
    - Weekly calendar grid displaying shifts; allow adding and editing shift entries via `GET`, `POST`/`PATCH` on `/api/v1/tenant/staff/shifts`
    - _Requirements: 12.10_

- [x] 21. Implement Inventory Management
  - [x] 21.1 Implement `InventoryRepository` and `InventoryBloc`
    - Create `InventoryRepository` with `getIngredients()`, `adjustStock(id, quantity, reason)`, `createRecipeLink(ingredientId, menuItemId, qtyPerServing)` methods
    - _Requirements: 13.1, 13.2, 13.4, 13.7_
  - [x] 21.2 Build Inventory screen UI
    - Display ingredients with name, unit, stock level; loading/error/retry states
    - Sort: below-threshold ingredients (amber triangle badge) appear before at-or-above-threshold ingredients
    - Stock Adjustment form: ingredient, non-zero numeric quantity, reason; validate before network call
    - Recipe Link form: ingredient ID, menu item ID, quantity per serving; confirm link on success
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7, 13.8_
  - [x] 21.3 Write property test for low-stock ordering invariant (Property 12)
    - **Property 12: Low-Stock Ordering Invariant**
    - Use `fast_check` to generate arbitrary lists of ingredients with varying stock/threshold values; assert every below-threshold ingredient appears before every at-or-above-threshold ingredient in the rendered list
    - Tag: `// Feature: rms-flutter-frontend, Property 12: Low-stock ordering`
    - **Validates: Requirements 13.3**
  - [x] 21.4 Write property test for required field validation (Property 3 — adjustment quantity)
    - **Property 3 (partial): Required Field Validation — No Network Call on Missing Input**
    - Use `fast_check` to generate zero values and non-numeric strings for adjustment quantity; assert validation error appears and no HTTP call is made
    - Tag: `// Feature: rms-flutter-frontend, Property 3: Required field validation`
    - **Validates: Requirements 13.5**


- [x] 22. Implement Reports
  - [x] 22.1 Implement `ReportsRepository` and `ReportsBloc`
    - Create `ReportsRepository` with `getSalesReport(dateFrom, dateTo)`, `getTopItemsReport(...)`, `getRevenueByTypeReport(...)`, `getStaffPerformanceReport(...)`, `getGstSummaryReport(...)` methods
    - Default date range: first day of current calendar month to current date
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6_
  - [x] 22.2 Build Reports screen UI
    - Date-range picker defaulting to current month; loading indicator during endpoint calls
    - Sales Report: bar chart (`fl_chart`) + data table with daily totals
    - Top Items Report: ranked list with item name, quantity, revenue contribution (top 10)
    - Revenue by Type Report: pie chart (`fl_chart`) split by order type
    - Staff Performance Report: table sorted descending by orders handled
    - GST Summary Report: grouped by distinct GST rate slab with taxable value, GST collected, net total
    - Show "No data for selected range" message (hide chart and data table) when response is empty
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 14.7, 14.8_

- [x] 23. Implement Settings
  - [x] 23.1 Implement `SettingsRepository` and `SettingsBloc`
    - Create `SettingsRepository` with `getRestaurant(id)`, `updateRestaurant(id, payload)` methods
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_
  - [x] 23.2 Build Settings screen UI
    - Load and populate restaurant profile form (name, address, phone, GST number, logo CDN_URL)
    - Business hours form (open/close HH:MM per day-of-week)
    - Submit both via `PATCH /api/v1/restaurants/:id`; show success confirmation; highlight offending fields with server errors on validation failure
    - Grant manager privileges to staff: calls `PATCH /api/v1/tenant/staff/:id` with role `manager`; refresh staff list
    - Route guard: redirect non-owner/manager roles to Dashboard (enforced in GoRouter)
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.7, 15.8_

- [x] 24. Final checkpoint — All screens integrated
  - Ensure all tests pass, ask the user if questions arise.


---

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP delivery
- All 15 design correctness properties are covered by property-based test sub-tasks
- Properties 3 and 5 each appear in multiple sub-tasks targeting different screens; all instances share the same property tag
- Checkpoints at tasks 7, 16, and 24 act as quality gates
- `build_runner` must be re-run whenever freezed models change
- The `fast_check` PBT library must be configured with `iterations: 100` minimum per test
- Each PBT sub-task includes a tag comment in format `// Feature: rms-flutter-frontend, Property N: <text>`
- The customer_app stub (task 2) should be completed early to validate the monorepo dependency isolation
- GoRouter is wired to `AuthBloc.stream` as a `refreshListenable` so guards re-evaluate automatically on auth state changes

---

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["2.1"] },
    { "id": 1, "tasks": ["3.1"] },
    { "id": 2, "tasks": ["3.2"] },
    { "id": 3, "tasks": ["3.3", "4.1"] },
    { "id": 4, "tasks": ["4.2", "4.3"] },
    { "id": 5, "tasks": ["4.4", "5.1", "6.1"] },
    { "id": 6, "tasks": ["5.2", "6.2"] },
    { "id": 7, "tasks": ["6.3", "6.4"] },
    { "id": 8, "tasks": ["6.5", "8.1"] },
    { "id": 9, "tasks": ["8.2"] },
    { "id": 10, "tasks": ["8.3", "8.4", "9.1", "10.1", "11.1"] },
    { "id": 11, "tasks": ["8.5", "9.2", "9.3", "10.2", "11.2", "12.1"] },
    { "id": 12, "tasks": ["9.4", "11.3", "12.2", "13.1", "14.1"] },
    { "id": 13, "tasks": ["13.2", "14.2", "15.1", "17.1", "18.1", "19.1", "20.1", "21.1", "22.1", "23.1"] },
    { "id": 14, "tasks": ["14.3", "14.4", "15.2", "17.2", "18.2", "19.2", "20.2", "21.2", "22.2", "23.2"] },
    { "id": 15, "tasks": ["14.5", "14.6", "15.3", "17.3", "18.3", "18.4", "19.3", "19.4", "20.3", "20.4", "21.3", "21.4"] },
    { "id": 16, "tasks": ["17.4", "17.5", "19.5"] }
  ]
}
```
