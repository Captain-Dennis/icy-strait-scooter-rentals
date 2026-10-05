# CloudKit, ready to turn on

Current TestFlight (customer build 4 / crew build 3, and the next builds from today's workflows) stays on the **empty** entitlements and the HTTP pipe. This document is the later flip. No architecture change is required after the portal work below.

CloudKit at this lot's size is included with the existing Apple Developer Program. There is no paid CloudKit add-on.

## What is already wired

Both apps share one public-database container:

`iCloud.com.icystrait.scooterrentals` (`SharedPipeConfig.cloudKitContainer`)

| App | Bundle ID | Shipping entitlements (default) | CloudKit entitlements (opt-in) |
| --- | --- | --- | --- |
| Icy Strait Scooter Rentals | `com.icystrait.scooterrentals` | `IcyStraitScooterRentals/IcyStraitScooterRentals.entitlements` (empty) | `IcyStraitScooterRentals/IcyStraitScooterRentals-CloudKit.entitlements` |
| Icy Strait Crew | `com.icystrait.crew` | `IcyStraitCrew/IcyStraitCrew.entitlements` (empty) | `IcyStraitCrew/IcyStraitCrew-CloudKit.entitlements` |

Debug and Release on each target use `Config/Customer.xcconfig` or `Config/Crew.xcconfig`. Those files set `ICY_ENTITLEMENTS_FILE` to the empty plist. `CODE_SIGN_ENTITLEMENTS` is `$(ICY_ENTITLEMENTS_FILE)`, so the default archive does not embed CloudKit.

`codemagic.yaml` does **not** pass `CLOUDKIT_ENTITLED` or a CloudKit entitlements path.

## The switch

Two gates, both off today. CloudKit is used only when **both** are true. If a CloudKit call throws, the same operation is retried on the HTTP pipe.

1. **Build gate.** `Config/Customer-CloudKit.xcconfig` and `Config/Crew-CloudKit.xcconfig` select the CloudKit entitlements and add the compile flag `CLOUDKIT_ENTITLED`. Shipping xcconfigs do not. An unentitled build ignores the runtime switch, even if UserDefaults is already `true`.
2. **Runtime switch.** `SharedPipeConfig.preferCloudKit` (UserDefaults key `icystrait.preferCloudKit`). Default is **false**. In an entitled build, Settings (customer) and Roster (crew) show **Prefer CloudKit**. On this shipping build the toggle is disabled.

`SharedPipeConfig.usesCloudKit` is that pair. `customerCloudKitEntitled` is the same build gate and is false here.

## Turn it on (next TestFlight)

Do this only after the portal list. Skip a step and the phones stay on HTTP.

1. **Container.** In [developer.apple.com](https://developer.apple.com) → Identifiers, confirm `iCloud.com.icystrait.scooterrentals` exists and is attached to **both** `com.icystrait.scooterrentals` and `com.icystrait.crew`. iCloud / CloudKit is already enabled (or in progress) on both App IDs.
2. **Dashboard schema.** [CloudKit Console](https://icloud.developer.apple.com) → this container → **Development**, public database. Add the record types below, then **Deploy Schema to Production**. Queries use `NSPredicate(value: true)`, so each type needs to be queryable (mark at least one field Queryable, or use the console's queryable-record-type index).
3. **Profiles.** Regenerate the App Store profiles after iCloud is on the App IDs. Customer profile must include CloudKit. Crew profile must include CloudKit **and** Push. `aps-environment` on the crew distribution entitlements file is **`production`** (required for TestFlight / App Store). `development` is only in `IcyStraitCrew-CloudKit-Development.entitlements` for a local development-signed run (`Config/Crew-CloudKit-Development.xcconfig`).
4. **Codemagic.** Team settings → code signing identities: refresh `app_store` and `crew_app_store` so the new profiles replace the ones baked before iCloud. Do not reuse the customer profile for crew.
5. **Build gate, both apps.** Either change the target's configuration file, or pass build settings. Do both apps in the same TestFlight pair or one phone will write a store the other is not reading.
   - Xcode → target → Build Settings → Based on Configuration File: `Config/Customer-CloudKit.xcconfig` or `Config/Crew-CloudKit.xcconfig` for Debug and Release.
   - Or leave the shipping xcconfig in place and pass, for the customer archive:

     ```text
     ICY_ENTITLEMENTS_FILE=IcyStraitScooterRentals/IcyStraitScooterRentals-CloudKit.entitlements SWIFT_ACTIVE_COMPILATION_CONDITIONS=CLOUDKIT_ENTITLED
     ```

     Crew archive (production APNs):

     ```text
     ICY_ENTITLEMENTS_FILE=IcyStraitCrew/IcyStraitCrew-CloudKit.entitlements SWIFT_ACTIVE_COMPILATION_CONDITIONS=CLOUDKIT_ENTITLED
     ```

     Codemagic: append those two settings to that workflow's `--archive-xcargs`. Do not add them to the workflows that are shipping now.
6. **Runtime switch, both phones.** Install that build. Customer: Settings → **Prefer CloudKit**. Crew: Roster → **Prefer CloudKit**. That sets `icystrait.preferCloudKit`. Until both phones are on, keep using the HTTP URL (Settings / Roster pipe field, default `http://127.0.0.1:8787`).

Crew then registers the public-database subscription `icystrait.rental-events` on `RentalEvent` (fires on record creation). Push still needs the production profile from step 3. Local notifications on refresh stay in place either way.

To force HTTP again on an entitled build, turn **Prefer CloudKit** off. You do not need another code change.

## Dashboard fields

Public database. Record names are the UUID strings the apps already use.

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

- Confirm the shared container is created and attached to both App IDs (portal).
- Deploy the schema above to Production.
- Regenerate App Store profiles, then refresh `app_store` and `crew_app_store` in Codemagic.
- Flip step 5 and step 6 together on the **next** TestFlight, not on the build this repo ships today.
