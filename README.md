# Icy Strait Scooter Rentals

Native iOS 17+ SwiftUI app for renting **4-wheel offroad e-scooters** (quad-style, four knobby all-terrain tires — not 2-wheel kick scooters) at Icy Strait Point.

Open `IcyStraitScooterRentals.xcodeproj` in Xcode 15.4 or later, choose an iPhone Simulator, and run the **Icy Strait Scooter Rentals** scheme.

Display name: **Icy Strait Scooter Rentals**  
Bundle ID: `com.icystrait.scooterrentals`

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

## Staff SMS

`StaffNotifier` + **`MockStaffNotifier`** (default). `TwilioSMSNotifier` is a compile-ready stub and does **not** send traffic or require API keys.

- SwiftData `StaffMember`: id, display name, phone (E.164), active flag.
- **My rentals → gear → Staff roster**: list, add, edit, disable, delete.
- Seeded once: **Front desk** · `9075005152` / `+19075005152` / **+1 (907) 500-5152** (editable). Deleting the roster does not recreate it on next launch.
- Checkout and check-in notify **every active** staff member.
- Simulator shows an orange **SMS sent** banner and a log in Settings. Message includes rental id, scooter id/name, start or return time; returns note that left/right condition photos were submitted.

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
- Associated domain entitlement: `applinks:icystraitscooters.example`

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

SwiftData on device: scooters, rentals, agreement acceptances, return photos (external storage), POS ledger, staff roster, SMS log.

## Tests

Product target `IcyStraitScooterRentalsTests` covers billing increments, the 6/hour cap, the five-section agreement gate, left+right return photos, unique-per-scooter QR parsing (and rejection of shared/unknown codes), rental records bound to the scanned unit ID, and mock staff fan-out to multiple numbers.

```text
Product → Test
```

## Codemagic → TestFlight

GitHub (Codemagic source): https://github.com/cotd99/icy-strait-scooter-rentals  

Root `codemagic.yaml` builds the native iOS app and uploads to TestFlight. There are no CocoaPods and no secrets in the repo.

| Setting | Value |
| --- | --- |
| Project | `IcyStraitScooterRentals.xcodeproj` |
| Scheme | `IcyStraitScooterRentals` |
| Bundle ID | `com.icystrait.scooterrentals` |
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
- SMS failure never rolls back a successful checkout or check-in.
- Agreement and area-of-operation text is draft placeholder for counsel.
