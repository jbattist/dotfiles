"""Retry an unresolved bare SSH hostname with the local `.home` suffix.

Examples:
    ssh ember       -> ssh ember.home
    ssh joe@ember   -> ssh joe@ember.home
    ssh -p 2222 joe@ember -> ssh -p 2222 joe@ember.home
"""

import re


# Short SSH options whose value may be supplied as the next argument.
_SSH_OPTIONS_WITH_VALUES = set("BbcDEeFIiJLlmOopQRSWw")

_RESOLUTION_FAILURE = re.compile(
    r"(?:ssh: )?Could not resolve hostname (?P<host>[^: ]+):",
    re.IGNORECASE,
)


def _destination(command):
    """Return the destination token from an ssh command, if identifiable."""
    parts = command.script_parts
    if not parts or parts[0].rsplit("/", 1)[-1] != "ssh":
        return None

    index = 1
    while index < len(parts):
        part = parts[index]

        if part == "--":
            return parts[index + 1] if index + 1 < len(parts) else None

        if not part.startswith("-") or part == "-":
            return part

        option = part[1:2]
        if option in _SSH_OPTIONS_WITH_VALUES and len(part) == 2:
            index += 2
        else:
            # Flags such as -v, combined flags such as -vv, and options with
            # attached values such as -p2222 consume only this token.
            index += 1

    return None


def _bare_hostname(destination):
    """Extract a hostname only when it is suitable for appending `.home`."""
    if not destination:
        return None

    hostname = destination.rsplit("@", 1)[-1]

    # Exclude FQDNs, IPv4/IPv6 addresses, wildcard-like names, and malformed
    # destinations. Hyphens and underscores are accepted for homelab names.
    if "." in hostname or ":" in hostname:
        return None
    if not re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9_-]*", hostname):
        return None
    if hostname.isdigit():
        return None

    return hostname


def match(command):
    destination = _destination(command)
    hostname = _bare_hostname(destination)
    failure = _RESOLUTION_FAILURE.search(command.output or "")

    return bool(
        hostname
        and failure
        and failure.group("host").lower() == hostname.lower()
    )


def get_new_command(command):
    destination = _destination(command)
    hostname = _bare_hostname(destination)
    if destination is None or hostname is None:
        return command.script

    corrected = destination[: -len(hostname)] + hostname + ".home"

    # Replace only the parsed destination token, preserving options, remote
    # commands, and an optional user@ prefix exactly as entered.
    parts = command.script_parts
    destination_index = parts.index(destination)
    start = 0
    for index, part in enumerate(parts):
        if index == destination_index:
            break
        start = command.script.find(part, start) + len(part)

    token_start = command.script.find(destination, start)
    token_end = token_start + len(destination)
    return command.script[:token_start] + corrected + command.script[token_end:]


priority = 900
requires_output = True
