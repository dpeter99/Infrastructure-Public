from pathlib import Path
from typing import Any

import makejinja
import re

# Return the stripped contents of file_path, rejecting a missing or empty file
def _read_stripped(file_path: str) -> str:
    try:
        content = Path(file_path).read_text().strip()
    except FileNotFoundError:
        raise FileNotFoundError(f"File not found: {file_path}") from None
    if not content:
        raise ValueError(f"{file_path} is empty")
    return content

# Return the age public or private key from age.key
def age_key(key_type: str, file_path: str = 'age.key') -> str:
    file_content = _read_stripped(file_path)
    if key_type == 'public':
        # Matches both classic (age1...) and post-quantum (age1pq1...) recipients
        key_match = re.search(r"# public key: (age1[\w]+)", file_content)
        if not key_match:
            raise ValueError("Could not find public key in the age key file.")
        return key_match.group(1)
    elif key_type == 'private':
        # (?:PQ-)? matches post-quantum identities (AGE-SECRET-KEY-PQ-1...) as well as classic ones
        key_match = re.search(r"(AGE-SECRET-KEY-(?:PQ-)?1[\w]+)", file_content)
        if not key_match:
            raise ValueError("Could not find private key in the age key file.")
        return key_match.group(1)
    else:
        raise ValueError("Invalid key type. Use 'public' or 'private'.")


class Plugin(makejinja.plugin.Plugin):
    def __init__(self, data: dict[str, Any]):
        self._data = data


    def functions(self) -> makejinja.plugin.Functions:
        return [
            age_key
        ]