# Requirements Document

## Introduction

This document defines the requirements for the **Staff/Owner Management Portal** — the first app within a multi-tenant SaaS Restaurant Management System (RMS) Flutter monorepo. The portal targets restaurant owners, managers, and operational staff (waiters, chefs, cashiers) and runs on mobile (portrait), tablet (landscape), and web (responsive). It communicates with an existing Node.js/Express backend via REST over HTTP, a two-phase JWT authentication scheme, and polling-based real-time updates for the Kitchen Display System. A Customer Self-Ordering App will be co-located in the same Flutter project and built in a subsequent phase.

---

## Glossary

- **App**: The Staff/Owner Management Portal Flutter application.
- **Auth_Service**: The module responsible for authentication flows, JWT storage, and session management.
- **Tenant_JWT**: A JSON Web Token returned by `POST /api/v1/restaurants/:id/select` that carries a `restaurant_id` claim and scopes all subsequent API requests to a single tenant.
- **Base_JWT**: The initial JSON Web Token returned on successful login, used only to list accessible restaurants and obtain a Tenant_JWT.
- **Router**: The Flutter navigation layer (GoRouter) that controls screen transitions and guards protected routes.
- **BLoC**: Business Logic Component — the state management pattern used throughout the App.
- **API_Client**: The HTTP layer (Dio) that attaches Authorization headers, handles token refresh, and maps error responses.
- **KDS**: Kitchen Display System — the station-facing view that shows order items and their preparation lifecycle.
- **POS**: Point of Sale — the cashier-facing billing and payment interface.
- **Razorpay**: The third-party payment gateway used for subscription activation.
- **Floor_View**: The visual table-map widget showing table statuses on a restaurant floor plan.
- **Print_Payload**: A structured JSON object returned by the bill endpoint used to render a printable invoice entirely on the client.
- **GST**: Goods and Services Tax — Indian indirect tax applied to menu items at item-level rates.
- **Role**: One of `owner`, `manager`, `waiter`, `chef`, `cashier`, `delivery_staff` — embedded in the Tenant_JWT and used to control UI visibility.
- **Dietary_Type**: One of `veg`, `non_veg`, `vegan`, `egg` — a property of a menu item.
- **Order_Status**: One of `pending` → `confirmed` → `preparing` → `ready` → `served` → `completed`.
- **Table_Status**: One of `available`, `occupied`, `reserved`, `cleaning`.
- **KDS_Item_Status**: One of `queued` → `started` → `done`.
- **Subscription_Plan**: A billing tier selected during restaurant onboarding.
- **CDN_URL**: An externally hosted image URL stored as a string on a menu item — no file upload is performed by the App.

---

## Requirements

### Requirement 1: Project Structure and Monorepo Organisation

**User Story:** As a developer, I want the Flutter project organised as a monorepo with clearly separated apps and shared packages, so that the Staff Portal and the future Customer App share code without coupling their entry points.

#### Acceptance Criteria

1. THE App SHALL provide a root directory with sub-packages: `apps/staff_portal`, `apps/customer_app` (stub), `packages/core_ui`, `packages/api_client`, `packages/auth`, `packages/models` — each sub-package having its own `pubspec.yaml` with a declared package name.
2. THE root `pubspec.yaml` SHALL include `path:` dependency entries for every package under `apps/` and `packages/`.
3. WHEN a developer runs `flutter run -t apps/staff_portal/lib/main.dart`, THE App SHALL launch the Staff Portal such that the resolved dependency graph contains no path reference to `apps/customer_app`.
4. THE `apps/customer_app` stub SHALL be a valid Flutter application with a `main.dart` entry point that compiles without errors.
5. THE `packages/models` package SHALL define at minimum the following domain models: `MenuItem`, `Order`, `Bill`, `Table`, `Staff`, `KdsItem`, `Subscription` — each implementing `fromJson`/`toJson` such that `fromJson(instance.toJson())` returns an equal instance, using `freezed` for immutability and `json_serializable` for JSON mapping.
6. THE `packages/api_client` package SHALL expose a single `ApiClient` class backed by Dio that attaches an `Authorization: Bearer <token>` header to every authenticated request and throws a typed `ApiException` containing HTTP status code and a human-readable message on error responses.

---

### Requirement 2: Authentication — Register, Login, Change Password

**User Story:** As a restaurant owner or staff member, I want to register and log in securely, so that I can access the portal with my credentials protected.

#### Acceptance Criteria

1. WHEN a new user submits a registration form with name, valid email, and a password of at least 8 characters, THE Auth_Service SHALL call `POST /api/v1/auth/register` and on success navigate to the Login screen.
2. WHEN a user submits the login form with valid credentials, THE Auth_Service SHALL call `POST /api/v1/auth/login`, store the returned Base_JWT in secure storage, and navigate to the Restaurant Selector screen.
3. IF `POST /api/v1/auth/login` returns HTTP 401, THEN THE Auth_Service SHALL display an inline error message indicating invalid credentials without clearing the email field.
4. WHEN a logged-in user submits the Change Password form with the correct current password and a new password of at least 8 characters, THE Auth_Service SHALL call `POST /api/v1/auth/change-password` and on success display a confirmation message.
5. IF the Change Password form is submitted with an incorrect current password, THEN THE App SHALL display an inline error message on the current password field without navigating away.
6. IF the new password is fewer than 8 characters, THEN THE App SHALL display a validation error on the new password field before making any network call.
7. THE Auth_Service SHALL store the Base_JWT and Tenant_JWT using `flutter_secure_storage` so that tokens survive app restarts but are inaccessible to other apps.
8. WHEN the App launches and a Tenant_JWT whose expiry timestamp has not yet passed is found in secure storage, THE Router SHALL navigate directly to the Dashboard screen.
9. WHEN the App launches and no Tenant_JWT is found, or the stored Tenant_JWT is expired, THE Router SHALL navigate to the Login screen.

---

### Requirement 3: Restaurant Selector

**User Story:** As a user with access to multiple restaurants, I want to select which restaurant I am working in, so that all subsequent actions are scoped to that tenant.

#### Acceptance Criteria

1. WHEN the Restaurant Selector screen loads, THE App SHALL call `GET /api/v1/restaurants` using the Base_JWT and display the list of accessible restaurants.
2. IF `GET /api/v1/restaurants` returns an error, THEN THE App SHALL display an error message and a retry button on the Restaurant Selector screen.
3. WHEN a user selects a restaurant and `POST /api/v1/restaurants/:id/select` succeeds, THE Auth_Service SHALL store the returned Tenant_JWT in secure storage and navigate to the Dashboard screen.
4. IF `POST /api/v1/restaurants/:id/select` succeeds but storing the returned Tenant_JWT fails, THEN THE Auth_Service SHALL display an error message and remain on the Restaurant Selector screen.
5. IF `GET /api/v1/restaurants` returns an empty list, THEN THE App SHALL display a prompt to create a new restaurant; WHEN the user taps that prompt, THE Router SHALL navigate to the Onboarding flow.
6. WHILE the restaurant list is loading, THE App SHALL display a loading indicator.
7. THE API_Client SHALL attach the Tenant_JWT as the `Authorization: Bearer` header for all requests made after restaurant selection.

---

### Requirement 4: Onboarding and Subscription

**User Story:** As a new restaurant owner, I want to register my restaurant, choose a subscription plan, and complete payment, so that my restaurant is activated on the platform.

#### Acceptance Criteria

1. WHEN a user submits the Create Restaurant form with name, address, and GST number, THE App SHALL call `POST /api/v1/restaurants` and on success advance to the Plan Selection step.
2. IF `POST /api/v1/restaurants` returns an error, THEN THE App SHALL display the error message on the Create Restaurant form without advancing to the next step.
3. IF the Create Restaurant form is submitted with any required field (name, address, GST number) missing, THEN THE App SHALL display a validation error beside the missing field without making a network call.
4. WHEN a user selects a Subscription_Plan on the Plan Selection step, THE App SHALL create a subscription and initiate payment, then launch the Razorpay payment sheet via the `razorpay_flutter` plugin.
5. WHEN the Razorpay payment sheet reports success with a payment ID, THE App SHALL call the payment verification endpoint and on success navigate to the Dashboard.
6. IF the payment verification call fails, THEN THE App SHALL remain on the Plan Selection step and display an error message indicating payment could not be confirmed.
7. IF the Razorpay payment sheet reports failure or is dismissed, THEN THE App SHALL remain on the Plan Selection step and display an error message without advancing.
8. THE onboarding flow SHALL be a multi-step wizard (restaurant details → plan selection → payment → confirmation) with a step indicator visible at all times.
9. WHERE a restaurant already has an active subscription, THE App SHALL skip the onboarding flow and route directly to the Dashboard.

---

### Requirement 5: Dashboard

**User Story:** As an owner or manager, I want a dashboard that shows today's key metrics at a glance, so that I can monitor restaurant performance without drilling into sub-sections.

#### Acceptance Criteria

1. WHEN the Dashboard screen loads, THE App SHALL call the summary statistics endpoint and display today's total orders, total revenue, and table occupancy count.
2. WHEN the Dashboard screen loads, THE App SHALL display a list of orders with Order_Status values of `pending`, `confirmed`, `preparing`, `ready`, or `served`, sorted by creation time with the newest first.
3. WHEN a user taps an order in the Dashboard order list and the summary statistics error card is not currently displayed, THE Router SHALL navigate to the Order Detail screen for that order.
4. WHILE dashboard data is loading, THE App SHALL display skeleton loading placeholders for each metric card and SHALL replace all skeletons only after all data has finished loading.
5. IF the summary statistics endpoint returns an error, THEN THE App SHALL display an error card with a retry button that re-fetches both the summary statistics and the active orders list.
6. IF the active orders endpoint returns an error, THEN THE App SHALL display an error message in the orders list area with a retry button.
7. WHILE the Dashboard screen is active, THE App SHALL re-fetch both summary statistics and the active orders list every 60 seconds.

---

### Requirement 6: Menu Management — Categories

**User Story:** As an owner or manager, I want to create, edit, and delete menu categories, so that my menu is logically organised for staff and customers.

#### Acceptance Criteria

1. WHEN the Menu Categories screen loads, THE App SHALL call `GET /api/v1/menu/categories` and display all categories in display-order sequence.
2. IF `GET /api/v1/menu/categories` returns an error, THEN THE App SHALL display an error message and a retry button.
3. WHEN a user submits the Add Category form with a name (1–100 characters) and optional description, THE App SHALL call `POST /api/v1/menu/categories` and add the new category to the list on success.
4. IF `POST /api/v1/menu/categories` returns an error, THEN THE App SHALL display the error message and keep the form open.
5. WHEN a user submits edits to an existing category, THE App SHALL call `PATCH /api/v1/menu/categories/:id` and update the displayed category on success.
6. IF `PATCH /api/v1/menu/categories/:id` returns an error, THEN THE App SHALL display the error message and keep the edit form open.
7. WHEN a user confirms deletion of a category and `DELETE /api/v1/menu/categories/:id` succeeds, THE App SHALL remove the category from the list.
8. WHILE a delete request is in flight, THE App SHALL keep the category in the list and disable the delete action for that category.
9. IF `DELETE /api/v1/menu/categories/:id` returns an error, THEN THE App SHALL display the server error message and keep the category in the list.
10. THE App SHALL require the user to confirm deletion with an alert dialog before calling the delete endpoint.

---

### Requirement 7: Menu Management — Items, Variants, and Modifier Groups

**User Story:** As an owner or manager, I want to create and manage menu items with their variants and modifier groups, so that complex menus with options are accurately represented.

#### Acceptance Criteria

1. WHEN the Menu Items screen loads, THE App SHALL call `GET /api/v1/menu/items` and display items grouped by category in alphabetical order by category name, each showing name, base price, Dietary_Type badge, and availability toggle.
2. WHEN a user submits the Add Item form, THE App SHALL validate that name, category_id, base_price, and dietary_type are present, then call `POST /api/v1/menu/items` with the full item payload (name, category_id, base_price, gst_rate, dietary_type, description, CDN_URL, is_available).
3. WHEN a user submits the Edit Item form, THE App SHALL validate that name, category_id, base_price, and dietary_type are present, then call `PATCH /api/v1/menu/items/:id` with the updated item payload.
4. IF the Add or Edit Item form is submitted with a required field (name, category_id, base_price, or dietary_type) missing, THEN THE App SHALL display a validation error beside the missing field without making a network call.
5. IF the Add or Edit Item API call returns an error, THEN THE App SHALL retain all entered form data and display the error message without navigating away.
6. WHEN a user toggles the availability switch on a menu item, THE App SHALL call `PATCH /api/v1/menu/items/:id` with the updated `is_available` value within 500 ms and reflect the new state in the UI optimistically.
7. IF the availability toggle API call returns an error, THEN THE App SHALL revert the toggle to its previous state and display an error message.
8. WHEN a user adds variants to an item, THE App SHALL allow between 1 and 20 variants each with a size_label (1–50 characters) and a price_delta between -999.99 and 9999.99, and include the variants array in the create or update payload.
9. WHEN a user configures a modifier group on an item, THE App SHALL require a group_name, a min_select value between 0 and 20, a max_select value between 1 and 20, and between 1 and 30 modifier options each with a modifier_name (1–50 characters) and price_delta between 0.00 and 9999.99.
10. IF a modifier group's max_select value is less than its min_select value, THEN THE App SHALL display a validation error and prevent saving the modifier group.
11. THE App SHALL display a dietary badge beside each menu item: `veg` as a green filled circle, `non_veg` as a brown filled circle, `vegan` as a green leaf icon, and `egg` as a yellow filled circle, consistent with FSSAI iconography conventions.

---

### Requirement 8: Table Management

**User Story:** As an owner or manager, I want to view and manage restaurant tables on a visual floor map, so that I can track occupancy and configure the table layout.

#### Acceptance Criteria

1. WHEN the Table Management screen loads, THE App SHALL call `GET /api/v1/tables` and render each table as a colour-coded tile in the Floor_View: green (`available`), red (`occupied`), yellow (`reserved`), grey (`cleaning`).
2. WHEN a user taps a table tile, THE App SHALL display a bottom sheet showing the table number, current Table_Status, current order reference (if any), and the following status-transition actions based on current status: `available` → Mark Occupied, Mark Reserved; `occupied` → Mark Cleaning, Mark Available; `reserved` → Mark Available, Mark Occupied; `cleaning` → Mark Available.
3. WHEN a manager submits the Bulk Create Tables form with a count between 1 and 50 and a prefix of 1–10 characters, THE App SHALL call `POST /api/v1/tenant/tables/bulk` and refresh the Floor_View on success.
4. IF the subsequent `GET /api/v1/tables` call after bulk create fails, THE App SHALL still display any previously loaded tables and show a refresh error indicator.
5. WHEN a user requests the QR code for a table, THE App SHALL display a QR code widget encoding the customer self-order URL for that table.
6. WHILE the Floor_View contains more than 12 tables, THE App SHALL support pinch-to-zoom gestures scaling between 0.5× and 3.0× and pan gestures.
7. IF `GET /api/v1/tables` returns an error, THEN THE App SHALL display an error message and a retry button.

---

### Requirement 9: Order Management

**User Story:** As a waiter or manager, I want to view, create, and manage orders with full lifecycle control, so that kitchen and service operations stay coordinated.

#### Acceptance Criteria

1. WHEN the Orders screen loads, THE App SHALL call `GET /api/v1/tenant/orders` with default pagination (`?page=1&limit=20`) and display orders in a list with order number, type badge, status badge, and total amount.
2. WHEN a user applies a filter (by order_type or Order_Status), THE App SHALL reset to page 1, append the filter parameters to the request, and re-render the list.
3. WHEN the user scrolls to the bottom of the order list and more pages are available, THE App SHALL request the next page and append the results to the existing list.
4. WHEN the user scrolls to the bottom of the order list and no more pages are available, THE App SHALL display a "No more orders" indicator and make no further requests.
5. WHEN a user submits the Create Order form with order_type, at least one item, and (for `dine_in`) a table_id, THE App SHALL call `POST /api/v1/tenant/orders` and navigate to the Order Detail screen on success.
6. WHEN the order_type is `takeaway` or `delivery`, THE App SHALL not require a table_id and SHALL not display a validation error for a missing table_id.
7. WHEN a user taps a status-transition button on the Order Detail screen, THE App SHALL call `PATCH /api/v1/tenant/orders/:id/status` and refresh the displayed order on success.
8. IF the status-transition call returns an error, THEN THE App SHALL display the server error message and retain the order's current status.
9. THE Order Detail screen SHALL display all order items with their selected variants and modifiers, quantities, and per-item totals.
10. IF `POST /api/v1/tenant/orders` returns a validation error, THEN THE App SHALL display an error message indicating which fields are invalid without navigating away.
11. WHILE the Orders screen is active, THE App SHALL re-fetch the order list every 30 seconds.

---

### Requirement 10: Kitchen Display System (KDS)

**User Story:** As a chef, I want a dedicated kitchen view that shows incoming order items grouped by station, so that I can track and update preparation progress without missing orders.

#### Acceptance Criteria

1. WHEN the KDS screen loads, THE App SHALL call `GET /api/v1/tenant/kds/stations/:id/feed` for each available station and display active order items grouped by KDS station, each card showing order number, item name, quantity, and elapsed time since the order was placed.
2. WHILE the KDS screen is active, THE KDS_BLoC SHALL re-fetch the station feed every 15 seconds; during each merge, existing item cards SHALL remain visible and in their current position until the response arrives.
3. WHEN a chef taps "Start" on a queued item, THE App SHALL call `PATCH /api/v1/tenant/kds/items/:orderItemId/status` with status `started` and transition the item's badge from grey (`queued`) to amber (`started`).
4. WHEN a chef taps "Done" on a started item, THE App SHALL call `PATCH /api/v1/tenant/kds/items/:orderItemId/status` with status `done` and remove the item card from the active list.
5. IF a KDS_Item_Status update request fails, THEN THE App SHALL retain the item's previous status and display an error snackbar that auto-dismisses after 3 seconds.
6. IF the polling request fails, THEN THE App SHALL display a non-blocking warning indicator (e.g., a banner or icon) without removing existing items from the display.
7. IF an item's elapsed time exceeds 10 minutes, THEN THE App SHALL display a red border around that item card AND an overdue label on that same card; both elements SHALL appear together whenever the condition is true.
8. WHERE the device screen width is at or above 600 dp, THE App SHALL display KDS items in a grid with at least 2 columns per station.

---

### Requirement 11: Billing and POS

**User Story:** As a cashier, I want to generate bills, record payments in multiple modes, split bills, and void bills, so that every transaction is accurately captured.

#### Acceptance Criteria

1. WHEN a cashier selects an order and taps "Generate Bill", THE App SHALL call `POST /api/v1/tenant/billing/bills` with the order ID and display the returned Bill showing subtotal, GST breakdown by slab, and total.
2. IF the Generate Bill call returns an error, THEN THE App SHALL display the error message without navigating away.
3. WHEN a cashier selects a payment mode (cash, UPI, or card) and submits a payment amount equal to or greater than the outstanding Bill total, THE App SHALL call `POST /api/v1/tenant/billing/bills/:id/payments` and update the Bill status to "Paid" on success.
4. IF the payment submission call returns an error, THEN THE App SHALL display the error message and keep the payment form open.
5. WHEN a cashier selects cash as payment mode and enters an amount greater than the Bill total, THE App SHALL display the change-due amount before the cashier confirms the payment.
6. IF the payment amount entered is less than the Bill total and no split is in progress, THEN THE App SHALL display a validation error and prevent the payment request from being submitted.
7. WHEN a cashier initiates a Split Bill, THE App SHALL require the number of diners (minimum 2) before calling `POST /api/v1/tenant/billing/bills/:id/split`.
8. IF the split configuration results in a sum that does not equal the Bill total, THEN THE App SHALL display a validation error and prevent submission.
9. WHEN the split call succeeds, THE App SHALL display each resulting sub-bill with its own subtotal and GST breakdown.
10. WHEN a cashier enters a void reason and confirms, THE App SHALL call `POST /api/v1/tenant/billing/bills/:id/void` and update the Bill status to "Voided" on success.
11. IF the void call returns an error, THEN THE App SHALL display the error message and keep the Bill status unchanged.
12. WHEN a cashier taps "Print Bill", THE App SHALL render the Print_Payload JSON into a formatted receipt widget and trigger the device print dialog via the `printing` package.
13. THE Bill screen SHALL display one GST breakdown line for each distinct GST rate slab present in the order's line items.

---

### Requirement 12: Staff Management

**User Story:** As an owner or manager, I want to invite staff members, assign roles, and manage their accounts, so that every team member has appropriate access.

#### Acceptance Criteria

1. WHEN the Staff Management screen loads, THE App SHALL call `GET /api/v1/tenant/staff` and display all staff members with their name, email, Role badge, and active/inactive status.
2. IF `GET /api/v1/tenant/staff` returns an error, THEN THE App SHALL display an error message and a retry button.
3. WHEN an owner or manager submits the Invite Staff form with a valid email address and a Role value from (`waiter`, `chef`, `cashier`, `delivery_staff`), THE App SHALL call `POST /api/v1/tenant/staff/invite` and display a confirmation message on the same screen without navigating away.
4. IF the Invite Staff form is submitted with an invalid email format, THEN THE App SHALL display a validation error on the email field before making any network call.
5. IF `POST /api/v1/tenant/staff/invite` returns an error, THEN THE App SHALL display the server error message without navigating away.
6. WHEN an owner or manager edits a staff member's Role, THE App SHALL call `PATCH /api/v1/tenant/staff/:id` with the updated role and refresh the staff list on success.
7. WHEN an owner or manager deactivates a staff member, THE App SHALL call `POST /api/v1/tenant/staff/:id/deactivate` and reflect the inactive status in the list on success.
8. IF the deactivation call returns an error, THEN THE App SHALL display the error message and keep the staff member's status unchanged.
9. IF a user whose Tenant_JWT Role is not `owner` or `manager` attempts to access the Invite Staff, Edit Role, or Deactivate actions, THEN THE App SHALL hide those controls.
10. WHEN an owner or manager opens the Shift Scheduling view, THE App SHALL call `GET /api/v1/tenant/staff/shifts`, display shifts in a weekly calendar grid, and allow adding or editing shift entries.

---

### Requirement 13: Inventory Management

**User Story:** As an owner or manager, I want to track ingredient stock levels, receive low-stock alerts, record adjustments, and link ingredients to recipes, so that kitchen supply is always visible.

#### Acceptance Criteria

1. WHEN the Inventory screen loads, THE App SHALL call `GET /api/v1/tenant/inventory/ingredients` and display all ingredients with name, unit, and current stock level.
2. IF `GET /api/v1/tenant/inventory/ingredients` returns an error, THEN THE App SHALL display an error message and a retry button.
3. IF an ingredient's current stock level is below its reorder threshold, THEN THE App SHALL display a low-stock warning badge (amber triangle icon) beside that ingredient and position it at the top of the list above all ingredients that are not below threshold.
4. WHEN a manager submits a Stock Adjustment form with an ingredient, a non-zero numeric adjustment quantity, and a reason, THE App SHALL call `POST /api/v1/tenant/inventory/ingredients/:id/adjustments` and update the displayed stock level on success.
5. IF the stock adjustment quantity field is zero or contains a non-numeric value, THEN THE App SHALL display a validation error before making any network call.
6. IF the Stock Adjustment API call returns an error, THEN THE App SHALL display the error message and keep the form open.
7. WHEN a manager links an ingredient to a menu item recipe with an ingredient ID, menu item ID, and quantity per serving, THE App SHALL call `POST /api/v1/tenant/inventory/recipe-links` and confirm the link on success.
8. IF the recipe-link call returns an error, THEN THE App SHALL display the error message without navigating away.

---

### Requirement 14: Reports

**User Story:** As an owner or manager, I want to view sales, item performance, revenue, staff performance, and GST reports with date-range filters, so that I can make informed business decisions.

#### Acceptance Criteria

1. WHEN a user selects the Sales Report with a date range, THE App SHALL call `GET /api/v1/tenant/reports/sales` with `date_from` and `date_to` query parameters and display daily totals in a bar chart and a data table.
2. WHEN a user selects the Top Items Report with a date range, THE App SHALL call `GET /api/v1/tenant/reports/top-items` with `date_from` and `date_to` query parameters and display the top 10 items by quantity sold in a ranked list with item name, quantity, and revenue contribution.
3. WHEN a user selects the Revenue by Type Report with a date range, THE App SHALL call `GET /api/v1/tenant/reports/revenue-by-type` and display a pie chart split by order type (`dine_in`, `takeaway`, `delivery`).
4. WHEN a user selects the Staff Performance Report with a date range, THE App SHALL call `GET /api/v1/tenant/reports/staff-performance` and display each staff member's orders handled and total revenue, sorted descending by orders handled.
5. WHEN a user selects the GST Summary Report with a date range, THE App SHALL call `GET /api/v1/tenant/reports/gst-summary` and display taxable value, GST collected, and net total grouped by each distinct GST rate slab present in the response.
6. THE Reports screen SHALL default to a date range of the first day of the current calendar month to the current date on first load.
7. IF a report endpoint returns an empty data set, THEN THE App SHALL hide both the chart widget and the data table and display a "No data for selected range" message in their place.
8. WHILE any report endpoint call is in progress, THE App SHALL display a loading indicator in the report content area.

---

### Requirement 15: Settings

**User Story:** As an owner, I want to update the restaurant profile, configure business hours, and manage additional managers, so that the platform reflects accurate operational information.

#### Acceptance Criteria

1. WHEN the Settings screen loads, THE App SHALL call `GET /api/v1/restaurants/:id` and populate the restaurant profile form with name, address, phone, GST number, and logo CDN_URL.
2. WHEN an owner submits updated restaurant profile details, THE App SHALL call `PATCH /api/v1/restaurants/:id` and display a success confirmation on completion.
3. IF `PATCH /api/v1/restaurants/:id` returns a validation error, THEN THE App SHALL highlight the offending form fields and display the server error messages without navigating away.
4. WHEN an owner submits business hours (open/close time in HH:MM 24-hour format per day of week), THE App SHALL call `PATCH /api/v1/restaurants/:id` with the business hours payload and display a success confirmation on completion.
5. IF the business hours save call returns an error, THEN THE App SHALL display the error message and keep the business hours form open.
6. WHEN an owner grants manager privileges to a staff member, THE App SHALL call `PATCH /api/v1/tenant/staff/:id` with role `manager` and refresh the staff list on success.
7. IF the manager role grant call returns an error, THEN THE App SHALL display the error message without navigating away.
8. IF a user whose Tenant_JWT Role is not `owner` or `manager` attempts to access the Settings screen via any navigation path, THEN THE Router SHALL redirect to the Dashboard screen.

---

### Requirement 16: Role-Based UI Visibility

**User Story:** As a platform operator, I want UI elements and screens to be shown or hidden based on the user's role, so that staff see only what is relevant to their function.

#### Acceptance Criteria

1. WHEN a user completes restaurant selection and the Tenant_JWT is stored, THE App SHALL extract the Role claim from the Tenant_JWT and store it in the Auth_BLoC state.
2. IF the Tenant_JWT contains no Role claim or an unrecognised Role value, THEN THE App SHALL display an error message and redirect the user to the Login screen.
3. WHILE a user with Role `waiter` is authenticated, THE App SHALL show Orders and Tables navigation items and hide Menu Management, Staff Management, Inventory, Reports, KDS, Billing/POS, and Settings navigation items.
4. WHILE a user with Role `chef` is authenticated, THE App SHALL show the KDS navigation item and hide all other navigation items except Dashboard.
5. WHILE a user with Role `cashier` is authenticated, THE App SHALL show Billing/POS and Orders navigation items and hide Menu Management, Staff Management, Inventory, Reports, KDS, and Settings navigation items.
6. WHILE a user with Role `owner` or `manager` is authenticated, THE App SHALL show all navigation items.
7. IF a user attempts to navigate directly to a restricted route via deep link or URL, THEN THE Router SHALL block the navigation and redirect to the Dashboard screen.
8. IF a navigation attempt to a restricted route is blocked, THEN THE App SHALL display an "Access Denied" message to the user.

---

### Requirement 17: Responsive Layout and Adaptive UI

**User Story:** As a staff member using a phone, tablet, or browser, I want the interface to adapt its layout appropriately, so that each device provides an optimal experience.

#### Acceptance Criteria

1. WHEN the App runs on a device with a screen width below 600 dp, THE App SHALL render single-column layouts with a bottom navigation bar for primary navigation.
2. WHEN the App runs on a device with a screen width between 600 dp and 1023 dp, THE App SHALL render a persistent side navigation rail and use two-column layouts for list-detail screens.
3. WHEN the App runs on a device with a screen width at or above 1024 dp, THE App SHALL render a permanent expanded side navigation drawer and use master-detail layouts.
4. WHEN the KDS screen is rendered on a device with a screen width at or above 600 dp, THE App SHALL display KDS items in a multi-column grid layout.
5. WHEN the KDS screen is rendered on a device with a screen width below 600 dp, THE App SHALL display KDS items in a single-column list layout.
6. THE Floor_View SHALL allocate equal share of available row width to each table tile, maintaining a minimum tile size of 64 × 64 dp; WHEN the available width cannot accommodate the minimum tile size, THE Floor_View SHALL scroll vertically to show overflow tiles.
7. WHILE the device is in landscape orientation with a screen width between 600 dp and 1023 dp, THE App SHALL display the side navigation rail without requiring an app restart; WHEN the device returns to portrait orientation, THE App SHALL switch back to the bottom navigation bar without requiring an app restart.

---

### Requirement 18: Error Handling and Network Resilience

**User Story:** As any user of the App, I want clear feedback when network errors occur and a graceful recovery path, so that transient failures do not disrupt my workflow.

#### Acceptance Criteria

1. IF the API_Client receives an HTTP 401 response and a stored, unexpired refresh token is available, THEN THE API_Client SHALL call `POST /api/v1/auth/refresh`, store the new tokens, and retry the original request exactly once.
2. IF the API_Client receives an HTTP 401 response and re-authentication fails or no refresh token is available, THEN THE Auth_Service SHALL clear all stored tokens and navigate to the Login screen.
3. IF the API_Client receives an HTTP 4xx response (except 401) and the response body contains a `message` field, THEN THE App SHALL display that message as a snackbar visible for at least 4 seconds.
4. IF the API_Client receives an HTTP 4xx response (except 401) and the response body does not contain a `message` field, THEN THE App SHALL display a generic "An error occurred. Please try again." snackbar visible for at least 4 seconds.
5. IF the API_Client receives an HTTP 5xx response, THEN THE App SHALL display a "Server error, please try again" snackbar visible for at least 4 seconds.
6. IF a network request has not received a response within 30 seconds, THEN THE API_Client SHALL cancel the request and THE App SHALL display a "Request timed out" message.
7. WHEN the "Request timed out" message is displayed, THE App SHALL provide a retry action that re-submits the same request.
8. THE API_Client SHALL add an `X-Request-ID` header containing a UUID v4 value to every outgoing request.

---

### Requirement 19: Offline Awareness

**User Story:** As a staff member in a restaurant with intermittent connectivity, I want the App to inform me when I am offline, so that I understand why actions are unavailable.

#### Acceptance Criteria

1. WHEN the device loses network connectivity, THE App SHALL display a persistent banner at the top of every screen indicating the offline state.
2. WHILE the device has no network connectivity, THE App SHALL disable all write actions (form submissions, status transitions, toggle actions) and display a tooltip on tap of any disabled control explaining that an internet connection is required.
3. WHEN network connectivity is restored, THE App SHALL dismiss the offline banner automatically and re-enable all write actions.
4. IF a write action is attempted while the App is in the offline state, THE App SHALL display the "internet connection required" tooltip without submitting any request.

---

### Requirement 20: Accessibility

**User Story:** As a staff member with visual or motor impairments, I want the App to meet baseline accessibility standards, so that I can use the portal effectively.

#### Acceptance Criteria

1. THE App SHALL assign a non-empty descriptive semantic label, exposed to the platform accessibility API, to every interactive widget (buttons, toggles, text fields, icon buttons) so that screen readers can announce the widget's purpose.
2. THE App SHALL render all interactive controls with a minimum touch target size of 48 × 48 dp; a control is compliant only if both its width and height are at least 48 dp.
3. THE App SHALL use a colour scheme where normal-weight text (below 18 pt or 14 pt bold) has a contrast ratio of at least 4.5:1 against its background, and large text (18 pt or above, or 14 pt bold) has a contrast ratio of at least 3:1 against its background; disabled and purely decorative elements are exempt.
4. WHEN a form submission fails validation, THE App SHALL move focus to the first field with an error before any other UI update is applied so that screen reader users are informed of the error immediately.
