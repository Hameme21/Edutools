const fs = require('fs');
const path = require('path');

// In-memory calendar databases per student: email -> { calendarEvents: [], files: [], syncReports: [] }
const userCalendarStore = new Map();

/**
 * Ensures user calendar store exists
 */
function getOrCreateUserCalendar(email = 'student@university.edu') {
  const norm = email.toLowerCase();
  if (!userCalendarStore.has(norm)) {
    userCalendarStore.set(norm, {
      calendarEvents: [],
      uploadedFiles: [],
      auditLogs: [],
      lastSyncTimestamp: null,
    });
  }
  return userCalendarStore.get(norm);
}

/**
 * Parses file contents into structured events based on extension and content signature
 */
function parseScheduleFile(filePath, originalName, buffer) {
  const content = buffer ? buffer.toString('utf-8') : fs.readFileSync(filePath, 'utf-8');
  const ext = path.extname(originalName).toLowerCase();
  const trimmed = content.trim();

  const parsedEvents = [];
  const parseLogs = [];

  try {
    if (ext === '.ics' || trimmed.toUpperCase().includes('BEGIN:VCALENDAR') || trimmed.toUpperCase().includes('BEGIN:VEVENT')) {
      parseLogs.push('Detected iCalendar (.ics) format.');
      const icsEvents = parseIcsString(trimmed);
      parsedEvents.push(...icsEvents);
      parseLogs.push(`Extracted ${icsEvents.length} events from iCalendar stream.`);
    } else if (ext === '.json' || trimmed.startsWith('[') || trimmed.startsWith('{')) {
      parseLogs.push('Detected JSON array/object schedule format.');
      const jsonEvents = parseJsonString(trimmed);
      parsedEvents.push(...jsonEvents);
      parseLogs.push(`Extracted ${jsonEvents.length} events from JSON payload.`);
    } else if (ext === '.csv' || (!trimmed.startsWith('{') && !trimmed.startsWith('[') && trimmed.includes(','))) {
      parseLogs.push('Detected CSV tabular schedule format.');
      const csvEvents = parseCsvString(trimmed);
      parsedEvents.push(...csvEvents);
      parseLogs.push(`Extracted ${csvEvents.length} events from CSV rows.`);
    } else {
      // Plain text or syllabus text extraction
      parseLogs.push('Detected Plain Text / Syllabus outline format. Performing heuristic parsing.');
      const textEvents = parseTextSyllabus(trimmed);
      parsedEvents.push(...textEvents);
      parseLogs.push(`Extracted ${textEvents.length} schedule markers from text document.`);
    }
  } catch (err) {
    parseLogs.push(`Parsing error encountered: ${err.message}`);
    throw new Error(`Failed to parse file "${originalName}": ${err.message}`);
  }

  return {
    events: parsedEvents,
    logs: parseLogs,
    totalCount: parsedEvents.length,
  };
}

/**
 * Synchronizes extracted events into the user's active calendar
 */
function synchronizeCalendar(email, extractedEvents, fileMetadata = {}) {
  const userStore = getOrCreateUserCalendar(email);
  const now = new Date().toISOString();

  const syncLogs = [];
  let addedCount = 0;
  let updatedCount = 0;
  let holidayCollisionCount = 0;

  // Save file record
  const fileRecord = {
    fileId: fileMetadata.fileId || `FILE-${Date.now()}`,
    filename: fileMetadata.filename || 'schedule_upload',
    size: fileMetadata.size || 0,
    uploadedAt: now,
    extractedCount: extractedEvents.length,
    events: extractedEvents,
  };
  userStore.uploadedFiles.push(fileRecord);

  // Synchronize each event
  extractedEvents.forEach((ev, idx) => {
    const signature = `${ev.courseCode || ''}-${ev.dayOfWeek || ev.startDate || ''}-${ev.startTime || ''}`.toLowerCase();
    const existingIndex = userStore.calendarEvents.findIndex(c => {
      const cSig = `${c.courseCode || ''}-${c.dayOfWeek || c.startDate || ''}-${c.startTime || ''}`.toLowerCase();
      return cSig === signature || (c.title && c.title === ev.title && c.startDate === ev.startDate);
    });

    if (existingIndex >= 0) {
      userStore.calendarEvents[existingIndex] = {
        ...userStore.calendarEvents[existingIndex],
        ...ev,
        lastUpdated: now,
        sourceFileId: fileRecord.fileId,
      };
      updatedCount++;
      syncLogs.push(`[UPDATE] Updated existing schedule entry "${ev.courseCode || ev.title}".`);
    } else {
      const newEntry = {
        id: ev.id || `EVT-SYNC-${Date.now()}-${idx}`,
        ...ev,
        createdAt: now,
        lastUpdated: now,
        sourceFileId: fileRecord.fileId,
      };
      userStore.calendarEvents.push(newEntry);
      addedCount++;
      syncLogs.push(`[INSERT] Added new event "${ev.courseCode || ev.title}" to calendar.`);
    }
  });

  userStore.lastSyncTimestamp = now;
  userStore.auditLogs.push(...syncLogs);

  return {
    success: true,
    fileId: fileRecord.fileId,
    totalParsed: extractedEvents.length,
    addedCount,
    updatedCount,
    syncedTotal: userStore.calendarEvents.length,
    timestamp: now,
    logs: syncLogs,
  };
}

/**
 * Synchronization Status Checker: Compares entries found in uploaded file against actual calendar entries
 */
function verifySyncStatus(email) {
  const userStore = getOrCreateUserCalendar(email);
  const now = new Date().toISOString();

  // Combine all uploaded file events from history
  const allParsedFileEvents = [];
  userStore.uploadedFiles.forEach(f => {
    if (f.events && Array.isArray(f.events)) {
      allParsedFileEvents.push(...f.events);
    }
  });

  const calendarEntries = userStore.calendarEvents;
  const auditLogs = [];

  const matchedEvents = [];
  const missingEvents = [];
  const duplicateEvents = [];
  const misalignedEvents = [];

  // 1. Check for Duplicate Events in Calendar
  const signatureMap = new Map();
  calendarEntries.forEach(entry => {
    const sig = `${entry.courseCode || entry.title}-${entry.dayOfWeek || entry.startDate}-${entry.startTime || ''}`.toLowerCase();
    if (signatureMap.has(sig)) {
      duplicateEvents.push({
        event: entry,
        reason: `Duplicate detected with event ID: ${signatureMap.get(sig).id}`,
      });
      auditLogs.push(`[WARN - DUPLICATE] Duplicate calendar entry: ${entry.title || entry.courseCode}`);
    } else {
      signatureMap.set(sig, entry);
    }
  });

  // 2. Cross-reference parsed file events vs calendar database entries
  allParsedFileEvents.forEach(fileEv => {
    const fileSig = `${fileEv.courseCode || fileEv.title}-${fileEv.dayOfWeek || fileEv.startDate}-${fileEv.startTime || ''}`.toLowerCase();
    const found = calendarEntries.find(c => {
      const cSig = `${c.courseCode || c.title}-${c.dayOfWeek || c.startDate}-${c.startTime || ''}`.toLowerCase();
      return cSig === fileSig || (c.title === fileEv.title && c.startDate === fileEv.startDate);
    });

    if (!found) {
      missingEvents.push(fileEv);
      auditLogs.push(`[ERROR - MISSING] File event "${fileEv.courseCode || fileEv.title}" is missing from active calendar.`);
    } else {
      // Check for misalignments (e.g. room mismatch, timing divergence)
      const roomMismatch = fileEv.room && found.room && fileEv.room !== found.room;
      const timeMismatch = fileEv.endTime && found.endTime && fileEv.endTime !== found.endTime;

      if (roomMismatch || timeMismatch) {
        misalignedEvents.push({
          fileEvent: fileEv,
          calendarEvent: found,
          discrepancy: [
            roomMismatch ? `Room mismatch: File='${fileEv.room}' vs Cal='${found.room}'` : null,
            timeMismatch ? `End time mismatch: File='${fileEv.endTime}' vs Cal='${found.endTime}'` : null,
          ].filter(Boolean).join('; '),
        });
        auditLogs.push(`[WARN - MISALIGNED] Discrepancy for "${fileEv.courseCode || fileEv.title}"`);
      } else {
        matchedEvents.push(found);
      }
    }
  });

  // Calculate Match Rate %
  const totalParsed = allParsedFileEvents.length > 0 ? allParsedFileEvents.length : calendarEntries.length;
  const totalSynced = calendarEntries.length;
  const discrepancyCount = missingEvents.length + duplicateEvents.length + misalignedEvents.length;

  let matchRatePercent = 100.0;
  if (totalParsed > 0) {
    const matchCount = Math.max(0, totalParsed - missingEvents.length - misalignedEvents.length);
    matchRatePercent = parseFloat(((matchCount / totalParsed) * 100).toFixed(1));
  }

  // Determine Health Status
  let syncHealth = 'PERFECT';
  if (discrepancyCount > 0) {
    syncHealth = matchRatePercent < 70 ? 'DESYNC' : 'DISCREPANCIES_DETECTED';
  } else if (totalSynced === 0) {
    syncHealth = 'NO_SCHEDULE';
  }

  return {
    success: true,
    email,
    syncHealth,
    matchRatePercent,
    totalParsed,
    totalSynced,
    matchedCount: matchedEvents.length,
    discrepancyCount,
    missingEvents,
    duplicateEvents,
    misalignedEvents,
    lastSyncTimestamp: userStore.lastSyncTimestamp || now,
    auditLogs: auditLogs.slice(-20), // Last 20 audit entries
  };
}

// ===================== HELPER PARSERS =====================

function parseIcsString(ics) {
  const events = [];
  const lines = ics.split(/\r\n|\n|\r/);
  let cur = null;

  lines.forEach(line => {
    const trimmed = line.trim();
    if (trimmed.startsWith('BEGIN:VEVENT')) {
      cur = {};
    } else if (trimmed.startsWith('END:VEVENT')) {
      if (cur) {
        const title = cur.SUMMARY || 'Untitled Class';
        const isRoutine = cur.RRULE && cur.RRULE.includes('BYDAY=');
        
        events.push({
          id: cur.UID || `ICS-${Date.now()}-${events.length}`,
          courseCode: extractCourseCode(title),
          title: title,
          subject: title,
          dayOfWeek: extractDayOfWeek(cur),
          startTime: extractTime(cur.DTSTART, '09:00'),
          endTime: extractTime(cur.DTEND, '10:30'),
          room: cur.LOCATION || 'Room TBA',
          instructor: cur.DESCRIPTION || 'Faculty Member',
          startDate: extractDate(cur.DTSTART),
          endDate: extractDate(cur.DTEND),
          isHoliday: title.toLowerCase().includes('holiday') || (cur.CATEGORIES && cur.CATEGORIES.includes('HOLIDAY')),
        });
      }
      cur = null;
    } else if (cur && trimmed.includes(':')) {
      const idx = trimmed.indexOf(':');
      const key = trimmed.substring(0, idx).split(';')[0];
      const val = trimmed.substring(idx + 1);
      cur[key] = val;
    }
  });

  return events;
}

function parseJsonString(jsonStr) {
  const data = JSON.parse(jsonStr);
  const list = Array.isArray(data) ? data : [data];
  return list.map((item, idx) => ({
    id: item.id || `JSON-${Date.now()}-${idx}`,
    courseCode: item.courseCode || item.code || extractCourseCode(item.title || item.subject || 'COURSE'),
    subject: item.subject || item.title || 'Course Subject',
    title: item.title || item.subject || 'Course Subject',
    dayOfWeek: parseInt(item.dayOfWeek || item.day || 1, 10),
    startTime: item.startTime || '09:00',
    endTime: item.endTime || '10:30',
    room: item.room || item.location || 'Room TBA',
    instructor: item.instructor || 'Faculty Member',
    startDate: item.startDate || item.start || new Date().toISOString().split('T')[0],
    endDate: item.endDate || item.end || new Date().toISOString().split('T')[0],
    isHoliday: item.isHoliday === true || item.category === 'holiday',
  }));
}

function parseCsvString(csvStr) {
  const lines = csvStr.split(/\r\n|\n|\r/).filter(l => l.trim().length > 0);
  if (lines.length < 2) return [];

  const headers = lines[0].split(',').map(h => h.trim().toLowerCase().replace(/[^a-z0-9]/g, ''));
  const events = [];

  for (let i = 1; i < lines.length; i++) {
    const cols = lines[i].split(',').map(c => c.trim().replace(/^["']|["']$/g, ''));
    if (!cols[0]) continue;

    const get = (keys, def = '') => {
      for (const k of keys) {
        const idx = headers.findIndex(h => h.includes(k));
        if (idx !== -1 && cols[idx] !== undefined && cols[idx] !== '') return cols[idx];
      }
      return def;
    };

    const dayMap = { mon: 1, monday: 1, '1': 1, tue: 2, tuesday: 2, '2': 2, wed: 3, wednesday: 3, '3': 3, thu: 4, thursday: 4, '4': 4, fri: 5, friday: 5, '5': 5, sat: 6, saturday: 6, '6': 6, sun: 7, sunday: 7, '7': 7 };
    const rawDay = get(['day', 'weekday'], '1').toLowerCase();

    events.push({
      id: `CSV-${Date.now()}-${i}`,
      courseCode: get(['course', 'code'], `CSE-${100 + i}`),
      subject: get(['subject', 'title', 'name'], `Course ${i}`),
      title: get(['title', 'subject'], `Course ${i}`),
      dayOfWeek: dayMap[rawDay] || 1,
      startTime: get(['start', 'from'], '09:00'),
      endTime: get(['end', 'to'], '10:30'),
      room: get(['room', 'location', 'lab'], 'Room TBA'),
      instructor: get(['instructor', 'faculty', 'teacher'], 'Faculty Member'),
      startDate: get(['startdate', 'date'], new Date().toISOString().split('T')[0]),
      endDate: get(['enddate'], new Date().toISOString().split('T')[0]),
      isHoliday: get(['type', 'category'], '').toLowerCase().includes('holiday'),
    });
  }

  return events;
}

function parseTextSyllabus(text) {
  const events = [];
  const lines = text.split('\n');
  lines.forEach((line, idx) => {
    const match = line.match(/([A-Z]{2,4}[-\s]?\d{3,4})[:\s]+([^,\n]+)/i);
    if (match) {
      events.push({
        id: `TXT-${Date.now()}-${idx}`,
        courseCode: match[1].replace(' ', '-').toUpperCase(),
        subject: match[2].trim(),
        title: match[2].trim(),
        dayOfWeek: 1,
        startTime: '09:00',
        endTime: '10:30',
        room: 'Room TBA',
        instructor: 'Faculty Member',
      });
    }
  });
  return events;
}

function extractCourseCode(text) {
  const m = text.match(/([A-Z]{2,4}[-\s]?\d{3,4})/i);
  return m ? m[1].replace(' ', '-').toUpperCase() : 'COURSE';
}

function extractDayOfWeek(ev) {
  if (ev.RRULE && ev.RRULE.includes('BYDAY=')) {
    const dayCode = ev.RRULE.split('BYDAY=')[1].split(';')[0].toUpperCase();
    const map = { MO: 1, TU: 2, WE: 3, TH: 4, FR: 5, SA: 6, SU: 7 };
    return map[dayCode] || 1;
  }
  return 1;
}

function extractTime(dtStr, def) {
  if (!dtStr || !dtStr.includes('T')) return def;
  const time = dtStr.split('T')[1].replace('Z', '');
  if (time.length >= 4) {
    return `${time.substring(0, 2)}:${time.substring(2, 4)}`;
  }
  return def;
}

function extractDate(dtStr) {
  if (!dtStr) return new Date().toISOString().split('T')[0];
  const clean = dtStr.replace(/[^0-9]/g, '');
  if (clean.length >= 8) {
    return `${clean.substring(0, 4)}-${clean.substring(4, 6)}-${clean.substring(6, 8)}`;
  }
  return new Date().toISOString().split('T')[0];
}

module.exports = {
  parseScheduleFile,
  synchronizeCalendar,
  verifySyncStatus,
  getOrCreateUserCalendar,
  userCalendarStore,
};
