#!/usr/bin/env python3
"""Add Shared sources, StaffSeeder, Crew target, and Crew tests file to the Xcode project."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / "IcyStraitScooterRentals.xcodeproj" / "project.pbxproj"

# 24-char hex IDs
F = {
    "RentalLifecycleEvent": ("C0DE01000000000000000001", "C0DE01000000000000000002", "C0DE01000000000000000003"),
    "CrewBoard": ("C0DE01000000000000000004", "C0DE01000000000000000005", "C0DE01000000000000000006"),
    "CrewAlertCopy": ("C0DE01000000000000000007", "C0DE01000000000000000008", "C0DE01000000000000000009"),
    "SharedLotStore": ("C0DE0100000000000000000A", "C0DE0100000000000000000B", "C0DE0100000000000000000C"),
    "HTTPLotStore": ("C0DE0100000000000000000D", "C0DE0100000000000000000E", "C0DE0100000000000000000F"),
    "SharedPipeConfig": ("C0DE01000000000000000010", "C0DE01000000000000000011", "C0DE01000000000000000012"),
    "LotEventPublisher": ("C0DE01000000000000000013", "C0DE01000000000000000014", "C0DE01000000000000000015"),
    "CloudKitLotStore": ("C0DE01000000000000000016", "C0DE01000000000000000017", "C0DE01000000000000000018"),
    "StaffSeeder": ("C0DE01000000000000000019", "C0DE0100000000000000001A", "C0DE0100000000000000001B"),
    "CrewEventPipeTests": ("C0DE0100000000000000001C", "C0DE0100000000000000001D", None),
    "IcyStraitCrewApp": ("C0DE02000000000000000001", None, "C0DE02000000000000000002"),
    "CrewRootView": ("C0DE02000000000000000003", None, "C0DE02000000000000000004"),
    "CrewSession": ("C0DE02000000000000000005", None, "C0DE02000000000000000006"),
    "CrewLotMonitor": ("C0DE02000000000000000007", None, "C0DE02000000000000000008"),
    "CrewSignInView": ("C0DE02000000000000000009", None, "C0DE0200000000000000000A"),
    "CrewBoardView": ("C0DE0200000000000000000B", None, "C0DE0200000000000000000C"),
    "UnitHistoryView": ("C0DE0200000000000000000D", None, "C0DE0200000000000000000E"),
    "AlertInboxView": ("C0DE0200000000000000000F", None, "C0DE02000000000000000010"),
    "CrewRosterHome": ("C0DE02000000000000000011", None, "C0DE02000000000000000012"),
    "CrewInfo": ("C0DE02000000000000000013", None, None),
    "CrewEntitlements": ("C0DE02000000000000000014", None, None),
    "CrewAssets": ("C0DE02000000000000000015", None, "C0DE02000000000000000016"),
    "CKEntitlements": ("C0DE0100000000000000001E", None, None),
}

CREW_TARGET = "C0DE03000000000000000001"
CREW_PRODUCT = "C0DE03000000000000000002"
CREW_SOURCES = "C0DE03000000000000000003"
CREW_FRAMEWORKS = "C0DE03000000000000000004"
CREW_RESOURCES = "C0DE03000000000000000005"
CREW_CFG_LIST = "C0DE03000000000000000006"
CREW_DEBUG = "C0DE03000000000000000007"
CREW_RELEASE = "C0DE03000000000000000008"
GROUP_SHARED = "C0DE04000000000000000001"
GROUP_SHAREDKIT = "C0DE04000000000000000002"
GROUP_CREW = "C0DE04000000000000000003"
GROUP_CREW_APP = "C0DE04000000000000000004"
GROUP_CREW_SERVICES = "C0DE04000000000000000005"
GROUP_CREW_VIEWS = "C0DE04000000000000000006"

# Shared customer sources also compiled into Crew (existing fileRef IDs)
EXISTING_CREW_SOURCES = [
    ("C542AACC84F86C31AF3A2412", "C0DE05000000000000000001", "BrandTheme.swift"),
    ("67FBF37B57EC7AD9217FCA21", "C0DE05000000000000000002", "FourWheelScooterMark.swift"),
    ("DBCC73F3324DCDEBAB28B08D", "C0DE05000000000000000003", "SharedComponents.swift"),
    ("8F3A1C2E4B5D67890A1B2C42", "C0DE05000000000000000004", "FleetCatalog.swift"),
    ("8F3A1C2E4B5D67890A1B2C3E", "C0DE05000000000000000005", "AppLinkConfig.swift"),
    ("1C9878ABABAFA6166503CA78", "C0DE05000000000000000006", "QRPayload.swift"),
    ("6F4668B61C43B051FDEAAF4D", "C0DE05000000000000000007", "Season.swift"),
    ("D4B14045ECDBF096040C224C", "C0DE05000000000000000008", "BillingCalculator.swift"),
    ("68EA36DB770B31CD57D23E41", "C0DE05000000000000000009", "AgreementSection.swift"),
    ("3FE8295090ED40B06AB60A68", "C0DE0500000000000000000A", "ReturnPhotoSide.swift"),
    ("78E68EF390163B87F1E7D80D", "C0DE0500000000000000000B", "Rental.swift"),
    ("EDC320F8284AC27842245FAF", "C0DE0500000000000000000C", "ReturnPhoto.swift"),
    ("2F07E4CEE21191F22A120F2B", "C0DE0500000000000000000D", "StaffMember.swift"),
    ("04E817497FDD8401B4351E2E", "C0DE0500000000000000000E", "StaffSMSLog.swift"),
    ("508783D7FB5309228BB063E2", "C0DE0500000000000000000F", "StaffConfig.swift"),
    ("3988763E4E2F279B24961ADE", "C0DE05000000000000000010", "StaffNotifier.swift"),
    ("09C068A9B4926FE4E899F08D", "C0DE05000000000000000011", "StaffServices.swift"),
    ("541DFA80D782ED4B5F712400", "C0DE05000000000000000012", "StaffRosterView.swift"),
    ("22E12ECDEA35511CD68B4E77", "C0DE05000000000000000013", "AppPreferences.swift"),
    # Types referenced by the files above. Missing these from Crew is
    # "cannot find type in scope" on archive (SharedComponents/Rental/AppPreferences).
    ("85B7339AD0C8A9A3216A7E8C", "C0DE05000000000000000015", "Scooter.swift"),
    ("C5165AC808D412184357660D", "C0DE05000000000000000016", "CapacityCalculator.swift"),
    ("C098FE7136E65CB524F8E267", "C0DE05000000000000000017", "POSProvider.swift"),
    ("1E94C380D7CCB87862E5FA25", "C0DE05000000000000000018", "MockPOSProvider.swift"),
]

# Existing file refs for those build files
EXISTING_FILE_REFS = {
    "BrandTheme.swift": "B048162F5E37787421C524F3",
    "FourWheelScooterMark.swift": "47A02604967722EB55DC8529",
    "SharedComponents.swift": "C790F4533B24D54622EB9BA7",
    "FleetCatalog.swift": "8F3A1C2E4B5D67890A1B2C41",
    "AppLinkConfig.swift": "8F3A1C2E4B5D67890A1B2C3D",
    "QRPayload.swift": "609432BE832A40BAB1387F41",
    "Season.swift": "BA3A84C72319A402F8E9BD55",
    "BillingCalculator.swift": "EF7A48D7CADF654086914FCE",
    "AgreementSection.swift": "6249CD65E96C09370AECDE38",
    "ReturnPhotoSide.swift": "1CE062C3C344110C8496E8B6",
    "Rental.swift": "7FB00304E2BD2BA2CCDF55C1",
    "ReturnPhoto.swift": "F71C24FE6C1B759491F7CD9E",
    "StaffMember.swift": "7AA5D687A4B753F62B8AE41F",
    "StaffSMSLog.swift": "7C2B94BCF27D1A3617AB0A86",
    "StaffConfig.swift": "5696570565AC810398868B6A",
    "StaffNotifier.swift": "6090D6191E01E4399AB2FE40",
    "StaffServices.swift": "520DB5C7948A34B13AAFF379",
    "StaffRosterView.swift": "FE1826D20AB2EE3CDAF7F7B0",
    "AppPreferences.swift": "C8EB231E36A084F6537CD9E2",
    "Scooter.swift": "8E78DA695488BBC03D18FF2F",
    "CapacityCalculator.swift": "38A33EEF4669FC7112993137",
    "POSProvider.swift": "02789EE956C55D0ECF33CFD4",
    "MockPOSProvider.swift": "37B4C15ECC87683FE24145EA",
    "Assets.xcassets": "D2BAA48C14157B374334CB7C",
}

CUSTOMER_ASSETS_CREW = "C0DE05000000000000000014"


def build_file(bid: str, fid: str, name: str) -> str:
    return f"\t\t{bid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {name} */; }};\n"


def file_ref(fid: str, name: str, path: str | None = None, ftype: str = "sourcecode.swift") -> str:
    shown = path or name
    return (
        f"\t\t{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; "
        f"path = {shown}; sourceTree = \"<group>\"; }};\n"
    )


def ensure_crew_sources(text: str) -> str:
    """Add any EXISTING_CREW_SOURCES still missing from the Crew compile phase."""
    added_build = ""
    added_phase = ""
    for _old_build, new_build, name in EXISTING_CREW_SOURCES:
        phase_line = f"\t\t\t\t{new_build} /* {name} in Sources */,\n"
        if phase_line in text:
            continue
        fid = EXISTING_FILE_REFS[name]
        added_build += build_file(new_build, fid, name)
        added_phase += phase_line
    if not added_phase:
        return text

    if added_build:
        text = text.replace(
            "/* End PBXBuildFile section */",
            added_build + "/* End PBXBuildFile section */",
        )

    # Crew-only compile IDs; insert after the last existing shared customer source.
    marker = "\t\t\t\tC0DE05000000000000000013 /* AppPreferences.swift in Sources */,\n"
    if marker not in text:
        raise SystemExit("Crew Sources phase marker AppPreferences.swift not found")
    text = text.replace(marker, marker + added_phase, 1)
    print("Added missing Crew sources:\n" + added_phase)
    return text


def main() -> None:
    text = PBX.read_text()
    if "IcyStraitCrew" in text and "C0DE03000000000000000001" in text:
        updated = ensure_crew_sources(text)
        if updated != text:
            PBX.write_text(updated)
            print("Updated", PBX)
        else:
            print("Already patched")
        return

    build_entries = ""
    file_entries = ""
    customer_sources = ""
    test_sources = ""
    crew_sources = ""

    shared_specs = [
        ("RentalLifecycleEvent", "RentalLifecycleEvent.swift"),
        ("CrewBoard", "CrewBoard.swift"),
        ("CrewAlertCopy", "CrewAlertCopy.swift"),
        ("SharedLotStore", "SharedLotStore.swift"),
        ("HTTPLotStore", "HTTPLotStore.swift"),
        ("SharedPipeConfig", "SharedPipeConfig.swift"),
        ("LotEventPublisher", "LotEventPublisher.swift"),
    ]
    for key, name in shared_specs:
        fid, cust, crew = F[key]
        file_entries += file_ref(fid, name)
        build_entries += build_file(cust, fid, name)
        build_entries += build_file(crew, fid, name)
        customer_sources += f"\t\t\t\t{cust} /* {name} in Sources */,\n"
        crew_sources += f"\t\t\t\t{crew} /* {name} in Sources */,\n"

    fid, cust, crew = F["CloudKitLotStore"]
    file_entries += file_ref(fid, "CloudKitLotStore.swift")
    build_entries += build_file(cust, fid, "CloudKitLotStore.swift")
    build_entries += build_file(crew, fid, "CloudKitLotStore.swift")
    customer_sources += f"\t\t\t\t{cust} /* CloudKitLotStore.swift in Sources */,\n"
    crew_sources += f"\t\t\t\t{crew} /* CloudKitLotStore.swift in Sources */,\n"

    fid, cust, crew = F["StaffSeeder"]
    file_entries += file_ref(fid, "StaffSeeder.swift")
    build_entries += build_file(cust, fid, "StaffSeeder.swift")
    build_entries += build_file(crew, fid, "StaffSeeder.swift")
    customer_sources += f"\t\t\t\t{cust} /* StaffSeeder.swift in Sources */,\n"
    crew_sources += f"\t\t\t\t{crew} /* StaffSeeder.swift in Sources */,\n"

    fid, test_id, _ = F["CrewEventPipeTests"]
    file_entries += file_ref(fid, "CrewEventPipeTests.swift")
    build_entries += build_file(test_id, fid, "CrewEventPipeTests.swift")
    test_sources += f"\t\t\t\t{test_id} /* CrewEventPipeTests.swift in Sources */,\n"

    file_entries += file_ref(F["CKEntitlements"][0], "IcyStraitScooterRentals-CloudKit.entitlements", ftype="text.plist.entitlements")

    crew_files = [
        ("IcyStraitCrewApp", "IcyStraitCrewApp.swift"),
        ("CrewRootView", "CrewRootView.swift"),
        ("CrewSession", "CrewSession.swift"),
        ("CrewLotMonitor", "CrewLotMonitor.swift"),
        ("CrewSignInView", "CrewSignInView.swift"),
        ("CrewBoardView", "CrewBoardView.swift"),
        ("UnitHistoryView", "UnitHistoryView.swift"),
        ("AlertInboxView", "AlertInboxView.swift"),
        ("CrewRosterHome", "CrewRosterHome.swift"),
    ]
    for key, name in crew_files:
        fid, _, crew = F[key]
        file_entries += file_ref(fid, name)
        build_entries += build_file(crew, fid, name)
        crew_sources += f"\t\t\t\t{crew} /* {name} in Sources */,\n"

    file_entries += file_ref(F["CrewInfo"][0], "Info.plist", ftype="text.plist.xml")
    file_entries += file_ref(F["CrewEntitlements"][0], "IcyStraitCrew.entitlements", ftype="text.plist.entitlements")
    file_entries += (
        f"\t\t{F['CrewAssets'][0]} /* Assets.xcassets */ = "
        "{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; };\n"
    )
    file_entries += (
        f"\t\t{CREW_PRODUCT} /* IcyStraitCrew.app */ = "
        "{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = IcyStraitCrew.app; sourceTree = BUILT_PRODUCTS_DIR; };\n"
    )

    build_entries += (
        f"\t\t{F['CrewAssets'][2]} /* Assets.xcassets in Resources */ = "
        f"{{isa = PBXBuildFile; fileRef = {F['CrewAssets'][0]} /* Assets.xcassets */; }};\n"
    )
    build_entries += (
        f"\t\t{CUSTOMER_ASSETS_CREW} /* Assets.xcassets in Resources */ = "
        f"{{isa = PBXBuildFile; fileRef = {EXISTING_FILE_REFS['Assets.xcassets']} /* Assets.xcassets */; }};\n"
    )

    for old_build, new_build, name in EXISTING_CREW_SOURCES:
        fid = EXISTING_FILE_REFS[name]
        build_entries += build_file(new_build, fid, name)
        crew_sources += f"\t\t\t\t{new_build} /* {name} in Sources */,\n"

    text = text.replace("/* End PBXBuildFile section */", build_entries + "/* End PBXBuildFile section */")
    text = text.replace("/* End PBXFileReference section */", file_entries + "/* End PBXFileReference section */")

    # Root group
    text = text.replace(
        "\t\t\t\tC8A1E76B6CA46DDC89E29CCD /* IcyStraitScooterRentals */,\n"
        "\t\t\t\t8C35799A97AD3FA99FA2EDFE /* IcyStraitScooterRentalsTests */,\n"
        "\t\t\t\t692092DE1C1C8624E142B71D /* Products */,",
        "\t\t\t\tC8A1E76B6CA46DDC89E29CCD /* IcyStraitScooterRentals */,\n"
        "\t\t\t\t8C35799A97AD3FA99FA2EDFE /* IcyStraitScooterRentalsTests */,\n"
        f"\t\t\t\t{GROUP_SHARED} /* Shared */,\n"
        f"\t\t\t\t{GROUP_SHAREDKIT} /* SharedKit */,\n"
        f"\t\t\t\t{GROUP_CREW} /* IcyStraitCrew */,\n"
        "\t\t\t\t692092DE1C1C8624E142B71D /* Products */,",
    )

    text = text.replace(
        "\t\t\t\t05B4B09660ED39C148591D26 /* IcyStraitScooterRentalsTests.xctest */,\n",
        "\t\t\t\t05B4B09660ED39C148591D26 /* IcyStraitScooterRentalsTests.xctest */,\n"
        f"\t\t\t\t{CREW_PRODUCT} /* IcyStraitCrew.app */,\n",
    )

    text = text.replace(
        "\t\t\t\t520DB5C7948A34B13AAFF379 /* StaffServices.swift */,\n",
        "\t\t\t\t520DB5C7948A34B13AAFF379 /* StaffServices.swift */,\n"
        f"\t\t\t\t{F['StaffSeeder'][0]} /* StaffSeeder.swift */,\n",
    )

    text = text.replace(
        "\t\t\t\t8F3A1C2E4B5D67890A1B2C40 /* IcyStraitScooterRentals.entitlements */,\n",
        "\t\t\t\t8F3A1C2E4B5D67890A1B2C40 /* IcyStraitScooterRentals.entitlements */,\n"
        f"\t\t\t\t{F['CKEntitlements'][0]} /* IcyStraitScooterRentals-CloudKit.entitlements */,\n",
    )

    text = text.replace(
        "\t\t\t\t6DACE63C78294F090B5412C2 /* CapacityCalculatorTests.swift */,\n",
        "\t\t\t\t6DACE63C78294F090B5412C2 /* CapacityCalculatorTests.swift */,\n"
        f"\t\t\t\t{F['CrewEventPipeTests'][0]} /* CrewEventPipeTests.swift */,\n",
    )

    groups = f"""
		{GROUP_SHARED} /* Shared */ = {{
			isa = PBXGroup;
			children = (
				{F['RentalLifecycleEvent'][0]} /* RentalLifecycleEvent.swift */,
				{F['CrewBoard'][0]} /* CrewBoard.swift */,
				{F['CrewAlertCopy'][0]} /* CrewAlertCopy.swift */,
				{F['SharedLotStore'][0]} /* SharedLotStore.swift */,
				{F['HTTPLotStore'][0]} /* HTTPLotStore.swift */,
				{F['SharedPipeConfig'][0]} /* SharedPipeConfig.swift */,
				{F['LotEventPublisher'][0]} /* LotEventPublisher.swift */,
			);
			path = Shared;
			sourceTree = "<group>";
		}};
		{GROUP_SHAREDKIT} /* SharedKit */ = {{
			isa = PBXGroup;
			children = (
				{F['CloudKitLotStore'][0]} /* CloudKitLotStore.swift */,
			);
			path = SharedKit;
			sourceTree = "<group>";
		}};
		{GROUP_CREW} /* IcyStraitCrew */ = {{
			isa = PBXGroup;
			children = (
				{F['CrewAssets'][0]} /* Assets.xcassets */,
				{F['CrewInfo'][0]} /* Info.plist */,
				{F['CrewEntitlements'][0]} /* IcyStraitCrew.entitlements */,
				{GROUP_CREW_APP} /* App */,
				{GROUP_CREW_SERVICES} /* Services */,
				{GROUP_CREW_VIEWS} /* Views */,
			);
			path = IcyStraitCrew;
			sourceTree = "<group>";
		}};
		{GROUP_CREW_APP} /* App */ = {{
			isa = PBXGroup;
			children = (
				{F['IcyStraitCrewApp'][0]} /* IcyStraitCrewApp.swift */,
				{F['CrewRootView'][0]} /* CrewRootView.swift */,
			);
			path = App;
			sourceTree = "<group>";
		}};
		{GROUP_CREW_SERVICES} /* Services */ = {{
			isa = PBXGroup;
			children = (
				{F['CrewSession'][0]} /* CrewSession.swift */,
				{F['CrewLotMonitor'][0]} /* CrewLotMonitor.swift */,
			);
			path = Services;
			sourceTree = "<group>";
		}};
		{GROUP_CREW_VIEWS} /* Views */ = {{
			isa = PBXGroup;
			children = (
				{F['CrewSignInView'][0]} /* CrewSignInView.swift */,
				{F['CrewBoardView'][0]} /* CrewBoardView.swift */,
				{F['UnitHistoryView'][0]} /* UnitHistoryView.swift */,
				{F['AlertInboxView'][0]} /* AlertInboxView.swift */,
				{F['CrewRosterHome'][0]} /* CrewRosterHome.swift */,
			);
			path = Views;
			sourceTree = "<group>";
		}};
"""
    text = text.replace("/* End PBXGroup section */", groups + "/* End PBXGroup section */")

    native_target = f"""
		{CREW_TARGET} /* IcyStraitCrew */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {CREW_CFG_LIST} /* Build configuration list for PBXNativeTarget "IcyStraitCrew" */;
			buildPhases = (
				{CREW_SOURCES} /* Sources */,
				{CREW_FRAMEWORKS} /* Frameworks */,
				{CREW_RESOURCES} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = IcyStraitCrew;
			productName = IcyStraitCrew;
			productReference = {CREW_PRODUCT} /* IcyStraitCrew.app */;
			productType = "com.apple.product-type.application";
		}};
"""
    text = text.replace("/* End PBXNativeTarget section */", native_target + "/* End PBXNativeTarget section */")

    text = text.replace(
        "\t\t\t\t904EC43069525F78E67530F2 /* IcyStraitScooterRentalsTests */,\n",
        "\t\t\t\t904EC43069525F78E67530F2 /* IcyStraitScooterRentalsTests */,\n"
        f"\t\t\t\t{CREW_TARGET} /* IcyStraitCrew */,\n",
    )
    text = text.replace(
        "\t\t\t\t\t904EC43069525F78E67530F2 = {\n"
        "\t\t\t\t\t\tCreatedOnToolsVersion = 15.4;\n"
        "\t\t\t\t\t\tTestTargetID = B902F7C2327297FC583709E1;\n"
        "\t\t\t\t\t};",
        "\t\t\t\t\t904EC43069525F78E67530F2 = {\n"
        "\t\t\t\t\t\tCreatedOnToolsVersion = 15.4;\n"
        "\t\t\t\t\t\tTestTargetID = B902F7C2327297FC583709E1;\n"
        "\t\t\t\t\t};\n"
        f"\t\t\t\t\t{CREW_TARGET} = {{\n"
        "\t\t\t\t\t\tCreatedOnToolsVersion = 15.4;\n"
        "\t\t\t\t\t};",
    )

    frameworks = f"""
		{CREW_FRAMEWORKS} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
"""
    text = text.replace("/* End PBXFrameworksBuildPhase section */", frameworks + "/* End PBXFrameworksBuildPhase section */")

    resources = f"""
		{CREW_RESOURCES} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{F['CrewAssets'][2]} /* Assets.xcassets in Resources */,
				{CUSTOMER_ASSETS_CREW} /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
"""
    text = text.replace("/* End PBXResourcesBuildPhase section */", resources + "/* End PBXResourcesBuildPhase section */")

    sources_phase = f"""
		{CREW_SOURCES} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{crew_sources}			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
"""
    text = text.replace("/* End PBXSourcesBuildPhase section */", sources_phase + "/* End PBXSourcesBuildPhase section */")

    text = text.replace(
        "\t\t\t\t541DFA80D782ED4B5F712400 /* StaffRosterView.swift in Sources */,\n",
        "\t\t\t\t541DFA80D782ED4B5F712400 /* StaffRosterView.swift in Sources */,\n" + customer_sources,
    )
    text = text.replace(
        "\t\t\t\t037D2F7138EB7FF55630A231 /* CapacityCalculatorTests.swift in Sources */,\n",
        "\t\t\t\t037D2F7138EB7FF55630A231 /* CapacityCalculatorTests.swift in Sources */,\n" + test_sources,
    )

    configs = f"""
		{CREW_DEBUG} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = IcyStraitCrew/IcyStraitCrew.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "\\"IcyStraitCrew/Preview Content\\"";
				DEVELOPMENT_TEAM = 3RJHN4N474;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = IcyStraitCrew/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = "Icy Strait Crew";
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.navigation";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.icystrait.crew;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = targeted;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		{CREW_RELEASE} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = IcyStraitCrew/IcyStraitCrew.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "\\"IcyStraitCrew/Preview Content\\"";
				DEVELOPMENT_TEAM = 3RJHN4N474;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = IcyStraitCrew/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = "Icy Strait Crew";
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.navigation";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.icystrait.crew;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = targeted;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
"""
    text = text.replace("/* End XCBuildConfiguration section */", configs + "/* End XCBuildConfiguration section */")

    cfg_list = f"""
		{CREW_CFG_LIST} /* Build configuration list for PBXNativeTarget "IcyStraitCrew" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{CREW_DEBUG} /* Debug */,
				{CREW_RELEASE} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
"""
    text = text.replace("/* End XCConfigurationList section */", cfg_list + "/* End XCConfigurationList section */")

    PBX.write_text(text)
    print("Patched", PBX)


if __name__ == "__main__":
    main()
