#!/usr/bin/env python3
"""Checks the seed personas against the real role templates.

Catches the three ways hand-written answers drift from a template: an id the
template does not have, a required question left blank, and a select value that
is not one of the offered options. Run it before seeding — a bad answer becomes
a profile that renders wrong and nobody notices.
"""
import json, sys

templates = {t['id']: t for t in json.load(open(sys.argv[1]))}
personas = json.load(open(sys.argv[2]))

def visible(q, a):
    dep = q.get('dependsOnId')
    if not dep:
        return True
    v = a.get(dep)
    if v is None:
        return False
    accepted = q.get('dependsOnValues') or (
        [q['dependsOnValue']] if q.get('dependsOnValue') else [])
    if not accepted:
        return True
    if isinstance(v, list):
        return any(str(x) in accepted for x in v)
    return str(v) in accepted

problems = []
for p in personas:
    t = templates.get(p['roleId'])
    if not t:
        problems.append("%s: no template '%s'" % (p['slot'], p['roleId']))
        continue
    a = p['answers']
    ids = set(q['id'] for q in t['questions'])
    for k in a:
        if k not in ids:
            problems.append("%s %s: '%s' is not a question" % (p['slot'], p['roleId'], k))
    for q in t['questions']:
        if not visible(q, a):
            if q['id'] in a:
                problems.append("%s %s: '%s' answered but hidden" % (p['slot'], p['roleId'], q['id']))
            continue
        v = a.get(q['id'])
        if q.get('required') and v in (None, '', []):
            problems.append("%s %s: required '%s' is blank" % (p['slot'], p['roleId'], q['id']))
        opts = q.get('options') or []
        if opts and v is not None and not q.get('allowCustom'):
            for x in (v if isinstance(v, list) else [v]):
                if str(x) not in opts:
                    problems.append("%s %s: '%s' = '%s' is not an option" % (p['slot'], p['roleId'], q['id'], x))

for line in problems:
    print(line)
print('%d personas, %d problems' % (len(personas), len(problems)))
sys.exit(1 if problems else 0)
