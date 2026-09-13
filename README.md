# Icy Strait Scooter Rentals

Native iOS 17+ SwiftUI app for renting **4-wheel offroad e-scooters** (quad-style, four knobby all-terrain tires — not 2-wheel kick scooters) at Icy Strait Point.

Open `IcyStraitScooterRentals.xcodeproj` in Xcode 15.4 or later, choose an iPhone Simulator, and run the **Icy Strait Scooter Rentals** scheme (renters) or **IcyStraitCrew** (staff phones).

Display name: **Icy Strait Scooter Rentals**  
Bundle ID: `com.icystrait.scooterrentals`

Crew display name: **Icy Strait Crew**  
Crew bundle ID: `com.icystrait.crew`

## What you rent

The official product photo lives in `Assets.xcassets/FleetHero`. The UI uses that photo on onboarding, scooter cards, empty states, and return-photo coaching. Brand colors are sampled from the vehicle: **safety orange** frame (`#FF5A00`) and **gloss black** fenders/seat/bars.

The fleet is six identical 4-wheel offroad units, distinguished by dock and name:

| ID | Name | Dock |
| --- | --- | --- |
| IS-101 | Glacier | Dock A · North lot |
| IS-102 | Humpback | Dock B · North lot |
| IS-103 | Spruce | Dock C · Lodge loop |
| IS-104 | Otter | Dock D · Waterfront |
| IS-105 | Raven | Dock E · Cannery row |
| IS-106 | Tidepool | Dock F · Point trail |

SF Symbol `scooter` is never used (that glyph is a 2-wheel kick scooter). Tabs use `qrcode.viewfinder`, `calendar`, and `list.bullet.rectangle`, plus a custom four-wheel mark.

## Season, hours, capacity

- Season: **1 May 2027 – 30 September 2027** (inclusive), Alaska time (`America/Juneau`).
- Hours: **8:00 AM – 7:00 PM**. Hourly slots are 8–9am through 6–7pm.
- Capacity: **exactly 6 rentals per hour** (one per unit). The calendar shows remaining capacity as `4/6 open`.
- Occupancy is any rental whose time range overlaps the hour. Active rentals occupy from start through “now”; completed rentals occupy start through check-in. Future hours are not reserved for an unknown remaining duration.

**Demo decision:** checkout does **not** enforce season hours by default so you can run a live meter on today’s Simulator clock. Turn on **Settings → Enforce 2027 season hours** to apply the May–September / 8am–7pm rules. The Calendar tab is always the 2027 season and is seeded with representative busy/quiet days (including 3–4 July at 6/6).

## Ideal 60-second walk-up

Do not open Calendar. Rent this hour.

1. **Scan** that scooter’s unique stem QR (`https://icystraitscooters.example/s/IS-103` for Spruce — never a shared fleet code).
2. **You’re renting IS-103** — confirm the ID, name, and photo. Wrong unit? Cancel and scan that scooter’s sticker. Tap **Continue**.
3. **Five I agree taps** (1/5 → 5/5). Each accept auto-advances. Damage & Liability and Area of Operation stay required.
4. Tap **Start rental · $75.00**. Meter starts. Staff get a mock SMS.

Return, later: scan return QR → left photo → right photo → **Done · stop the meter**.

## Checkout

Walk-up path only: Scan → short unit confirm → five required agrees → Start rental. No extra Pay screen. Calendar is for capacity browsing, not walk-up checkout.

### Agreements (draft legal copy)

Rental, Use, Liability, and Safety copy is still marked **DRAFT FOR OWNER REVIEW**. Area of Operation owner rules (no dirt roads; no Icy Strait Port property) are in force.

1. Rental Agreement  
2. Use Restrictions  
3. Area of Operation — **PROHIBITED: any dirt roads; any Icy Strait Port property.** Must accept before Pay.
4. **Damage & Liability** — dedicated tab; customer agrees to cover any and all damage to the e-scooter, any person, and any property including cars, trucks, and other vehicles  
5. Safety & Return — includes pricing and the left/right photo return rule  

Acceptances are stored on the rental with timestamps and can be reopened from rental details. `RentalOperations.startRental` refuses the POS call if any section is missing.

## Billing (exact)

Through `POSProvider`:

- **$75.00** first hour, billed as a block from the moment checkout starts (including t = 0).
- **$37.50** for each *started* additional half hour after 60:00 until check-in.

Examples: 60:00 → $75.00; 60:01 → $112.50; 90:00 → $112.50; 90:01 → $150.00.

## Check-in / return

1. Scan the return QR (`escooter://return/{rentalUUID}/{token}`), or open **My rentals → Preview mock return email** (no real mail).
2. Capture **left side** and **right side** photos (exactly two). Camera on device; Simulator can pick from the library or use the official product photo as a demo stand-in. Retakes allowed.
3. Check-in stays blocked until both sides are stored.
4. Completing check-in stops the meter, captures the final POS amount, stores the JPEGs on the rental, frees hourly capacity, and texts active staff to inspect condition.

## Crew app (Icy Strait Crew)

Staff-only second target in the same project. Home is a 6-unit Hoonah lot board (Out / Back, renter, times). Unit detail is that scooter’s history. Roster adds/edits name, phone, email, active. Alert inbox shows the SMS / email / push copy that was queued, per unit.

Sign-in is a beta PIN (`5152`, last four of the front-desk cell) plus the staff list. Not a full auth product.

Starter crew: **Front desk / Dennis** · `+1 (907) 500-5152` · `maddasstoner@yahoo.com` and `f.vhappytimes@gmail.com`.

### Shared event pipe (not on-device mock)

The customer app’s SwiftData store stays on that phone. A rental on a renter device will not appear on a crew phone unless both apps share a live event list.

CloudKit (same Apple team, container `iCloud.com.icystrait.scooterrentals`, query subscriptions / APNs) is compiled in `SharedKit/CloudKitLotStore.swift`. It is **not** entitled on the shipping customer app. Adding iCloud to `com.icystrait.scooterrentals` would require a new App Store profile and can break the current TestFlight upload. Optional entitlement files:

- `IcyStraitScooterRentals/IcyStraitScooterRentals-CloudKit.entitlements`
- `IcyStraitCrew/IcyStraitCrew-CloudKit.entitlements`

v1 live pipe is a tiny HTTP JSON server both apps POST/GET:

```text
python3 tools/rental-events-server/server.py --port 8787
```

Point both apps at that host (Settings in the customer app, Roster → Pipe in Crew). Default is `http://127.0.0.1:8787` (Simulator on the same Mac). On two physical phones, use a LAN/public URL. `NSAllowsLocalNetworking` is on; no Twilio keys.

On real checkout and check-in the customer app publishes a per-unit event (`scooterID`, `scooterName`, `rentalID`, renter display name if known, `startedAt`, `endedAt`) and queues mock SMS + email + a push payload. Notification text names the exact unit (e.g. `IS-104 Otter`), the renter if known, and Alaska time. Live APNs and live SMS are **not** claimed: Twilio stays a stub; push copy is stored and shown in Crew; local notifications fire when Crew is running or gets a refresh.

Mock POS, season, hours, pricing, and per-unit QR stickers are unchanged.

## Staff SMS

`StaffNotifier` + **`MockStaffNotifier`** (default). `TwilioSMSNotifier` is a compile-ready stub and does **not** send traffic or require API keys.

- SwiftData `StaffMember`: id, display name, phone (E.164), emails, active flag.
- **My rentals → gear → Staff roster**: list, add, edit, disable, delete.
- Seeded once: **Front desk / Dennis** · `9075005152` / `+19075005152` / **+1 (907) 500-5152** · `maddasstoner@yahoo.com`, `f.vhappytimes@gmail.com` (editable). Deleting the roster does not recreate it on next launch.
- Checkout and check-in notify **every active** staff member (mock SMS + email copy) and publish the same event to the crew pipe.
- Simulator shows an orange **SMS sent** banner and a log in Settings. Message includes the exact unit (`IS-104 Otter`), renter if known, and time; returns note that left/right condition photos were submitted.

To send real SMS later: implement `StaffNotifier` with Twilio (or swap in `TwilioSMSNotifier` after setting `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `TWILIO_FROM_NUMBER`) and point it at the active roster numbers.

## POS swap

```swift
protocol POSProvider {
    func startCheckout(rentalID: UUID, scooterID: String, estimatedAmount: Decimal) async throws -> POSAuthorization
    func finalizeCharge(authorizationID: String, finalAmount: Decimal) async throws -> POSCharge
    func cancelCheckout(authorizationID: String) async throws
}
```

v1 injects `MockPOSProvider` from `POSEnvironment` in `IcyStraitScooterRentalsApp`. Ledger rows are stored in SwiftData. For Square or Stripe Terminal, add a new type that conforms to `POSProvider` and assign it there. No API keys ship in this repo.

## Customer QR / install flow

Preferred stem QR is an https smart link:

`https://icystraitscooters.example/s/IS-101`

| App installed | Opens Icy Strait Scooter Rentals on Scan and starts checkout for that unit (Universal Link + `onContinueUserActivity`). |
| App not installed | Safari hits the stub in `landing/index.html` (“Get the app”) and the App Store button. |

**There is no live App Store listing yet.** Placeholders:

- Apple ID: `APP_STORE_APPLE_ID_TBD`
- Store URL: `https://apps.apple.com/app/idAPP_STORE_APPLE_ID_TBD`
- Team ID in `apple-app-site-association`: `APPLE_TEAM_ID_TBD`
- Associated domain entitlement: not included in the signed app yet (placeholder host would fail App Store / TestFlight signing). Re-add a real `applinks:` host later.

Host `landing/` (plus `.well-known/apple-app-site-association`) on that host after you have a Team ID. Until then, Simulator demos still accept `escooter://scooter/IS-101` and bare `IS-101`.

Store redirect only works after a published App Store page or a TestFlight public link.

## Printable QR checklist (one sticker per scooter)

**Hard product rule:** each unit has its own unique QR. Never print or scan a shared “any scooter / rent the fleet” code. After scan, checkout shows **You’re renting IS-10x** (name + photo) before agreements. The rental record and staff SMS store that exact unit ID.

Print six stickers. Affix one to each stem. Scan-test every code before the lot opens.

| Sticker | Unit | Name | Dock | Preferred https payload (print this) | Demo custom scheme |
| --- | --- | --- | --- | --- | --- |
| 1 | IS-101 | Glacier | Dock A · North lot | `https://icystraitscooters.example/s/IS-101` | `escooter://scooter/IS-101` |
| 2 | IS-102 | Humpback | Dock B · North lot | `https://icystraitscooters.example/s/IS-102` | `escooter://scooter/IS-102` |
| 3 | IS-103 | Spruce | Dock C · Lodge loop | `https://icystraitscooters.example/s/IS-103` | `escooter://scooter/IS-103` |
| 4 | IS-104 | Otter | Dock D · Waterfront | `https://icystraitscooters.example/s/IS-104` | `escooter://scooter/IS-104` |
| 5 | IS-105 | Raven | Dock E · Cannery row | `https://icystraitscooters.example/s/IS-105` | `escooter://scooter/IS-105` |
| 6 | IS-106 | Tidepool | Dock F · Point trail | `https://icystraitscooters.example/s/IS-106` | `escooter://scooter/IS-106` |

Bare IDs (`IS-101` … `IS-106`) also parse for Simulator typing. Unknown IDs (`IS-999`, `FLEET`, `/s/any`) are rejected.

**How to generate the six codes**

1. In the app: **My rentals → gear → Fleet QR stickers** — live QR images for all six https payloads.
2. Printable sheet: open `landing/qr-stickers.html` in a browser and print (six cards, one per scooter). Generated PNGs live in `landing/qr-stickers/IS-101.png` … `IS-106.png`.
3. Payload list: `landing/qr-payloads.txt`.

Return QRs are per rental (`escooter://return/{uuid}/{token}`), not per scooter.

## Simulator QR samples

Camera scanning needs a physical device. On Simulator:

| Action | Payload |
| --- | --- |
| Checkout Glacier (preferred) | `https://icystraitscooters.example/s/IS-101` |
| Checkout Glacier (demo scheme) | `escooter://scooter/IS-101` |
| Checkout Spruce | `https://icystraitscooters.example/s/IS-103` |
| Checkout Tidepool | `IS-106` |
| Return | `escooter://return/{uuid}/{token}` from **My rentals** or the mock email |

## Persistence

SwiftData on device: scooters, rentals, agreement acceptances, return photos (external storage), POS ledger, staff roster, SMS log. Live lot events for Crew live on the HTTP pipe (and CloudKit when entitled), not in the customer phone’s SwiftData.

## Tests

Product target `IcyStraitScooterRentalsTests` covers billing increments, the 6/hour cap, the five-section agreement gate, left+right return photos, unique-per-scooter QR parsing (and rejection of shared/unknown codes), rental records bound to the scanned unit ID, mock staff fan-out to multiple numbers, Dennis emails, and the shared crew event pipe (per-unit checkout/return events, board Out/Back, notification payloads that name the exact unit).

```text
python3 tools/rental-events-server/test_server.py
```

```text
Product → Test
```

## Codemagic → TestFlight

GitHub (Codemagic source): https://github.com/cotd99/icy-strait-scooter-rentals  

Root `codemagic.yaml` builds the native iOS app and uploads to TestFlight. There are no CocoaPods and no secrets in the repo.

| Setting | Value |
| --- | --- |
| Project | `IcyStraitScooterRentals.xcodeproj` |
| Scheme | `IcyStraitScooterRentals` (customer). Crew is `IcyStraitCrew` — see the commented second-workflow note in `codemagic.yaml`. |
| Bundle ID | `com.icystrait.scooterrentals` (customer). Crew: `com.icystrait.crew` (needs its own App Store Connect record before a second workflow). |
| `distribution_type` | `app_store` |
| `submit_to_testflight` | `true` |
| App Store Connect integration name | **`APP_STORE_CONNECT_INTEGRATION_NAME_TBD`** (placeholder) |

Replace the integration name in `codemagic.yaml` with the **exact** name of the App Store Connect API key you add in Codemagic:

1. Codemagic → Team settings → Integrations → Developer Portal → Manage keys.  
2. Add the `.p8` key from App Store Connect (Users and Access → Integrations → App Store Connect API).  
3. Copy that Codemagic key name into `integrations.app_store_connect`.  
4. Codemagic → Team settings → codemagic.yaml settings → Code signing identities: Apple Distribution certificate + App Store profile for `com.icystrait.scooterrentals`.  
5. Replace `APP_STORE_APPLE_ID_TBD` with the numeric Apple ID from App Store Connect → App Information (not the bundle ID). Create the App Store Connect app record before the first automated upload.

Do not commit `.p8`, `.p12`, provisioning profiles, or API tokens.

## Decisions (owner)

- Vehicle is a 4-wheel offroad e-scooter; copy, icons, and hero art never depict a 2-wheel kick scooter.
- Calendar is the 2027 season; live checkout uses the device clock unless season hours are enforced.
- Sample 2027 occupancy is a curated set of days, not every calendar day, so first launch stays fast.
- Return photos are **left and right only** (not front/back).
- SMS / event-pipe failure never rolls back a successful checkout or check-in.
- Agreement and area-of-operation text is draft placeholder for counsel.
- Customer TestFlight stays on empty entitlements. The live crew board uses the tiny HTTP event pipe; CloudKit is compiled and optional.
- Live APNs and live Twilio SMS are not claimed in v1. Mock copies and local crew notifications are.
