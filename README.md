Phenom Angular MCP
MCP server שמחבר את Cursor ישירות ל-Phenom Angular Design System.
עם ה-MCP הזה Cursor יכול לענות על שאלות כמו:

"מה כל ה-@Input() props של הbutton?"
"תראה לי את ה-HTML template של phenom-input"
"איך משתמשים בcomponent X? תביא דוגמה מה-stories"


שני MCP שמשלימים זה את זה
phenom-angular — קורא מהריפו המקומי
עובד ישירות מול קוד המקור. לא תלוי באינטרנט.
כלימה הוא עושהlist_componentsכל הcomponents בDSsearch_componentsחיפוש לפי שם או selectorget_component_sourceקוד מקור מלא — TS + HTML + SCSSget_component_inputsכל ה-@Input() עם טיפוסים, defaults ותיאוריםget_component_outputsכל ה-@Output() EventEmittersget_story_codeקובץ ה-.stories.ts המלאget_storybook_indexרשימת stories חיה מ-pds.phenom.com
storybook-mcp — קורא מ-pds.phenom.com/angular
עובד מול ה-Storybook הציבורי. מביא את מה שהמשתמשים רואים באתר.
כלימה הוא עושהconnectמתחבר ל-Storybook ומוודא חיבורlistרשימת כל הcomponents והstoriessearchחיפוש לפי שם או נתיבget_docsדוקומנטציה מרונדרת — props, code examples, תיאוריםscreenshotצילום מסך של קומפוננטה
למה שניהם?
phenom-angular יודע איך הקומפוננטה בנויה — קוד מקור, TypeScript, templates.

storybook-mcp יודע איך להשתמש בקומפוננטה — דוקומנטציה, דוגמאות, ויזואליזציה.
יחד: Cursor יכול לענות על "מה ה-@Input() של הbutton?" וגם "תראה לי דוגמה איך להשתמש בו".

---

## התקנה

### דרישות מוקדמות
- Node.js 18+
- Cursor
- Clone מקומי של ריפו `phenom-ds` https://bitbucket.org/phenompeople/phenom-ds/src/main/

### צעד 1 — Clone

```bash
git clone https://github.com/shlomikastoryano-prog/phenom-angular-mcp.git
```
```bash
cd phenom-angular-mcp
```



### צעד 2 — הרץ את סקריפט ההתקנה

```bash
bash install.sh
```

הסקריפט ישאל אותך:
1. **איפה להתקין את השרת** — לחץ Enter לברירת מחדל (`~/Documents/Cursor/phenom-angular-mcp`)
2. **נתיב לריפו phenom-ds שלך** — ינסה לזהות אוטומטית, אחרת תכניס ידנית
3. תלחץ Enter

הסקריפט יעשה הכל בעצמו: `npm install`, `build`, ועדכון `~/.cursor/mcp.json`.

### צעד 3 — Restart Cursor

פתח מחדש את Cursor ולך ל-**Settings → MCP**.

אמורים להופיע:
- ✅ `phenom-angular`
- ✅ `storybook-mcp`

---

## שאלות?

פנה ל-Shlomi Kastoryano
