(function (root) {
  'use strict';
  const key = code => String(code).replace(/[^a-z0-9]/gi, '').toUpperCase();
  const normalize = title => String(title).toLowerCase().replace(/&/g, 'and').replace(/laboratory/g, 'lab').replace(/[^a-z0-9]/g, '');
  const overlaps = (a, b) => a.dayOfWeek === b.dayOfWeek && a.startTime < b.endTime && b.startTime < a.endTime;
  function clashes(candidate, active, configured) {
    const replaced = new Set([...active.map(s => key(s.courseCode)), key(candidate.courseCode)]);
    const others = [...active.filter(s => key(s.courseCode) !== key(candidate.courseCode)).flatMap(s => s.meetings.map(m => ({...m, courseCode: s.courseCode}))),
      ...configured.filter(c => !replaced.has(key(c.courseCode)))];
    return others.filter(other => candidate.meetings.some(m => overlaps(m, other)));
  }
  function applySections(active, configured) {
    if (new Set(active.map(s => key(s.courseCode))).size !== active.length || active.some(s => clashes(s, active, configured).length)) throw Error('Resolve active-section clashes first.');
    const replaced = new Set(active.map(s => key(s.courseCode)));
    return [...configured.filter(c => !replaced.has(key(c.courseCode))), ...active.flatMap(s => s.meetings.map((m, i) => ({...m,
      id: `${s.id}-${i}`, courseCode: s.courseCode, subject: `${s.title} · Section ${s.section}`,
      instructor: s.facultyName, color: '#0891B2', reminderEnabled: true})))];
  }
  function resolveCode(title, catalog) {
    const matches = catalog.filter(c => normalize(c.name) === normalize(title));
    return matches.length === 1 ? matches[0].code : null;
  }
  const api = {key, normalize, overlaps, clashes, applySections, resolveCode};
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  if (typeof document === 'undefined') return;
  root.SectionPlanner = api;
  const load = name => fetch(`sample_data/${name}.json`).then(r => { if (!r.ok) throw Error('Could not load the section catalog. Refresh to retry.'); return r.json(); });
  const data = Promise.all([load('course_catalog'), load('faculties'), load('fall_2026_sections')]);
  const el = (tag, text, cls) => { const node = document.createElement(tag); if (text) node.textContent = text; if (cls) node.className = cls; return node; };
  const button = (text, fn) => { const node = el('button', text, 'btn btn-secondary'); node.type = 'button'; node.addEventListener('click', fn); return node; };
  const day = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const grid = document.getElementById('toolsGrid');
  const anchor = document.getElementById('coursePlannerPanel');
  if (!grid || !anchor) return;
  const panel = el('section', '', 'tool-panel-wrap section-planner');
  panel.id = 'sectionPlannerPanel'; panel.style.display = 'none'; anchor.after(panel);
  const card = el('button', '', 'tool-card'); card.type = 'button'; card.dataset.toolAction = 'sections';
  card.append(el('h3', 'Section Planner'), el('p', 'Fall 2026 CSE / DS sections, faculty, exact times and clash checks. Save backup sections per course.'));
  grid.append(card);
  grid.addEventListener('click', event => { const target = event.target.closest('[data-tool-action]'); if (target && target !== card) panel.style.display = 'none'; });
  let sections = [], selected = new Set(), primary = {}, query = '', program = 'All', limit = 40;
  const draftKey = () => `section_plan_fall2026_${state.student?.email?.toLowerCase() || 'guest'}`;
  const chosen = () => sections.filter(s => selected.has(s.id));
  const active = () => chosen().filter(s => primary[key(s.courseCode)] === s.id);
  let planList, optionList, summary, applyButton, message;
  function save() { try { localStorage.setItem(draftKey(), JSON.stringify({selected: [...selected], primary})); } catch (_) { message.textContent = 'This draft could not be saved on this device.'; } }
  function render() {
    const current = active(), existing = state.classes || [];
    planList.replaceChildren(); optionList.replaceChildren();
    summary.textContent = `My plan · ${current.length} active courses · ${chosen().length - current.length} backups`;
    function sectionCard(s, isChosen) {
      const box = el('article', '', 'section-choice');
      box.append(el('h4', `${s.courseCode} · Section ${s.section} · ${s.program}`), el('p', s.title),
        el('p', s.facultyName === 'To be announced' ? 'TBA — To be announced' : `${s.facultyName} (${s.facultyCode})`));
      if (s.sectionNote) box.append(el('p', 'Offered if required'));
      s.meetings.forEach(m => box.append(el('p', `${day[m.dayOfWeek]} ${m.startTime}–${m.endTime} · Room ${m.room}`)));
      const conflicts = clashes(s, current, existing);
      box.append(el('p', conflicts.length ? `Clash with ${[...new Set(conflicts.map(m => `${m.courseCode} · ${day[m.dayOfWeek]} ${m.startTime}–${m.endTime}`))].join('; ')}` : 'No clash with active plan / configured classes', conflicts.length ? 'section-clash' : 'section-clear'));
      const actions = el('div', '', 'section-actions');
      if (isChosen) {
        const isPrimary = primary[key(s.courseCode)] === s.id;
        actions.append(el('strong', isPrimary ? 'Active section' : 'Backup only'));
        if (!isPrimary) actions.append(button('Make active', () => { primary[key(s.courseCode)] = s.id; save(); render(); }));
        actions.append(button('Remove', () => {
          selected.delete(s.id);
          if (isPrimary) { delete primary[key(s.courseCode)]; const next = chosen().find(other => key(other.courseCode) === key(s.courseCode)); if (next) primary[key(s.courseCode)] = next.id; }
          save(); render();
        }));
      } else actions.append(button(primary[key(s.courseCode)] ? 'Add backup' : 'Add section', () => { selected.add(s.id); primary[key(s.courseCode)] ||= s.id; save(); render(); }));
      box.append(actions); return box;
    }
    chosen().forEach(s => planList.append(sectionCard(s, true)));
    const matches = sections.filter(s => !selected.has(s.id) && (program === 'All' || s.program === program) &&
      (`${s.courseCode} ${s.title} ${s.section} ${s.facultyName} ${s.facultyCode}`.toLowerCase().includes(query.toLowerCase()) || key(s.courseCode).includes(key(query))));
    optionList.append(el('h3', `Available sections · ${matches.length}`));
    matches.slice(0, limit).forEach(s => optionList.append(sectionCard(s, false)));
    if (matches.length > limit) optionList.append(button('Show more sections', () => { limit += 40; render(); }));
    const blocked = current.some(s => clashes(s, current, existing).length);
    applyButton.disabled = !current.length || blocked;
    applyButton.textContent = `Apply ${current.length} active sections to routine`;
    message.textContent = blocked ? 'Resolve active-section clashes before applying.' : 'Apply replaces configured meetings for these courses. Other courses stay in place. Backups stay in this planner.';
  }
  card.addEventListener('click', async () => {
    ['cgpaCalcPanel','examRoutinePanel','divisionCalcPanel','coursePlannerPanel','toolsCalendarPanel'].forEach(id => { const p = document.getElementById(id); if (p) p.style.display = 'none'; });
    panel.style.display = 'block'; panel.replaceChildren(el('p', 'Loading Fall 2026 sections…'));
    try {
      const [, , catalog] = await data; sections = catalog.offerings;
      selected = new Set(); primary = {}; query = ''; program = 'All'; limit = 40;
      let saved; try { saved = JSON.parse(localStorage.getItem(draftKey()) || 'null'); } catch (_) {}
      const valid = new Set(sections.map(s => s.id));
      (saved?.selected || []).filter(id => valid.has(id)).forEach(id => selected.add(id));
      chosen().forEach(s => { primary[key(s.courseCode)] ||= s.id; if (saved?.primary?.[key(s.courseCode)] === s.id) primary[key(s.courseCode)] = s.id; });
      panel.replaceChildren(el('h2', 'Section Planner · Fall 2026'), button('Close planner', () => panel.style.display = 'none'),
        el('p', '791 BSCSE / BSDS offerings from the supplied routine. TBA means To be announced. Choose one active section per course and keep alternatives as backups.'));
      const search = el('input', '', 'form-input'); search.type = 'search'; search.placeholder = 'Search course, section or faculty'; search.setAttribute('aria-label', 'Search course, section or faculty');
      search.addEventListener('input', () => { query = search.value; limit = 40; render(); });
      const filter = el('select', '', 'form-input'); filter.setAttribute('aria-label', 'Program');
      ['All','BSCSE','BSDS'].forEach(p => { const o = el('option', p); o.value = p; filter.append(o); });
      filter.addEventListener('change', () => { program = filter.value; limit = 40; render(); });
      summary = el('h3'); planList = el('div'); optionList = el('div'); message = el('p');
      applyButton = button('Apply to routine', () => {
        try { state.classes = applySections(active(), state.classes || []); saveStudentSession(); renderAll(); syncStudentWithServer(true); showToast('Active sections added. Backups remain in the planner.', 'success'); render(); }
        catch (error) { message.textContent = error.message; }
      });
      panel.append(search, filter, summary, planList, message, applyButton, optionList); render();
    } catch (error) { panel.replaceChildren(el('p', error.message)); }
    panel.scrollIntoView({behavior: 'smooth', block: 'start'});
  });
  data.then(([courses, faculty]) => {
    api.courses = courses;
    function datalist(id, inputId, values) {
      const list = el('datalist'); list.id = id;
      values.forEach(value => { const o = el('option'); o.value = value; list.append(o); });
      document.body.append(list); document.getElementById(inputId)?.setAttribute('list', id);
    }
    datalist('plannerCourseTitles', 'classSubject', courses.map(c => c.name));
    datalist('plannerCourseCodes', 'classCourseCode', courses.map(c => c.code));
    datalist('facultyNames', 'classInstructor', faculty.map(f => f.name));
    const title = document.getElementById('classSubject'), code = document.getElementById('classCourseCode');
    title?.addEventListener('input', () => { const match = resolveCode(title.value, courses); if (match) code.value = match; });
    code?.addEventListener('input', () => { const match = courses.find(c => key(c.code) === key(code.value)); if (match) title.value = match.name; });
    const instructor = document.getElementById('classInstructor');
    if (instructor) instructor.placeholder = 'Search faculty name or initial';
    if (state.student) renderSetup();
  }).catch(() => { /* Opening the planner shows a retry message if assets fail. */ });
})(typeof window !== 'undefined' ? window : globalThis);
