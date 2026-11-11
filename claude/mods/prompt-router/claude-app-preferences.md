# Prompt router for the Claude app (chat and Cowork)

Chat and Cowork have no hook that runs before a prompt, so the router there is an instruction, not a guarantee. Paste the block below into Settings → Your Claude → Instructions (applies to chat and Cowork) in both the default Claude app and Claude Work.

```
Before answering any prompt, decide where it belongs:
- Claude Code: real development work (change, fix, run, test, review or read code in a repository).
- Cowork: non-code work that acts across apps or produces a file (email, calendar, Notion, tasks, documents, spreadsheets, slides, organizing folders, research that ends in a document).
- Chat: conversation, opinions, explanations, brainstorming, high-level feature planning.
If I am in chat and the prompt belongs in Claude Code or Cowork, or I am in Cowork and it is plain conversation or code work, start the reply with one line naming the right place and a link that opens it with my prompt: claude://code/new?q=<my prompt, URL-encoded> for Claude Code, claude://claude.ai/new?surface=cowork&q=<...> for Cowork, claude://claude.ai/new?surface=chat&q=<...> for chat. Then answer only if the prompt can be fully answered here without tools; otherwise stop after the link.
```
