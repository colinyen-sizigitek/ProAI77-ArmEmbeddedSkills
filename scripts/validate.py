#!/usr/bin/env python3
"""
Validation script for proai77-embedded-skills suite.
Verifies plugin.json, YAML frontmatters, required references, scripts, and python syntax.
"""
import os
import sys
import json
import re

def check_file(path, desc):
    if not os.path.exists(path):
        print(f"[FAIL] Missing {desc}: {path}")
        return False
    print(f"[PASS] Found {desc}: {os.path.basename(path)}")
    return True

def validate_frontmatter(skill_md_path):
    with open(skill_md_path, "r", encoding="utf-8") as f:
        content = f.read()
    m = re.match(r"^---\n(.*?)\n---\n", content, re.DOTALL)
    if not m:
        print(f"[FAIL] Missing frontmatter in: {skill_md_path}")
        return False
    fm = m.group(1)
    required = ["name:", "description:"]
    for req in required:
        if req not in fm:
            print(f"[FAIL] Missing '{req}' in frontmatter: {skill_md_path}")
            return False
    return True

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    print(f"Validating ProAI77 Embedded Skills Suite at: {root}\n")
    errors = 0

    # 1. Check root files
    if not check_file(os.path.join(root, "plugin.json"), "plugin.json"): errors += 1
    if not check_file(os.path.join(root, "README.md"), "README.md"): errors += 1
    if not check_file(os.path.join(root, "rules", "AGENTS.md"), "rules/AGENTS.md"): errors += 1
    if not check_file(os.path.join(root, "shared", "AGENTS.proai77.md"), "shared/AGENTS.proai77.md"): errors += 1
    if not check_file(os.path.join(root, "docs", "DESIGN.md"), "docs/DESIGN.md"): errors += 1
    if not check_file(os.path.join(root, "docs", "ARM_PERFORMANCE_GUIDELINES.md"), "docs/ARM_PERFORMANCE_GUIDELINES.md"): errors += 1
    if not check_file(os.path.join(root, "docs", "DEBUG_AND_VERIFICATION.md"), "docs/DEBUG_AND_VERIFICATION.md"): errors += 1

    # 2. Check skills
    skills_dir = os.path.join(root, "skills")
    if not os.path.exists(skills_dir):
        print(f"[FAIL] Skills dir missing: {skills_dir}")
        return 1

    skill_folders = [f for f in os.listdir(skills_dir) if os.path.isdir(os.path.join(skills_dir, f))]
    print(f"\nFound {len(skill_folders)} skills:")
    for sf in skill_folders:
        s_path = os.path.join(skills_dir, sf)
        skill_md = os.path.join(s_path, "SKILL.md")
        if not check_file(skill_md, f"{sf}/SKILL.md"):
            errors += 1
        else:
            if not validate_frontmatter(skill_md):
                errors += 1

    # 3. Syntax check python scripts
    print("\nChecking Python syntax in scripts...")
    for dirpath, _, filenames in os.walk(root):
        for fn in filenames:
            if fn.endswith(".py"):
                fpath = os.path.join(dirpath, fn)
                try:
                    with open(fpath, "r", encoding="utf-8") as pf:
                        compile(pf.read(), fpath, "exec")
                    print(f"[PASS] Syntax OK: {os.path.relpath(fpath, root)}")
                except Exception as e:
                    print(f"[FAIL] Syntax Error in {fpath}: {e}")
                    errors += 1

    print("\n" + "=" * 50)
    if errors == 0:
        print("[SUCCESS] All files and validations passed!")
        return 0
    else:
        print(f"[FAILED] Total validation errors: {errors}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
