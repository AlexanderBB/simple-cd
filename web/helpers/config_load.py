import json
import sys


def load_json(file_path):
    try:
        with open(file_path, 'r') as file:
            data = json.load(file)
            return data
    except Exception as e:
        print(f"Error loading JSON file: {e}")
        sys.exit(1)


def generate_export_commands(json_data):
    export_commands = []
    for key, value in json_data.items():
        export_commands.append(f"export TF_VAR_{key}='{value}'")
    return export_commands


def main(variables_file: str):
    json_data = load_json(variables_file)
    export_commands = generate_export_commands(json_data)
    for command in export_commands:
        print(command)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python export_tf_vars.py <path_to_json_file>")
        sys.exit(1)

    json_file_path = sys.argv[1]
    main(json_file_path)
