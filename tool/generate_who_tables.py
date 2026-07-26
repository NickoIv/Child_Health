"""Generates the WHO growth reference tables as Dart source.

The tables are data, not code: they must be reproducible from the source
dataset rather than hand-transcribed. An earlier version of this file was
written from memory, and while the medians happened to be right, the L and S
coefficients were off by enough to shift every z-score.

Input:  tool/data/wgsData.csv — WHO Child Growth Standards LMS values as
        packaged by the R `zscorer` package (nutriverse/zscorer).
Output: lib/core/growth/who_tables.dart

Run:    python tool/generate_who_tables.py
"""

import csv
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(HERE, 'data', 'wgsData.csv')
OUT_PATH = os.path.join(
    HERE, '..', 'lib', 'core', 'growth', 'who_tables.dart')

# indicator code in the dataset -> (dart table prefix, human name)
INDICATORS = {
    'wfa': ('weightForAge', 'weight-for-age'),
    'hfa': ('heightForAge', 'length/height-for-age'),
}
# dataset sex code -> dart suffix
SEXES = {'1': 'Boys', '2': 'Girls'}


def load():
    with io.open(CSV_PATH, encoding='utf-8') as f:
        rows = list(csv.DictReader(f))

    tables = {}
    for indicator, (prefix, _) in INDICATORS.items():
        for sex_code, suffix in SEXES.items():
            picked = [
                r for r in rows
                if r['indicator'] == indicator and r['sex'] == sex_code
            ]
            picked.sort(key=lambda r: float(r['given']))
            if not picked:
                sys.exit(f'no rows for {indicator} sex={sex_code}')
            tables[prefix + suffix] = picked
    return tables


def check(tables):
    """Fails loudly rather than emitting a table that is subtly wrong."""
    for name, rows in tables.items():
        months = [int(float(r['given'])) for r in rows]
        if months != list(range(0, 61)):
            sys.exit(f'{name}: expected months 0..60, got {months[:5]}...')
        for r in rows:
            m, s = float(r['m']), float(r['s'])
            if m <= 0 or s <= 0:
                sys.exit(f'{name}: non-positive M or S at month {r["given"]}')

    # Spot-check against a published value: WHO weight-for-age, boys, 12
    # months, median 9.6479 kg.
    row = tables['weightForAgeBoys'][12]
    if abs(float(row['m']) - 9.6479) > 0.0001:
        sys.exit(f'sanity check failed: boys wfa at 12mo M={row["m"]}')


def emit(tables):
    out = io.StringIO()
    out.write('''// GENERATED FILE — DO NOT EDIT BY HAND.
//
// Produced by tool/generate_who_tables.py from the WHO Child Growth Standards
// LMS dataset (tool/data/wgsData.csv, as packaged by nutriverse/zscorer).
// Regenerate with:  python tool/generate_who_tables.py
//
// Complete monthly coverage, 0-60 months, both sexes, for weight-for-age and
// length/height-for-age. Every row is L (Box-Cox power), M (median) and S
// (coefficient of variation) exactly as published.

part of 'who_standards.dart';

''')

    for name, rows in tables.items():
        is_weight = name.startswith('weightForAge')
        indicator = 'weight-for-age' if is_weight else 'length/height-for-age'
        sex = 'boys' if name.endswith('Boys') else 'girls'
        out.write(f'/// WHO {indicator}, {sex}, 0-60 months.\n')
        out.write(f'const _{name} = <LmsPoint>[\n')
        for r in rows:
            month = int(float(r['given']))
            out.write(
                f'  LmsPoint({month}, {float(r["l"]):.6g}, '
                f'{float(r["m"]):.6g}, {float(r["s"]):.6g}),\n'
            )
        out.write('];\n\n')

    with io.open(OUT_PATH, 'w', encoding='utf-8', newline='\n') as f:
        f.write(out.getvalue())


def main():
    tables = load()
    check(tables)
    emit(tables)
    total = sum(len(v) for v in tables.values())
    print(f'wrote {os.path.normpath(OUT_PATH)}: '
          f'{len(tables)} tables, {total} rows')


if __name__ == '__main__':
    main()
