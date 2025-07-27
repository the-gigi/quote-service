#!/usr/bin/env python3
"""
Generate Dockerfile from template by reading dependencies from pyproject.toml
"""
import tomllib
from pathlib import Path

def main():
    # Read pyproject.toml
    pyproject_path = Path("pyproject.toml")
    if not pyproject_path.exists():
        raise FileNotFoundError("pyproject.toml not found")
    
    with open(pyproject_path, "rb") as f:
        pyproject = tomllib.load(f)
    
    # Extract dependencies
    dependencies = pyproject.get("project", {}).get("dependencies", [])
    if not dependencies:
        raise ValueError("No dependencies found in pyproject.toml")
    
    # Format dependencies for pip install (escape and join with backslashes for multi-line)
    formatted_deps = " \\\n    ".join(f'"{dep}"' for dep in dependencies)
    
    # Read template
    template_path = Path("Dockerfile.template")
    if not template_path.exists():
        raise FileNotFoundError("Dockerfile.template not found")
    
    with open(template_path, "r") as f:
        template = f.read()
    
    # Replace placeholder
    dockerfile_content = template.replace("{{DEPENDENCIES}}", formatted_deps)
    
    # Write Dockerfile
    with open("Dockerfile", "w") as f:
        f.write(dockerfile_content)
    
    print(f"✅ Generated Dockerfile with {len(dependencies)} dependencies:")
    for dep in dependencies:
        print(f"  • {dep}")

if __name__ == "__main__":
    main()