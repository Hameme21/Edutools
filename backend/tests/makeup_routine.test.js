const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

for (const file of ['index.html', 'docs/index.html', 'backend/public/index.html']) {
  test(`${file}: academic substitutions apply only on their calendar dates`, () => {
    const html = fs.readFileSync(path.join(__dirname, '../..', file), 'utf8');
    const context = vm.createContext({});
    const start = html.indexOf('const OFFICIAL_2026_CALENDAR = [');
    const end = html.indexOf('\n];', start) + 3;
    vm.runInContext(html.slice(start, end) + '\nvar state = {notices: OFFICIAL_2026_CALENDAR, classes: []};', context);
    // Run the actual page functions with its real academic calendar data.
    for (const name of ['parseDateStr', 'getHolidayNoticesForDate', 'isSemesterBreak',
      'isClassesSuspended', 'isExamPeriod', 'areClassesInSession', 'isDateHoliday',
      'routineDayFromNotice', 'routineWeekdayForDate', 'getActiveClassesForDate', 'getOtherNoticesForDate']) {
      const begin = html.indexOf(`function ${name}(`);
      const next = html.indexOf('\nfunction ', begin + 1);
      vm.runInContext(html.slice(begin, next), context);
    }
    vm.runInContext('state.classes = [2,3,4,6,7].map(dayOfWeek => ({dayOfWeek, startTime:"09:51"}));', context);
    const active = date => JSON.parse(vm.runInContext(
      `JSON.stringify(getActiveClassesForDate(parseDateStr('${date}')))`, context));
    for (const [date, day] of Object.entries({
      '2026-11-05':6, '2026-11-12':6, '2026-11-26':7,
      '2026-12-17':3, '2026-12-31':6, '2026-04-13':2, '2026-11-19':4,
    })) {
      assert.deepEqual(active(date), [{dayOfWeek:day, startTime:'09:51'}]);
    }
    vm.runInContext("state.routineRange = {startDate:'2026-11-13',endDate:'2027-01-20'}", context);
    assert.deepEqual(active('2026-11-12'), []);
    vm.runInContext("state.routineRange = null; state.notices.push({title:'Holiday',startDate:'2026-11-12',endDate:'2026-11-12',isHoliday:true});", context);
    assert.deepEqual(active('2026-11-12'), []);
    assert.deepEqual(active('2026-12-05'), []); // Exam period remains suppressed.
    vm.runInContext('state.classes = state.classes.filter(c => c.dayOfWeek !== 7)', context);
    assert.deepEqual(active('2026-11-26'), []); // No fallback to Thursday classes.
  });
}
