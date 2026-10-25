const fs = require('fs');
const path = require('path');

const projectRoot = 'C:\\Users\\hamim\\.gemini\\antigravity\\scratch\\educal';
const webAppDir = path.join(projectRoot, 'web_app');
const htmlPath = path.join(webAppDir, 'index.html');
const cssPath = path.join(webAppDir, 'style.css');
const jsPath = path.join(webAppDir, 'app.js');

const html = fs.readFileSync(htmlPath, 'utf8');
const css = fs.readFileSync(cssPath, 'utf8');
const js = fs.readFileSync(jsPath, 'utf8');

console.log('HTML total bytes:', Buffer.byteLength(html));
console.log('CSS total bytes:', Buffer.byteLength(css));
console.log('JS total bytes:', Buffer.byteLength(js));

console.log('Contains CSS snippet:', html.includes('--bg-main: #F8FAFC;'));
console.log('Contains JS snippet:', html.includes('OFFICIAL_2026_CALENDAR'));
console.log('Contains auto-end classes:', html.includes('areClassesInSession'));
console.log('Contains semester break:', html.includes('isSemesterBreak'));
