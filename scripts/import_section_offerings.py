"""Import the supplied Fall 2026 PDF. Requires pdfplumber; never guesses times.
Usage: python scripts/import_section_offerings.py PDF_PATH FACULTIES_JSON_PATH
"""
import datetime
import json
import pathlib
import re
import sys
import pdfplumber
import pymupdf

ROOT = pathlib.Path(__file__).resolve().parents[1]
assets = ROOT / 'sample_data'
days = {'Mon': 1, 'Tue': 2, 'Wed': 3, 'Thu': 4, 'Fri': 5, 'Sat': 6, 'Sun': 7}

def clock(value):
    return datetime.datetime.strptime(value.strip(), '%I:%M:%p').strftime('%H:%M')

def main():
    faculty = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding='utf-8-sig'))
    (assets / 'faculties.json').write_text(json.dumps(faculty, ensure_ascii=False, indent=2), encoding='utf-8')
    offerings = []
    source = pymupdf.open(sys.argv[1])
    with pdfplumber.open(sys.argv[1]) as pdf:
        for page_number, page in enumerate(pdf.pages, 1):
            traces = [(t['chars'][0][2], ''.join(chr(c[0]) for c in t['chars']))
                      for t in source[page_number - 1].get_texttrace() if t['chars']]
            for table in page.find_tables():
                for table_row in table.rows[1:]:
                    # Assign text DRAW OPERATIONS by their insertion point,
                    # not glyph extents. Long titles/rooms/faculty names spill
                    # into adjacent cells in the source PDF.
                    row = [' '.join(text for (x, y), text in traces
                                    if cell and cell[0] <= x < cell[2] and cell[1] <= y < cell[3]).strip()
                           for cell in table_row.cells]
                    if not row or not str(row[0]).isdigit():
                        continue
                    serial = int(row[0])
                    assert len(row) == 14, (page_number, row)
                    section = re.search(r'[A-Z]+', row[4]).group()
                    meetings = []
                    for day, time, room in [(row[7], row[9], row[5]), (row[8], row[10], row[6])]:
                        if not day and time.strip() in ('', '-'):
                            continue
                        assert day in days, (serial, day)
                        start, end = [clock(t) for t in time.split(' - ')]
                        assert start < end, (serial, time)
                        meetings.append(dict(dayOfWeek=days[day], startTime=start, endTime=end,
                                             room=(room.split()[0] if room else 'TBA')))
                    assert meetings, serial
                    offerings.append(dict(id=f'F26-{serial}', program=row[1], courseCode=row[2].strip(),
                        title=row[3].strip(), section=section, sectionNote=row[4] if '(' in row[4] else '',
                        facultyName='To be announced' if 'TBA' in row[11:13] else row[11].strip(),
                        facultyCode=row[12].strip(), credits=float(row[13]), meetings=meetings,
                        sourcePage=page_number, sourceRow=serial))
    assert [s['sourceRow'] for s in offerings] == list(range(1, 792))
    data = dict(term='Fall 2026', programs=['BSCSE', 'BSDS'],
                source=pathlib.Path(sys.argv[1]).name, offerings=offerings)
    (assets / 'fall_2026_sections.json').write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'Imported {len(offerings)} offerings, {sum(len(x["meetings"]) for x in offerings)} meetings.')

if __name__ == '__main__':
    main()
