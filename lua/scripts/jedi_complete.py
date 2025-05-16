# ~/.config/nvim/lua/scripts/jedi_complete.py
import contextlib
import importlib
import io
import json
import os
import sys
import types

import jedi

LOGGING = False


@contextlib.contextmanager
def suppress_stdout():
    with contextlib.redirect_stdout(io.StringIO()):
        yield


# Suppress TensorFlow and other verbose logs
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'  # Error only
sys.stderr = open(os.devnull, 'w')  # Redirect all stderr to null


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


project_root = find_project_root()
if project_root not in sys.path:
    sys.path.insert(0, project_root)


if LOGGING:
    with open("/tmp/jedi_env_debug.log", "w") as f:
        f.write("PYTHONPATH=" + os.environ.get("PYTHONPATH", "") + "\n")
        f.write("sys.path:\n" + "\n".join(os.sys.path))


def import_module_by_name(name):
    try:
        return importlib.import_module(name)
    except ImportError:
        return None


def get_filtered_completions_from_globals(globals_dict, target_module_name):
    completions = []
    for name, obj in globals_dict.items():
        if name.startswith('_'):
            continue

        module_of_obj = getattr(obj, '__module__', None)

        # Allow modules *only* if they are part of the target package
        if isinstance(obj, types.ModuleType):
            if obj.__name__.startswith(target_module_name):
                completions.append({
                    'name': name,
                    'type': 'module',
                    'module': obj.__name__,
                    'description': f"module: {obj.__name__}",
                })
            continue

        # Allow functions/classes defined in the target package
        if module_of_obj and module_of_obj.startswith(target_module_name):
            completions.append({
                'name': name,
                'type': type(obj).__name__,
                'module': module_of_obj,
                'description': str(obj),
            })

    return completions


def get_completions(module_path: str):
    """
    Get filtered completions from the given Python module path.
    Returns only user-defined symbols and filters out built-ins and imported modules.
    """
    module_path = module_path.rstrip('.')
    try:
        module = importlib.import_module(module_path)
        globals_dict = module.__dict__
        completions = get_filtered_completions_from_globals(
            globals_dict, module_path)
    except Exception as e:
        print(f"Error importing or inspecting module: {e}")
        completions = []

    return completions


def main():
    for line in sys.stdin:
        module_path = line.strip()
        results = get_completions(module_path)
        print(json.dumps(results), flush=True)


if __name__ == "__main__":
    main()
