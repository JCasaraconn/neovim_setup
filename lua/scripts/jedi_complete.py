# ~/.config/nvim/lua/scripts/jedi_complete.py
import importlib
import json
import os
import sys

import jedi

# Suppress TensorFlow and other verbose logs
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'  # Error only
sys.stderr = open(os.devnull, 'w')  # Redirect all stderr to null


def import_module_by_name(name):
    try:
        return importlib.import_module(name)
    except ImportError:
        return None


def get_completions(module_path: str):
    top_module = module_path.split('.')[0]
    module_obj = import_module_by_name(top_module)
    namespaces = [{top_module: module_obj}] if module_obj else [{}]

    try:
        script = jedi.Interpreter(module_path, namespaces=namespaces)
        completions = script.complete()
    except Exception:
        completions = []

    return [
        {'name': c.name, 'type': c.type, 'description': c.description}
        for c in completions
    ]


def main():
    for line in sys.stdin:
        module_path = line.strip()
        results = get_completions(module_path)
        print(json.dumps(results), flush=True)


if __name__ == "__main__":
    main()
