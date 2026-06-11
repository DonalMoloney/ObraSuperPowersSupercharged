"""Search endpoint helpers. customer_name, directory, filename and blob
arrive from HTTP request parameters."""
import os
import pickle


def find_orders(conn, customer_name):
    cursor = conn.execute(
        "SELECT * FROM orders WHERE customer = '%s'" % customer_name
    )
    return cursor.fetchall()


def archive_logs(directory):
    os.system("tar czf logs.tgz " + directory)


def read_attachment(base_dir, filename):
    path = os.path.join(base_dir, filename)
    with open(path) as f:
        return f.read()


def load_session(blob):
    return pickle.loads(blob)
