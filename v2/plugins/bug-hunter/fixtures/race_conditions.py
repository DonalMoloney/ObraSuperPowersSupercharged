"""Download cache helpers used by the threaded fetch pool."""
import os
import threading

_cache = None
download_count = 0


def get_cache():
    global _cache
    if _cache is None:
        _cache = {}
    return _cache


def record_download():
    global download_count
    download_count += 1


def fetch_all(urls, fetch_one):
    threads = [threading.Thread(target=fetch_one, args=(u,)) for u in urls]
    for t in threads:
        t.start()
    for t in threads:
        t.join()


def write_once(path, data):
    if not os.path.exists(path):
        with open(path, "w") as f:
            f.write(data)
