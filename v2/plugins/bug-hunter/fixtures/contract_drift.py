"""User lookup helpers."""


def sorted_names(users):
    """Return the user names sorted alphabetically."""
    return [u["name"] for u in users]


def find_user(users, user_id):
    """Return the user dict for user_id, or raise KeyError if not found."""
    for u in users:
        if u["id"] == user_id:
            return u
    return None


def normalize(name, strict=True):
    if strict:
        return name.strip().lower()
    if not strict:
        return name.strip()
    return name
