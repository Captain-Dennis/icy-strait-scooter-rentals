#!/usr/bin/env python3
"""Verify IcyStraitCrew has the types its compiled sources need, without
changing the customer IcyStraitScooterRentals compile list.

Linux-checkable stand-in for xcodebuild (no Xcode in this environment).
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / "IcyStraitScooterRentals.xcodeproj" / "project.pbxproj"

CUSTOMER_SOURCES = "68794D95D50DF8ED5158D413"
CREW_SOURCES = "C0DE03000000000000000003"

# Files Crew already compiled that name these types, plus Shared/.
REQUIRED_CREW = {
    "Scooter.swift",  # SharedComponents.ScooterDetailCard
    "CapacityCalculator.swift",  # Rental.snapshot() -> RentalSnapshot
    "POSProvider.swift",  # AppPreferences.POSEnvironment
    "MockPOSProvider.swift",
    "SharedComponents.swift",
    "Rental.swift",
    "AppPreferences.swift",
    "RentalLifecycleEvent.swift",
    "CrewBoard.swift",
    "CrewAlertCopy.swift",
    "SharedLotStore.swift",
    "HTTPLotStore.swift",
    "SharedPipeConfig.swift",
    "IcyStraitCrewApp.swift",
}

# Customer compile list must keep these (ios-testflight / IcyStraitScooterRentals).
REQUIRED_CUSTOMER = {
    "IcyStraitScooterRentalsApp.swift",
    "RootView.swift",
    "Scooter.swift",
    "Rental.swift",
    "CapacityCalculator.swift",
    "POSProvider.swift",
    "MockPOSProvider.swift",
    "AppPreferences.swift",
    "SharedComponents.swift",
    "FleetSeeder.swift",
    "RentalOperations.swift",
    "CheckoutFlowView.swift",
    "ScanTabView.swift",
}


def sources_for(text: str, phase_id: str) -> set[str]:
    block = re.search(
        rf"{phase_id} /\* Sources \*/ = \{{.*?files = \((.*?)\);",
        text,
        re.S,
    )
    if not block:
        raise SystemExit(f"Sources phase {phase_id} not found")
    return set(re.findall(r"/\* ([A-Za-z0-9_.]+) in Sources \*/", block.group(1)))


def main() -> int:
    text = PBX.read_text()
    crew = sources_for(text, CREW_SOURCES)
    customer = sources_for(text, CUSTOMER_SOURCES)

    errors: list[str] = []
    missing_crew = sorted(REQUIRED_CREW - crew)
    if missing_crew:
        errors.append(f"IcyStraitCrew missing sources: {missing_crew}")

    missing_customer = sorted(REQUIRED_CUSTOMER - customer)
    if missing_customer:
        errors.append(f"IcyStraitScooterRentals missing sources: {missing_customer}")

    leaked_into_customer = sorted(
        {
            "IcyStraitCrewApp.swift",
            "CrewRootView.swift",
            "CrewBoardView.swift",
            "CrewSignInView.swift",
        }
        & customer
    )
    if leaked_into_customer:
        errors.append(f"Crew-only files leaked into customer target: {leaked_into_customer}")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1

    print(f"IcyStraitCrew sources: {len(crew)}")
    print(f"IcyStraitScooterRentals sources: {len(customer)}")
    print("Target membership OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
