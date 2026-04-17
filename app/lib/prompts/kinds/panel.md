A panel discussion — multiple panelists discussing a topic, usually moderated by a host.
Extract a single talk node (type: panel) representing the panel itself, and capture all participants as persons with `authored` edges.
Use the edge `context` to distinguish panelists from the moderator (e.g. "moderator", "panelist on cloud strategy").
Audience questions from Q&A should be extracted as question nodes with `asked_at` edges to the panel.
