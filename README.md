# Ruby knowledge graph

An event-sourced knowledge graph engine written in Ruby on Rails. It takes
unstructured text (conference transcripts, meeting notes, sales calls,
book-club discussions, …) and turns it into a navigable graph of typed nodes
and relations, using an LLM as the extractor.

Every run of an LLM extraction is a first-class event, so the entire graph can
be rebuilt from the audit log at any time. Individual nodes and their
relations are derived read-models.

The live demo at <https://wrocloverb.rubygraph.dev> is configured for the
[wroc_love.rb](https://wrocloverb.com) conference — talks, speakers, tools,
events, takeaways, etc. **The engine itself is domain-agnostic**: by swapping
the ontology, prompts and content sources you can point it at any other
corpus.

## Stack

- Ruby 3.4, Rails 8.1
- Postgres 17 with pgvector for semantic search on nodes
- Rails Event Store (RES) for the event log and handlers
- Solid Queue (running in-Puma in production) for background jobs
- [RubyLLM][rubyllm] against Anthropic (Claude Opus 4.7 in prod, Haiku 4.5 in
  dev) for extraction; Ollama (`qwen3-embedding:4b`) for local embeddings
- [MCP][mcp] server exposing the graph to AI assistants (`/mcp`)
- Thruster + Puma in production, Kamal 2 for deployment

[rubyllm]: https://rubyllm.com
[mcp]: https://modelcontextprotocol.io

## Architecture

```
TranscriptIngested ──► BuildIngestion ──► Ingestion read-model
                   └─► RequestExtraction
ExtractionRequested ──► BuildExtraction ──► Extraction read-model
                    └─► ExtractKnowledge (job, calls Claude with tool-use)
KnowledgeExtracted ──► BuildKnowledgeGraph ──► Node / Edge read-models
```

The extraction prompt is composed from [a shared template][prompt] plus a
per-kind slice (`talk`, `panel`, `lightning-talks`, …) and a per-format slice. The ontology (node
kinds, relation types, attribute schemas) lives in
[`config/ontology.yml`](config/ontology.yml).

[prompt]: app/lib/prompts/extraction.md.erb

## Adapting to your own domain

The current live instance is configured for a Ruby conference, but everything
that makes it domain-specific lives in a handful of files. To point the
engine at a different corpus:

| What                                | Where                                          | What to change |
|-------------------------------------|------------------------------------------------|----------------|
| Node kinds, relation types, attrs   | [`config/ontology.yml`](config/ontology.yml)   | Replace `person/talk/event/tool/...` with kinds that fit your domain (e.g. `customer/ticket/product/feature/...` for support tickets). Relations must also be updated — they declare which source kinds may connect to which target kinds. |
| Per-kind prompt slices              | `app/lib/prompts/kinds/*.md`                   | Each input's `kind` field selects one of these. Add a new file (`kinds/<your-kind>.md`) describing the structure of that kind of document. |
| Per-format prompt slices            | `app/lib/prompts/formats/*.md`                 | Same idea for input format (`transcript`, `markdown`, …). |
| Seed domain data / starter nodes    | [`db/seeds.rb`](db/seeds.rb) + `NODES`/`EDGES` arrays | Replace hardcoded events/people/etc. with your own or empty the seed. |

Everything else (event sourcing, read-model builders, the extraction pipeline,
MCP server, web UI) is generic and should not need changes.

## Getting started

You'll need an `ANTHROPIC_API_KEY` in the environment for extraction to
work — set it in your shell before starting the app (for Dev Containers,
put it in `.env` or export it before opening the project).

### Dev Containers (recommended)

Open the project in VS Code or any IDE with Dev Containers support. The
`.devcontainer` spins up the Rails app, Postgres (with pgvector), and Ollama;
models are pulled on first boot.

```bash
# inside the container
bin/setup          # bundle + db:prepare + db:seed
bin/dev            # starts Rails
```

Visit <http://localhost:3000>.

### Locally without Dev Containers

You need Ruby 3.4.7, Postgres 17 with pgvector, and an Ollama instance with
the embedding model pulled, reachable via `OLLAMA_URL`:

```bash
ollama pull qwen3-embedding:4b
```

Then:

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed    # ingests files from transcripts/, skips auto-extraction
bin/rails server
```

Seeding only ingests the raw transcripts; it does not kick off LLM
extractions (the initializer detects `db:seed` and disables the
auto-extraction subscription so you can trigger runs manually afterwards).

## Testing

```bash
bundle exec rspec
```

External network calls are stubbed with WebMock.

## MCP

The MCP endpoint is mounted at `/mcp`. OAuth discovery is disabled on the
public demo (`.well-known/oauth-authorization-server` is commented out), so
clients can connect without credentials. Re-enable it in `config/routes.rb`
and `app/lib/mcp_rack_app.rb` for private deployments.

## License

The code in this repository is licensed under the MIT License. Transcripts
under `transcripts/` belong to their respective speakers; they are included
under fair-use for research and conference archival purposes.
