# Phenom Angular MCP

MCP server שמחבר את Cursor ישירות ל-Phenom Angular Design System.

עם ה-MCP הזה Cursor יכול לענות על שאלות כמו:
- _"מה כל ה-@Input() props של הbutton?"_
- _"תראה לי את ה-HTML template של phenom-input"_
- _"איך משתמשים בcomponent X? תביא דוגמה מה-stories"_

---

## מה כלול

| כלי | מה הוא עושה |
|---|---|
| `list_components` | כל הcomponents בDS |
| `search_components` | חיפוש לפי שם או selector |
| `get_component_source` | קוד מקור מלא — TS + HTML + SCSS |
| `get_component_inputs` | כל ה-`@Input()` עם טיפוסים וdefaults |
| `get_component_outputs` | כל ה-`@Output()` EventEmitters |
| `get_story_code` | קובץ ה-`.stories.ts` |
| `get_storybook_index` | רשימת stories חיה מ-pds.phenom.com |

בנוסף — `storybook-mcp` מתחבר ל-[pds.phenom.com/angular](https://pds.phenom.com/angular) ומאפשר docs, חיפוש וscreenshots.

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
