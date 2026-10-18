"""Rebuild the Godot resource from the editable UTF-8 language catalog."""
import json
from pathlib import Path

directory = Path(__file__).resolve().parent
messages = json.loads((directory / "strings.json").read_text(encoding="utf-8"))
if not isinstance(messages, dict) or not all(
    isinstance(key, str) and isinstance(value, str) for key, value in messages.items()
):
    raise ValueError("The catalog must map source strings to English strings")
header = (
    '[gd_resource type="Resource" load_steps=2 format=3]\n\n'
    '[ext_resource type="Script" path="res://localization/catalog_resource.gd" id="1"]\n\n'
    '[resource]\nscript = ExtResource("1")\nmessages = '
)
(directory / "strings.tres").write_text(
    header + json.dumps(messages, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
)
print(f"Compiled {len(messages)} bilingual messages")
