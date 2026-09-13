#!/usr/bin/env python3
"""Build the word seed from published, commercially usable datasets.

Committed rather than run once by hand: the seed is derived data, and derived data that
cannot be regenerated is a liability. Re-running this produces the same SQL, so a source
correction is a rerun and a diff rather than an archaeology exercise.

Sources and their licences are documented in docs/DATA_SOURCES.md. Nothing here invents a
level, a transcription or a frequency: every field comes from one of those files or is
derived from them by a rule stated below.

Usage:  python3 scripts/build-word-seed.py            (downloads sources, writes the SQL)
"""

import collections
import csv
import io
import os
import re
import sys
import urllib.request

CEFR_URL = ("https://raw.githubusercontent.com/openlanguageprofiles/"
            "olp-en-cefrj/master/cefrj-vocabulary-profile-1.5.csv")
C1_URL = ("https://raw.githubusercontent.com/openlanguageprofiles/"
          "olp-en-cefrj/master/octanove-vocabulary-profile-c1c2-1.0.csv")
IPA_URL = ("https://raw.githubusercontent.com/open-dict-data/"
           "ipa-dict/master/data/en_US.txt")

OUT = os.path.join(os.path.dirname(__file__), "..", "backend",
                   "migrations", "seed", "001_words.sql")

# The sounds Voca can actually teach: every one of these has an articulation tip in the
# feedback generator, so a word chosen for it can always be explained. Ordered by how much
# trouble they give an Uzbek speaker, though the choice below is by rarity, not this order.
TIP_SOUNDS = ["θ", "ð", "æ", "ŋ", "v", "w", "r", "l", "ɪ", "iː"]

# This dictionary writes some sounds with different symbols than the tips are keyed by.
# Found by measurement, not assumption: r, l and iː each came back with ZERO words, which
# is impossible for English.
ALIAS = {"ɹ": "r", "ɫ": "l"}

CEFR_TO_DIFFICULTY = {
    "A1": "beginner", "A2": "beginner",
    "B1": "intermediate", "B2": "intermediate",
    "C1": "advanced", "C2": "advanced",
}

LEVEL_ORDER = {"A1": 0, "A2": 1, "B1": 2, "B2": 3, "C1": 4}


def fetch(url):
    sys.stderr.write(f"  {url.rsplit('/', 1)[-1]} ... ")
    with urllib.request.urlopen(url, timeout=120) as r:
        data = r.read().decode("utf-8")
    sys.stderr.write(f"{len(data):,} bayt\n")
    return data


def normalise(pron):
    body = pron.strip("/")
    for src, dst in ALIAS.items():
        body = body.replace(src, dst)
    return body


def sounds_in(body):
    """Every teachable sound the word contains."""
    found = set()
    for s in TIP_SOUNDS:
        if s == "iː":
            # This dictionary writes the long vowel as a plain i; ɪ is the short one.
            if re.search(r"i", body.replace("ɪ", "")):
                found.add("iː")
        elif s in body:
            found.add(s)
    return found


def load_levels(text, wanted, ipa):
    out = []
    for r in csv.DictReader(io.StringIO(text)):
        head = (r.get("headword") or "").strip()
        level = (r.get("CEFR") or "").strip()
        if level not in wanted or not head:
            continue
        # Real words only: no clitics ('m, 's), no multi-word entries, no slashed variants.
        if not re.fullmatch(r"[A-Za-z]+(?:[-'][A-Za-z]+)*", head) or len(head) < 2:
            continue
        key = head.lower()
        if key not in ipa:
            continue
        out.append({
            "word": key,
            "ipa": ipa[key],
            "level": level,
            "pos": (r.get("pos") or "").strip(),
        })
    return out


def main():
    sys.stderr.write("manbalar yuklanmoqda\n")
    ipa_raw = fetch(IPA_URL)
    cefr_raw = fetch(CEFR_URL)
    c1_raw = fetch(C1_URL)
    # No frequency source. The obvious candidate (google-10000-english) carries an
    # explicit warning against commercial use without an LDC licence, and Voca is a
    # commercial product — the same reason EFLLex was rejected. frequency_rank therefore
    # stays NULL until a properly licensed source is found, and ordering falls back to
    # CEFR level. A made-up rank would be worse than an absent one.

    ipa = {}
    for line in ipa_raw.splitlines():
        if "\t" not in line:
            continue
        w, p = line.split("\t", 1)
        ipa.setdefault(w.strip().lower(), p.split(",")[0].strip())

    rows = load_levels(cefr_raw, {"A1", "A2", "B1", "B2"}, ipa)
    rows += load_levels(c1_raw, {"C1"}, ipa)

    # One row per word, at the EASIEST level it appears at: that is when a learner first
    # meets it. This also collapses the same word listed under several parts of speech.
    best = {}
    for r in rows:
        cur = best.get(r["word"])
        if cur is None or LEVEL_ORDER[r["level"]] < LEVEL_ORDER[cur["level"]]:
            best[r["word"]] = r

    words = []
    for r in best.values():
        body = normalise(r["ipa"])
        present = sounds_in(body)
        if not present:
            # No sound Voca can teach, so it is not a pronunciation exercise.
            continue
        r["phonemes"] = sorted(present)
        r["body"] = body
        words.append(r)

    words.sort(key=lambda r: (LEVEL_ORDER[r["level"]], r["word"]))

    def q(v):
        return "NULL" if v is None or v == "" else "'" + str(v).replace("'", "''") + "'"

    def arr(items):
        return "ARRAY[" + ",".join(q(i) for i in items) + "]::text[]"

    with open(OUT, "w", encoding="utf-8") as f:
        f.write("-- GENERATED by scripts/build-word-seed.py. Do not edit by hand.\n")
        f.write("--\n")
        f.write("-- Sources and licences: docs/DATA_SOURCES.md\n")
        f.write("--   CEFR levels A1-B2  CEFR-J Vocabulary Profile 1.5 (Tono Lab, TUFS)\n")
        f.write("--   CEFR level C1      Octanove Vocabulary Profile C1/C2 1.0 (CC BY-SA 4.0)\n")
        f.write("--   IPA                ipa-dict en_US (MIT, from CMUdict)\n")
        f.write("--   frequency_rank     deliberately NULL - see docs/DATA_SOURCES.md\n")
        f.write("--\n")
        f.write("-- Re-running is safe: ON CONFLICT DO NOTHING, keyed by the natural key.\n\n")
        f.write("INSERT INTO words (text, language, accent, phonetic_ipa, target_phonemes,\n")
        f.write("                   difficulty_level, cefr_level, part_of_speech)\nVALUES\n")
        lines = []
        for r in words:
            lines.append(
                f"  ({q(r['word'])}, 'en', 'en-US', {q(r['body'])}, {arr(r['phonemes'])}, "
                f"{q(CEFR_TO_DIFFICULTY[r['level']])}, {q(r['level'])}, {q(r['pos'])})"
            )
        f.write(",\n".join(lines))
        f.write("\nON CONFLICT (text, language, accent) DO NOTHING;\n")

    by_level = collections.Counter(r["level"] for r in words)
    print(f"yozildi: {os.path.relpath(OUT)}")
    print(f"jami   : {len(words)} so'z")
    for k in ["A1", "A2", "B1", "B2", "C1"]:
        print(f"   {k}: {by_level[k]}")
    top = collections.Counter(p for r in words for p in r["phonemes"])
    print("tovushlar:", dict(top.most_common()))


if __name__ == "__main__":
    main()
