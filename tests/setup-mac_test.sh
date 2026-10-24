#!/usr/bin/env bash

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/setup-mac.sh"

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [ "$actual" != "$expected" ]; then
        echo "FAIL: $message"
        echo "  expected: $expected"
        echo "  actual:   $actual"
        exit 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    case "$haystack" in
        *"$needle"*) ;;
        *)
            echo "FAIL: $message"
            echo "  expected to contain: $needle"
            echo "  actual:             $haystack"
            exit 1
            ;;
    esac
}

assert_success() {
    local status="$1"
    local message="$2"

    if [ "$status" -ne 0 ]; then
        echo "FAIL: $message"
        echo "  status: $status"
        exit 1
    fi
}

test_parse_run_mode() {
    assert_equals "wizard" "$(parse_run_mode -w)" "parse_run_mode should detect wizard mode"
    assert_equals "manual" "$(parse_run_mode -m)" "parse_run_mode should detect manual mode"
    assert_equals "auto" "$(parse_run_mode "")" "parse_run_mode should default to auto mode"
}

test_skip_step_auto_mode() {
    run_mode="auto"
    set +e
    skip_step "Auto test"
    local status=$?
    set -e
    assert_equals 1 "$status" "skip_step should return 1 in auto mode"
}

test_skip_step_wizard_mode_yes() {
    run_mode="wizard"
    local output
    set +e
    output=$(printf 'y\n' | skip_step "Wizard test" 2>&1)
    local status=$?
    set -e
    assert_success "$status" "skip_step should succeed when user chooses to skip"
    assert_contains "$output" "Skipping Wizard test" "skip_step should print the skip message"
}

test_main_dispatches_manual_mode() {
    run_sequence() {
        echo "unexpected-auto-path"
    }
    manual_menu() {
        echo "manual-menu-called"
    }

    local output
    output=$(main -m 2>&1)
    assert_contains "$output" "manual-menu-called" "main should call manual_menu in manual mode"
}

test_main_dispatches_auto_mode() {
    run_sequence() {
        echo "auto-sequence-called"
    }
    manual_menu() {
        echo "unexpected-manual-path"
    }

    local output
    output=$(main 2>&1)
    assert_contains "$output" "Running setup script in auto mode..." "main should announce auto mode"
    assert_contains "$output" "auto-sequence-called" "main should run the auto sequence"
}

test_main_help() {
    local output
    output=$(main -h 2>&1)
    assert_contains "$output" "Usage: ./setup-mac.sh" "main help should display script usage"
}

test_setup_essential_programs_installs_programs() {
    run_mode="auto"
    brew() {
        echo "brew $*"
    }

    set +e
    local output
    output=$(setup_essential_programs 2>&1)
    local status=$?
    set -e

    assert_success "$status" "setup_essential_programs should succeed when brew is mocked"
    assert_contains "$output" "Setting up VS Code..." "setup_essential_programs should install VS Code"
    assert_contains "$output" "brew install --cask visual-studio-code" "setup_essential_programs should invoke brew for VS Code"
    assert_contains "$output" "Setting up Postman..." "setup_essential_programs should install Postman"
    assert_contains "$output" "brew install --cask postman" "setup_essential_programs should invoke brew for Postman"
    assert_contains "$output" "Setting up Free Download Manager..." "setup_essential_programs should install Free Download Manager"
    assert_contains "$output" "brew install --cask free-download-manager" "setup_essential_programs should invoke brew for Free Download Manager"
}

run_test() {
    local test_name="$1"

    echo "Running $test_name"
    "$test_name"
}

run_test test_parse_run_mode
run_test test_skip_step_auto_mode
run_test test_skip_step_wizard_mode_yes
run_test test_main_dispatches_manual_mode
run_test test_main_dispatches_auto_mode
run_test test_main_help
run_test test_setup_essential_programs_installs_programs

echo "All setup-mac tests passed."
