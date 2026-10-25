#!/usr/bin/env python3
"""Create a Python project from the devtools-cli templates."""

import re
import shutil
import subprocess
import sys
from pathlib import Path


# --- Configuration ---
PYTHON_VERSION = "3.14"
AUTHOR = "Gaétan Muck"
INIT_GIT = False
CREATE_SRC = True
CREATE_TESTS = True
# ---------------------

RESET = "\033[0m"
BOLD = "\033[1m"
CYAN = "\033[96m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
MAGENTA = "\033[95m"
DIM = "\033[2m"


def ask(prompt: str, default: str) -> str:
    """Ask for a value, using the default when empty."""
    value = input(f"  {CYAN}›{RESET} {prompt} {DIM}[{default}]{RESET}: ")
    return value.strip() or default


def main() -> None:
    project_dir = Path.cwd()
    folder_name = project_dir.name
    script_dir = Path(__file__).resolve().parent
    defaults_dir = script_dir.parent / "defaults"

    pyproject_template = defaults_dir / "pyproject.toml"
    gitignore_template = defaults_dir / ".gitignore"

    for template in (pyproject_template, gitignore_template):
        if not template.is_file():
            sys.exit(f"\n{YELLOW}✗ Missing template: {template}{RESET}")

    print(f"""
{MAGENTA}╭──────────────────────────────────────╮
│                                      │
│    ⚡  PYTHON PROJECT GENERATOR      │
│                                      │
╰──────────────────────────────────────╯{RESET}

{DIM}Let's build something cool.{RESET}
""")

    project_name = ask("Project name", folder_name)
    project_description = ask("Project description", "")
    init_git = ask("Initialize a Git repository? (Y/n)", "Y").lower() in ("y", "yes")
    origin_url = ask("Git origin URL (optional)", "") if init_git else ""

    # Convert the display name to a valid distribution name.
    distribution_name = re.sub(
        r"[^a-zA-Z0-9._-]+", "-", project_name
    ).strip("-").lower()

    if not distribution_name:
        sys.exit(f"\n{YELLOW}✗ Invalid project name.{RESET}")

    package_name = re.sub(r"[-.]+", "_", distribution_name)

    print(f"""
{DIM}──────────────────────────────────────{RESET}
  {BOLD}Project{RESET}    {GREEN}{project_name}{RESET}
  {BOLD}Package{RESET}    {package_name}
  {BOLD}Python{RESET}     {PYTHON_VERSION}
  {BOLD}Location{RESET}   {project_dir}
{DIM}──────────────────────────────────────{RESET}
""")

    if ask("Ready to create it? (Y/n)", "Y").lower() not in ("y", "yes"):
        print(f"\n{YELLOW}✗ Cancelled. Happy coding!{RESET}")
        return

    print(f"\n{CYAN}⚙ Initializing project...{RESET}\n")

    # Initialize the project using uv.
    subprocess.run(
        [
            "uv", "init",
            "--name", distribution_name,
            "--description", project_description,
            "--python", PYTHON_VERSION,
            "--vcs", "none",
        ],
        check=True,
    )

    # Install the project templates.
    shutil.copy2(pyproject_template, "pyproject.toml")
    shutil.copy2(gitignore_template, ".gitignore")

    # Update the project name in the copied TOML template.
    pyproject_path = Path("pyproject.toml")
    content = pyproject_path.read_text()

    pattern = re.compile(
        r'(?ms)(^\[project\]\s*\n.*?)(?=^\[|\Z)'
    )
    match = pattern.search(content)

    if not match:
        sys.exit(f"{YELLOW}✗ Missing [project] section in pyproject.toml.{RESET}")

    section = match.group(1)
    name_pattern = re.compile(r'^name\s*=\s*["\'][^"\']*["\']\s*$', re.M)

    if not name_pattern.search(section):
        sys.exit(f"{YELLOW}✗ Missing project name in [project].{RESET}")

    section = name_pattern.sub(
        f'name = "{distribution_name}"', section, count=1
    )
    content = content[:match.start()] + section + content[match.end():]

    # Add author metadata when configured.
    if AUTHOR:
        author = AUTHOR.replace("\\", "\\\\").replace('"', '\\"')
        section_match = pattern.search(content)
        if section_match is None:
            sys.exit(f"{YELLOW}✗ Missing [project] section in pyproject.toml.{RESET}")
        section = section_match.group(1)
        section = section.replace(
            "[project]\n",
            f'[project]\nauthors = [{{ name = "{author}" }}]\n',
            1,
        )
        content = (
            content[:section_match.start()]
            + section
            + content[section_match.end():]
        )

    pyproject_path.write_text(content)

    # Create the source package.
    if CREATE_SRC:
        package_dir = Path(".") / package_name
        package_dir.mkdir(parents=True, exist_ok=True)
        (package_dir / "__init__.py").touch()

        main_file = Path("main.py")
        if main_file.is_file():
            shutil.move(str(main_file), str(package_dir / "main.py"))

    # Create a minimal test suite.
    if CREATE_TESTS:
        tests_dir = Path("tests")
        tests_dir.mkdir(exist_ok=True)

        (tests_dir / "test_main.py").write_text(
            "def test_placeholder():\n"
            "    assert True\n"
        )

    # Install dependencies.
    subprocess.run(["uv", "sync"], check=True)

    # Initialize Git if requested.
    if init_git:
        subprocess.run(["git", "init"], check=True)
        print(f"{GREEN}✓ Git repository initialized.{RESET}")
        if origin_url:
            subprocess.run(["git", "remote", "add", "origin", origin_url], check=True)
            print(f"{GREEN}✓ Git remote 'origin' set to: {origin_url}{RESET}")

    print(f"""
{GREEN}{BOLD}╭──────────────────────────────────────╮
│  ✓ Project created successfully!     │
╰──────────────────────────────────────╯{RESET}
""")


if __name__ == "__main__":
    main()