"""Inventory sync helpers."""
import json
import subprocess


def load_config(path):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return {}


def sync_inventory(items):
    failed = []
    for item in items:
        try:
            push_item(item)
        except ConnectionError:
            pass
    return failed


def push_item(item):
    subprocess.run(["sync-tool", item["id"]])
    return True
