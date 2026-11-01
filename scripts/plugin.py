from collections.abc import Mapping
from pathlib import Path
from typing import Any

import base64
import json
import makejinja
import re
import subprocess
import yaml

# Secret cluster values (domain, ...); sops-encrypted, keys visible, committed.
SECRETS_FILE = 'cluster.secrets.sops.yaml'

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


# Resolve a 1Password secret reference (op://vault/item/field) with the op CLI
def op_read(reference: str) -> str:
    if not reference.startswith('op://'):
        raise ValueError(f"Not a 1Password secret reference: {reference!r}")
    result = subprocess.run(['op', 'read', '--no-newline', reference], capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"op read {reference} failed: {result.stderr.strip()}")
    if not result.stdout:
        raise ValueError(f"op read {reference} returned nothing")
    return result.stdout


# Return a .dockerconfigjson document granting pull access to the registry
# that hosts oci_url (e.g. oci://ghcr.io/org/repo -> ghcr.io), with the
# username and token read from the given 1Password references.
def docker_config_json(oci_url: str, username_ref: str, token_ref: str) -> str:
    host = oci_url.removeprefix('oci://').split('/', 1)[0]
    if not host:
        raise ValueError(f"Could not determine registry host from {oci_url!r}")
    username = op_read(username_ref)
    token = op_read(token_ref)
    auth = base64.b64encode(f"{username}:{token}".encode()).decode()
    return json.dumps({'auths': {host: {'username': username, 'password': token, 'auth': auth}}})


# Return the Flux webhook token from flux-webhook-token.txt
def webhook_token(file_path: str = 'flux-webhook-token.txt') -> str:
    return _read_stripped(file_path)


# Run sops with args (and optional stdin), returning stdout
def _sops(args: list[str], stdin: str | None = None) -> str:
    result = subprocess.run(['sops', *args], input=stdin, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"sops {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout


# Decrypt the root secrets file into a mapping (needs SOPS_AGE_KEY_FILE / age.key)
def load_secrets(file_path: str = SECRETS_FILE) -> dict[str, Any]:
    if not Path(file_path).exists():
        raise FileNotFoundError(f"{file_path} not found, run: just init")
    data = json.loads(_sops(['--decrypt', '--output-type', 'json', file_path]))
    if not isinstance(data, dict) or not data:
        raise ValueError(f"{file_path} must be a non-empty mapping")
    return data


class Plugin(makejinja.plugin.Plugin):
    def __init__(self, *, data: Mapping[str, Any], **_: Any):
        self._data = data
        self._secrets = load_secrets()

    # Extra template global; `secrets` is therefore a reserved top-level name in cluster.toml.
    def data(self) -> makejinja.plugin.Data:
        return {'secrets': self._secrets}

    # Return the cluster.toml config as a YAML block, for embedding under a parent key
    def cluster_data(self, indent: int = 2) -> str:
        dumped = yaml.safe_dump(dict(self._data), default_flow_style=False, sort_keys=False).rstrip()
        return dumped.replace("\n", "\n" + " " * indent)

    def functions(self) -> makejinja.plugin.Functions:
        return [
            age_key,
            docker_config_json,
            webhook_token,
            self.cluster_data,
        ]
