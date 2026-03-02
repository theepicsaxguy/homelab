---
name: agents-md-updater
description: "Skill for updating AGENTS.md, using ONLY the exact plain text and tag syntax found in AGENTS.md. No markdown, no extra formatting, no chapter headers."
---

PURPOSE
Update AGENTS.md by adding, updating, or removing entries using ONLY the exact plain text and tag syntax found in AGENTS.md. No markdown, no extra formatting, and no chapter headers are allowed. The only acceptable format is:

The tags below are examples. Each tag represents a specific area with its own rules or information. Include only tags that are relevant to the project. Omit any tag for an area that does not exist in the project.

```
<project_description>
Project description goes here. This section should briefly explain the purpose and scope of the project, e.g.:
AiPortal is Region Halland’s internal AI assistant portal: a product that standardizes how the organization uses AI by providing a single, governed place for chat-based assistants, approved capabilities, and operational oversight.
</project_description>


<Global_rules>
- Global rules for the project. List each rule as a bullet point, e.g.:
- Do not log credentials, api keys, tokens, or connection strings.
- All async dotnet methods accept and pass CancellationToken to every async dependency.
<Global_rules>


<backend>
Backend section. Summarize backend architecture, then specify paths and rules:
<backend_paths>
- List backend paths here
</backend_paths>
<backend_rules>
- List backend rules here
</backend_rules>
<backend>


<database>
Database section. Summarize database technology, then specify paths:
<database_paths>
- List database paths here
</database_paths>
</database>


<frontend>
Frontend section. Summarize frontend stack, then specify paths and rules:
<frontend_paths>
- List frontend paths here
</frontend_paths>
<frontend_rules>
- List frontend rules here
</frontend_rules>
<frontend>
```

WHEN TO USE
- Adding, updating, or removing entries in AGENTS.md
- Enforcing the exact plain text and tag syntax—never markdown or extra formatting


RULE QUALITY STANDARD
- Every rule must state one direct action.
- Every rule must name the target object or area.
- Every rule must use concrete words.
- Every rule must avoid vague terms such as proper, clear, robust, clean, or as needed.
- Every rule must stand alone without extra interpretation.
- Every rule must map to one behavior that can be checked.
- Never use the word if.

FILE STRUCTURE RULES
- Include only tags relevant to the project; omit tags for areas that do not exist in the project.
- Edit only lines requested by the user.
- Preserve all existing tag names exactly.
- Preserve tag order exactly as present in AGENTS.md.
- Preserve opening and closing tag pairs exactly as present in AGENTS.md.
- Preserve plain text style and bullet style already used in AGENTS.md.
- Keep top project description as plain text, not a tag block.
- Add no markdown headings.
- Add no code fences.
- Add no wrapper tags.
- Add no new section shape.

WORKFLOW
1. Identify the change (add, update, remove)
2. Edit AGENTS.md using ONLY the allowed tag syntax (see above)
3. Do NOT add markdown, chapter headers, or any formatting not present in AGENTS.md
4. If more detail is needed, reference a skill by name only—never inline details
5. Review to ensure the file remains strictly in the accepted format

COMPLETION CHECK
- All entries use only the allowed plain text and tag syntax
- No markdown, chapter headers, or extra formatting present
- The always-on context remains minimal and focused

