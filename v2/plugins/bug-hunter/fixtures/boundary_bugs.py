"""Score statistics helpers."""


def average(scores):
    return sum(scores) / len(scores)


def top_n(scores, n):
    ordered = sorted(scores, reverse=True)
    return [ordered[i] for i in range(1, n)]


def label_for(score):
    if score > 90:
        return "excellent"
    if score > 50:
        return "ok"


def first_initial(name):
    return name[0].upper()
