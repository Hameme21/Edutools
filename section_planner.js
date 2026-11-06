(function (root) {
  'use strict';
  const key = code => String(code).replace(/[^a-z0-9]/gi, '').toUpperCase();
  const normalize = title => String(title).toLowerCase().replace(/&/g, 'and').replace(/laboratory/g, 'lab').replace(/[^a-z0-9]/g, '');
  const minutes = time => { const [h,m] = time.split(':').map(Number); return h*60+m; };
  const overlaps = (a, b) => a.dayOfWeek === b.dayOfWeek && minutes(a.startTime) < minutes(b.endTime) && minutes(b.startTime) < minutes(a.endTime);
  function clashes(candidate, active, configured) {
    const replaced = new Set([...active.map(s => key(s.courseCode)), key(candidate.courseCode)]);
    const others = [...active.filter(s => key(s.courseCode) !== key(candidate.courseCode)).flatMap(s => s.meetings.map(m => ({...m, courseCode: s.courseCode}))),
      ...configured.filter(c => !replaced.has(key(c.courseCode)))];
    return others.filter(other => candidate.meetings.some(m => overlaps(m, other)));
  }
  function unifiedMeetings(active, configured) {
    const replaced = new Set(active.map(s => key(s.courseCode)));
    return [...configured.filter(c => !replaced.has(key(c.courseCode))), ...active.flatMap(s => s.meetings.map((m, i) => ({...m,
      id: `${s.id}-${i}`, courseCode: s.courseCode, subject: `${s.title} · Section ${s.section}`,
      instructor: s.facultyName, color: '#0891B2', reminderEnabled: true})))];
  }
  function applySections(active, configured) {
    if (new Set(active.map(s => key(s.courseCode))).size !== active.length || active.some(s => clashes(s, active, configured).length)) throw Error('Resolve active-section clashes first.');
    return unifiedMeetings(active, configured);
  }
  function resolveCode(title, catalog) {
    const matches = catalog.filter(c => normalize(c.name) === normalize(title));
    return matches.length === 1 ? matches[0].code : null;
  }
  function matchesSectionFaculty(s,query) {
    const q=query.trim().toLowerCase();
    return [s.section,s.facultyName,s.facultyCode].some(value=>String(value).toLowerCase().includes(q));
  }
  function expiredPlannerEnd(range,now=new Date()) {
    if(!range?.endDate || !/^\d{4}-\d{2}-\d{2}$/.test(range.endDate)) return null;
    const today=`${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}-${String(now.getDate()).padStart(2,'0')}`;
    return today>range.endDate?range.endDate:null;
  }
  function rolloverSectionDraft(saved,expiredEnd,now=new Date()) {
    const draft={...(saved||{})};
    if(!expiredEnd || draft.clearedForEndDate===expiredEnd) return draft;
    const [y,m,d]=expiredEnd.split('-').map(Number),boundary=new Date(y,m-1,d+1).getTime();
    if((Number(draft.savedAtMs)||0)<boundary){draft.selected=[];draft.primary={};draft.savedAtMs=now.getTime();}
    draft.clearedForEndDate=expiredEnd;return draft;
  }
  const api = {key, normalize, minutes, overlaps, clashes, unifiedMeetings, applySections, resolveCode, matchesSectionFaculty, expiredPlannerEnd, rolloverSectionDraft};
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
  const cardTop=el('div','','tool-card-top'), iconBox=el('div','','tool-icon-box teal');
  const blueprint=el('i','','fa-solid fa-compass-drafting'); blueprint.setAttribute('aria-hidden','true');iconBox.append(blueprint);
  cardTop.append(iconBox,el('span','Active','tool-badge'));
  const cardFooter=el('div','','tool-card-footer'),features=el('div','','tool-features');
  ['Sections','Clash check','Backups'].forEach(text=>features.append(el('span',text,'tool-feat-chip')));
  const arrow=el('div','','tool-card-arrow');arrow.append(el('i','','fa-solid fa-arrow-right'));cardFooter.append(features,arrow);
  card.append(cardTop,el('h3', 'Section Planner'), el('p', 'Fall 2026 CSE / DS sections, faculty, exact times and clash checks. Save backup sections per course.'),cardFooter);
  grid.append(card);
  grid.addEventListener('click', event => { const target = event.target.closest('[data-tool-action]'); if (target && target !== card) panel.style.display = 'none'; });
  let sections = [], selected = new Set(), primary = {}, query = '', sectionQuery = '', program = 'All', limit = 12;
  let clearedForEndDate=null,savedAtMs=0;
  let ready=false;
  const draftKey = () => `section_plan_fall2026_${state.student?.email?.toLowerCase() || 'guest'}`;
  const chosen = () => sections.filter(s => selected.has(s.id));
  const active = () => chosen().filter(s => primary[key(s.courseCode)] === s.id);
  let planList, optionList, summary, applyButton, message, timetable, clashSummary,termNotice;
  const configuredForPlanner=()=>expiredPlannerEnd(state.routineRange)?[]:(state.classes||[]);
  function refreshExpiredPlan() {
    const expired=expiredPlannerEnd(state.routineRange);
    if(!expired || expired===clearedForEndDate) return;
    const refreshed=rolloverSectionDraft({selected:[...selected],primary,clearedForEndDate,savedAtMs},expired);
    selected=new Set(refreshed.selected||[]);primary=refreshed.primary||{};clearedForEndDate=refreshed.clearedForEndDate;savedAtMs=refreshed.savedAtMs||0;
    save();
  }
  panel.addEventListener('click',refreshExpiredPlan,true);
  panel.addEventListener('input',refreshExpiredPlan,true);
  function removeSection(s) {
    selected.delete(s.id);
    if (primary[key(s.courseCode)] === s.id) { delete primary[key(s.courseCode)]; const next = chosen().find(other => key(other.courseCode) === key(s.courseCode)); if (next) primary[key(s.courseCode)] = next.id; }
    save(); render();
  }
  function renderTimetable() {
    const entries = unifiedMeetings(active(), configuredForPlanner());
    const meta = new Map(active().flatMap(s => s.meetings.map((_, i) => [`${s.id}-${i}`,s])));
    const first = Math.min(8,...entries.map(m => Math.floor(minutes(m.startTime)/60)));
    const last = Math.max(17,...entries.map(m => Math.ceil(minutes(m.endTime)/60)));
    const span = (last-first)*60, hours = last-first;
    const hourLabel = h => `${h%12 || 12} ${h<12?'AM':'PM'}`;
    const conflict = new Set(entries.filter(a => entries.some(b => a !== b && overlaps(a,b))));
    clashSummary.textContent = conflict.size ? `${conflict.size} clashing meetings. Red cards show the conflicts; choose another active section to resolve them.` : 'No clashes in the unified routine.';
    clashSummary.className = conflict.size ? 'section-clash' : 'section-clear';
    timetable.replaceChildren();
    const canvas = el('div','','unified-canvas');
    const header = el('div','','unified-row unified-header'); header.append(el('div','Day','unified-day-heading'));
    const ticks = el('div','','unified-hours');
    for(let h=first;h<last;h++) ticks.append(el('div',`${hourLabel(h)} – ${hourLabel(h+1)}`));
    header.append(ticks); canvas.append(header);
    for(const weekday of [6,7,1,2,3,4,5]) {
      const meetings = entries.filter(m => m.dayOfWeek===weekday).sort((a,b)=>minutes(a.startTime)-minutes(b.startTime));
      const ends = [], positions = meetings.map(m => { let lane = ends.findIndex(end=>end<=minutes(m.startTime)); if(lane<0) lane=ends.length; ends[lane]=minutes(m.endTime); return {m,lane}; });
      const row = el('div','','unified-row');
      const label = el('div','','unified-day'+(meetings.length?' has-classes':''));
      label.append(el('strong',day[weekday].slice(0,3).toUpperCase()),el('small',meetings.length?`${meetings.length} ${meetings.length===1?'class':'classes'}`:'No class'));
      const track = el('div','','unified-track'); track.style.height=`${meetings.length?ends.length*100+16:64}px`; track.style.setProperty('--hour-count',hours);
      if(!meetings.length) track.append(el('em','No classes scheduled','unified-empty'));
      positions.forEach(({m,lane})=>{
        const s=meta.get(m.id), isClash=conflict.has(m);
        const block=el('article','','unified-class'+(isClash?' is-clash':''));
        block.style.left=`${(minutes(m.startTime)-first*60)/span*100}%`;
        block.style.width=`calc(${(minutes(m.endTime)-minutes(m.startTime))/span*100}% - 4px)`;
        block.style.top=`${lane*100+8}px`;
        block.title=`${m.courseCode} · ${s?'Section '+s.section:m.subject}\n${m.instructor}\n${day[weekday]} ${m.startTime}–${m.endTime} · Room ${m.room}${isClash?'\nCLASH':''}`;
        block.append(el('strong',m.courseCode),el('span',s?`${s.facultyName} · SEC ${s.section}`:m.instructor || m.subject),el('small',`${m.startTime}–${m.endTime} · ${m.room}`),el('small',isClash?'CLASH':s?'★ Active section':'Configured class'));
        if(s) { const remove=button('×',()=>removeSection(s)); remove.className='unified-remove'; remove.setAttribute('aria-label',`Remove ${s.courseCode} section ${s.section}`); block.append(remove); }
        track.append(block);
      });
      row.append(label,track);canvas.append(row);
    }
    timetable.append(canvas);
  }
  function save() { savedAtMs=Date.now();try { localStorage.setItem(draftKey(), JSON.stringify({selected: [...selected], primary,clearedForEndDate,savedAtMs})); } catch (_) { if(message)message.textContent = 'This draft could not be saved on this device.'; } }
  function render() {
    refreshExpiredPlan();
    const current = active(), existing = configuredForPlanner();
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
        actions.append(button('Remove', () => removeSection(s)));
      } else actions.append(button(primary[key(s.courseCode)] ? 'Add backup' : 'Add section', () => { selected.add(s.id); primary[key(s.courseCode)] ||= s.id; save(); render(); }));
      box.append(actions); return box;
    }
    chosen().forEach(s => planList.append(sectionCard(s, true)));
    const courseQuery = query.split(' — ')[0];
    const matches = sections.filter(s => query.trim() && !selected.has(s.id) && (program === 'All' || s.program === program) && matchesSectionFaculty(s,sectionQuery) &&
      (`${s.courseCode} ${s.title} ${s.facultyName} ${s.facultyCode}`.toLowerCase().includes(courseQuery.toLowerCase()) || key(s.courseCode).includes(key(courseQuery))));
    optionList.append(el('h3', `Available sections · ${matches.length}`));
    matches.slice(0, limit).forEach(s => optionList.append(sectionCard(s, false)));
    if (!query.trim()) optionList.append(el('p','Search a course above, then search or choose a section to add.'));
    if (matches.length > limit) optionList.append(button('Show more sections', () => { limit += 12; render(); }));
    const blocked = current.some(s => clashes(s, current, existing).length);
    applyButton.disabled = !current.length || blocked;
    applyButton.textContent = `Apply ${current.length} active sections to routine`;
    message.textContent = blocked ? 'Resolve active-section clashes before applying.' : 'Apply replaces configured meetings for these courses. Other courses stay in place. Backups stay in this planner.';
    if(expiredPlannerEnd(state.routineRange)) message.textContent=blocked?'Resolve active-section clashes before applying.':'Apply starts a new routine without the previous semester’s classes. Set the new routine dates in Class Setup afterward.';
    termNotice.textContent=expiredPlannerEnd(state.routineRange)?`The previous routine ended on ${state.routineRange.endDate}. Old semester classes are cleared from this planner. Your new selections are kept.`:'';
    renderTimetable();
  }
  card.addEventListener('click', async () => {
    ready=false;
    ['cgpaCalcPanel','examRoutinePanel','divisionCalcPanel','coursePlannerPanel','toolsCalendarPanel'].forEach(id => { const p = document.getElementById(id); if (p) p.style.display = 'none'; });
    panel.style.display = 'block'; panel.replaceChildren(el('p', 'Loading Fall 2026 sections…'));
    try {
      const [, , catalog] = await data; sections = catalog.offerings;
      selected = new Set(); primary = {}; query = ''; sectionQuery=''; program = 'All'; limit = 12;
      let saved; try { saved = JSON.parse(localStorage.getItem(draftKey()) || 'null'); } catch (_) {}
      saved=rolloverSectionDraft(saved,expiredPlannerEnd(state.routineRange));
      clearedForEndDate=saved.clearedForEndDate||null;savedAtMs=saved.savedAtMs||0;
      const valid = new Set(sections.map(s => s.id));
      (saved?.selected || []).filter(id => valid.has(id)).forEach(id => selected.add(id));
      chosen().forEach(s => { primary[key(s.courseCode)] ||= s.id; if (saved?.primary?.[key(s.courseCode)] === s.id) primary[key(s.courseCode)] = s.id; });
      panel.replaceChildren(el('h2', 'Section Planner · Fall 2026'), button('Close planner', () => panel.style.display = 'none'),
        el('p', '791 BSCSE / BSDS offerings from the supplied routine. TBA means To be announced. Choose one active section per course and keep alternatives as backups.'));
      const search = el('input', '', 'form-input'); search.type = 'search'; search.placeholder = 'Search course code or title'; search.setAttribute('aria-label', 'Search course');
      const courseOptions=el('datalist'); courseOptions.id='sectionCourseOptions';
      [...new Map(sections.map(s=>[s.courseCode,s])).values()].forEach(s=>{const o=el('option');o.value=`${s.courseCode} — ${s.title}`;courseOptions.append(o);});
      search.setAttribute('list','sectionCourseOptions');
      search.addEventListener('input', () => { query = search.value; limit = 12; render(); });
      const sectionSearch=el('input','','form-input');sectionSearch.type='search';sectionSearch.placeholder='Section, faculty name or initial';sectionSearch.setAttribute('aria-label','Search section or faculty');
      sectionSearch.addEventListener('input',()=>{sectionQuery=sectionSearch.value;limit=12;render();});
      const filter = el('select', '', 'form-input'); filter.setAttribute('aria-label', 'Program');
      ['All','BSCSE','BSDS'].forEach(p => { const o = el('option', p); o.value = p; filter.append(o); });
      filter.addEventListener('change', () => { program = filter.value; limit = 12; render(); });
      summary = el('h3'); planList = el('div'); optionList = el('div'); message = el('p');
      applyButton = button('Apply to routine', () => {
        try { const expired=expiredPlannerEnd(state.routineRange);state.classes = applySections(active(), configuredForPlanner());if(expired)state.routineRange=null;saveStudentSession(); renderAll(); syncStudentWithServer(true); showToast('Active sections added. Backups remain in the planner.', 'success'); render(); }
        catch (error) { message.textContent = error.message; }
      });
      const selectors=el('div','','section-selectors');
      for(const [text,input] of [['1. Search course',search],['2. Search section or faculty',sectionSearch],['Program',filter]]){const label=el('label',text);label.append(input);selectors.append(label);}
      const tableHeading=el('div','','unified-heading');tableHeading.append(el('h3','Unified Class Routine'),button('Clear section plan',()=>{selected.clear();primary={};save();render();}));
      timetable=el('div','','unified-scroll');timetable.setAttribute('role','region');timetable.setAttribute('aria-label','Unified Class Routine');timetable.tabIndex=0;
      clashSummary=el('p');
      termNotice=el('p','','section-term-notice');
      panel.append(termNotice,selectors,courseOptions,optionList,tableHeading,el('p','Swipe or scroll horizontally to see all hours. Cards use exact meeting times.'),timetable,clashSummary,el('h3','Section plan'),summary,planList,message,applyButton);ready=true;render();save();
    } catch (error) { panel.replaceChildren(el('p', error.message)); }
    panel.scrollIntoView({behavior: 'smooth', block: 'start'});
  });
  setInterval(()=>{if(ready && panel.style.display!=='none' && expiredPlannerEnd(state.routineRange)!==clearedForEndDate && expiredPlannerEnd(state.routineRange)) render();},60000);
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
