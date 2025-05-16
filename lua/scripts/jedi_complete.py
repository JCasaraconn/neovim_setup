import jedi
import traceback
import json
import os
import sys

# Suppress TensorFlow and other verbose logs
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'  # Error only
sys.stderr = open(os.devnull, 'w')  # Redirect all stderr to null


def import_module_by_name(name):
    import importlib
    try:
        return importlib.import_module(name)
    except ImportError:
        return None


def get_module_completions(module_path: str):
    # Extract the top-level module name to import
    top_module = module_path.split('.')[0]
    module_obj = import_module_by_name(top_module)

    # Provide a namespace dict with the imported module (if available)
    namespaces = [{top_module: module_obj}] if module_obj else [{}]

    try:
        script = jedi.Interpreter(module_path, namespaces=namespaces)
        completions = script.complete()
        return [
            {'name': c.name, 'type': c.type, 'description': c.description}
            for c in completions
        ]
    except Exception as e:
        return {
            'error': str(e),
            'traceback': traceback.format_exc()
        }


if __name__ == "__main__":
    module_path = sys.argv[1] if len(sys.argv) > 1 else ''
    try:
        results = get_module_completions(module_path)
    except Exception as e:
        results = {
            'error': str(e),
            'traceback': traceback.format_exc()
        }
    print(json.dumps(results, indent=2))
