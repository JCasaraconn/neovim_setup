# ~/.config/nvim/lua/scripts/jedi_complete.py
import json
import os
import sys
from functools import lru_cache

import jedi

LOGGING = False


def find_project_root(start_path=None):
    if start_path is None:
        start_path = os.getcwd()

    current = os.path.abspath(start_path)
    while current != os.path.dirname(current):
        for marker in ['pyproject.toml', 'setup.py', '.git']:
            if os.path.exists(os.path.join(current, marker)):
                return current
        current = os.path.dirname(current)
    return start_path  # fallback


def is_private_method(text: str) -> bool:
    if text.startswith('_'):
        return True
    return False


def is_dunder_method(text: str) -> bool:
    if text.startswith('__'):
        return True
    return False


def passes_filters(text: str) -> bool:
    if not is_private_method(text) and not is_dunder_method(text):
        return True
    return False


def format_yaml_snippet(name, params):
    lines = [f"{name}:"]
    for i, param in enumerate(params, 1):
        if param.name == "self":
            continue  # skip self for methods
        lines.append(f"    {param.name}: ${{{i}}}")
    return "\n".join(lines)


@lru_cache(maxsize=None)
def get_completions(text: str):
    text = text.rstrip('.')
    split_text = text.rsplit('.', 1)
    code = f"import {split_text[0]}\n{text}."
    line = 2
    column = len(text) + 1
    script = jedi.Script(code=code, path=None)
    completions = script.complete(line, column)
    json_output = []
    for c in completions:
        if not passes_filters(c.name):
            continue
        docstring = c.docstring(raw=True)
        signatures = c.get_signatures()

        snippet = c.name
        if signatures:
            sig = signatures[0]
            snippet = format_yaml_snippet(c.name, sig.params)

        json_output.append({
            "name": c.name,
            "type": c.type,
            "module": c.module_name,
            "description": str(c.description),
            "docstring": docstring,
            "signature": snippet,
        })
    return json_output


def main():
    project_root = find_project_root()
    if project_root not in sys.path:
        sys.path.insert(0, project_root)

    if LOGGING:
        with open("/tmp/jedi_env_debug.log", "w") as f:
            f.write("PYTHONPATH=" + os.environ.get("PYTHONPATH", "") + "\n")
            f.write("sys.path:\n" + "\n".join(os.sys.path))

    for line in sys.stdin:
        module_path = line.strip().split(' ')[-1]
        results = get_completions(module_path)
        print(json.dumps(results), flush=True)


if __name__ == "__main__":
    main()
