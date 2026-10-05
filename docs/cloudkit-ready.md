# CloudKit is the TestFlight sync path

Season-one TestFlight uses CloudKit. Customer `ios-testflight` and crew `ios-crew-testflight` archive Release with the CloudKit xcconfigs. An entitled build starts with **Prefer CloudKit** on. If a CloudKit call throws, the same operation is retried on the HTTP pipe.

Builds already installed (customer build 4 / crew build 3, and any archive made before this change) stay on the empty entitlements until the next TestFlight pair is installed.

CloudKit at this lot's size is included with the existing Apple Developer Program. There is no paid CloudKit add-on. Record types are created in CloudKit Dashboard. This repo does not invent schema.

## What ships

Both apps share one public-database container:

`iCloud.com.icystrait.scooterrentals` (`SharedPipeConfig.cloudKitContainer`)

| App | Bundle ID | Debug | Release (TestFlight / App Store) |
| --- | --- | --- | --- |
| Icy Strait Scooter Rentals | `com.icystrait.scooterrentals` | `Config/Customer.xcconfig` → empty entitlements | `Config/Customer-CloudKit.xcconfig` → `IcyStraitScooterRentals-CloudKit.entitlements` |
| Icy Strait Crew | `com.icystrait.crew` | `Config/Crew.xcconfig` → empty entitlements | `Config/Crew-CloudKit.xcconfig` → `IcyStraitCrew-CloudKit.entitlements` (`aps-environment` = `production`) |

`CODE_SIGN_ENTITLEMENTS` is `$(ICY_ENTITLEMENTS_FILE)`. Release sets that to the CloudKit plist and adds `CLOUDKIT_ENTITLED`. Debug does not, so Simulator and the unit-test host stay on HTTP.

`codemagic.yaml` passes the same files again:

- `--archive-flags "-xcconfig …/Customer-CloudKit.xcconfig"` (or `Crew-CloudKit.xcconfig`). Codemagic applies archive flags before `xcodebuild archive`, which is where `-xcconfig` belongs.
- `--archive-xcargs` also sets `ICY_ENTITLEMENTS_FILE` and `SWIFT_ACTIVE_COMPILATION_CONDITIONS=CLOUDKIT_ENTITLED`.

Crew distribution must stay on `Config/Crew-CloudKit.xcconfig`. `Config/Crew-CloudKit-Development.xcconfig` is only for a local development-signed run (`aps-environment` = `development`).

## The switch

CloudKit is used when the binary is entitled and Prefer CloudKit is on. HTTP is used otherwise, and whenever CloudKit throws.

1. **Build gate.** Release and the two Codemagic workflows set `CLOUDKIT_ENTITLED`. An unentitled (Debug) build ignores the runtime switch, even if UserDefaults is already `true`.
2. **Runtime switch.** `SharedPipeConfig.preferCloudKit` (UserDefaults key `icystrait.preferCloudKit`). On an entitled build, a missing key reads as **true**. Settings (customer) and Roster (crew) still show **Prefer CloudKit**. Turn it off to force HTTP. An explicit `false` stays off across launches.

`SharedPipeConfig.usesCloudKit` is that pair. `SelectingLotStore` tries CloudKit first, then the HTTP store.

## Before the next Codemagic build

Container attach and profile regeneration are done on Apple Developer: `iCloud.com.icystrait.scooterrentals` is on both App IDs, and `app_store` / `crew_app_store` were regenerated ACTIVE. The archive still fails or falls back if the steps below are skipped.

1. **Dashboard schema (portal, not code).** [CloudKit Console](https://icloud.developer.apple.com) → container `iCloud.com.icystrait.scooterrentals` → **Development**, public database. Add the record types below, then **Deploy Schema to Production**. Queries use `NSPredicate(value: true)`, so each type needs to be queryable (mark at least one field Queryable, or use the console's queryable-record-type index). Until Production has these types, CloudKit calls fail and both apps use HTTP. Do not add a schema bootstrap in the app.
2. **Codemagic identities.** Team settings → code signing identities: `app_store` and `crew_app_store` must be the regenerated profiles (CloudKit on both; CloudKit **and** Push on crew). Replace any profile uploaded before the container was attached. Do not reuse the customer profile for crew. The fresh `.mobileprovision` files are the ones to upload if Codemagic still has the older copies.
3. **Start both workflows** from the commit that contains this Codemagic change (`ios-testflight` and `ios-crew-testflight`). This file does not trigger builds. Install that pair on both phones. One phone on the old HTTP build will not read the other's CloudKit records.
4. **Prefer CloudKit on device.** A fresh install of this build already has the switch on. Open it only if an earlier build saved `icystrait.preferCloudKit` as false: customer Settings, crew Roster. Turn it off later to force HTTP without another archive.

Crew registers the public-database subscription `icystrait.rental-events` on `RentalEvent` (fires on record creation) when Prefer CloudKit is on. That save needs the Production schema and the crew push entitlement. If it fails, the board still loads on refresh. Local notifications on refresh stay in place either way.

## Dashboard fields

Public database. Record names are the UUID strings the apps already use. Create these in the console. Do not add new record types in code to "fix" a missing schema.

**RentalEvent**

| Field | Type |
| --- | --- |
| `kind` | String |
| `scooterID` | String |
| `scooterName` | String |
| `rentalID` | String |
| `renterDisplayName` | String |
| `startedAt` | Date/Time |
| `endedAt` | Date/Time (optional) |
| `occurredAt` | Date/Time |

**StaffAlert**

| Field | Type |
| --- | --- |
| `channel` | String |
| `title` | String |
| `body` | String |
| `scooterID` | String |
| `scooterName` | String |
| `rentalID` | String |
| `kindRaw` | String |
| `recipientName` | String |
| `recipientAddress` | String |
| `providerName` | String |
| `sentAt` | Date/Time |
| `liveDelivery` | Int(64) |

**CrewMember**

| Field | Type |
| --- | --- |
| `displayName` | String |
| `phoneE164` | String |
| `emailsCSV` | String |
| `isActive` | Int(64) |
| `updatedAt` | Date/Time |

## Still human

- Deploy the schema above to Production (Development first, then Deploy Schema to Production).
- Confirm Codemagic `app_store` and `crew_app_store` are the regenerated profiles, then start both TestFlight workflows.
- On device, Prefer CloudKit is already on for a new entitled install. Turn it on once only if a previous build saved it off.
