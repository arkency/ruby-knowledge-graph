NODES = [
  # --- Event ---
  { name: "wroclove.rb 2026", kind: "event", short_description: "Ruby conference in Wrocław, April 2026.", description: "3-day, single-track, non-profit Ruby conference. 12 talks + 4 workshops.", attrs: { "scope" => "external", "type" => "conference", "format" => "in-person", "date" => "2026-04-17", "location" => "Wrocław, Poland" } },

  # --- Speakers ---
  { name: "Charles Nutter", kind: "person", short_description: "JRuby co-creator.", description: "Co-creator of JRuby, long-time Ruby and JVM community member." },
  { name: "Josef Strzibny", kind: "person", short_description: "Author of Deployment from Scratch.", description: "Developer and author focused on deployment and infrastructure." },
  { name: "Markus Schirp", kind: "person", short_description: "Creator of Mutant, mutation testing expert.", description: "Creator of Mutant — mutation testing tool for Ruby." },
  { name: "Ismael Celis", kind: "person", short_description: "Ruby developer, event sourcing practitioner.", description: "Ruby developer exploring event sourcing and actor model patterns." },
  { name: "Louis Antonopoulos", kind: "person", short_description: "Ruby developer.", description: "Ruby developer, speaker on Ractor and concurrency." },
  { name: "Sharon Rosner", kind: "person", short_description: "Creator of Polyphony and UringMachine.", description: "Ruby developer focused on high-performance concurrency with io_uring." },
  { name: "Adam Okoń", kind: "person", short_description: "Ruby developer, agentic workflows.", description: "Ruby developer building agentic AI workflows." },
  { name: "Julik Tarkhanov", kind: "person", short_description: "Ruby developer, durable execution.", description: "Ruby developer exploring durable execution patterns." },
  { name: "Kuba Suder", kind: "person", short_description: "macOS/iOS and Ruby developer.", description: "Developer building on Bluesky's AT Protocol with Ruby." },
  { name: "Emiliano Della Casa", kind: "person", short_description: "Ruby developer, alternative protocols.", description: "Ruby developer working with alternative protocols beyond REST." },
  { name: "Ryan Townsend", kind: "person", short_description: "Ruby developer, no-build frontend.", description: "Ruby developer advocating modern UX with Rails and web standards." },
  { name: "Nicolò Rebughini", kind: "person", short_description: "Ruby developer, ML in Ruby.", description: "Ruby developer who accidentally built a neural network for product recommendations." },
  { name: "Greg Molnar", kind: "person", short_description: "Rails security expert.", description: "Rails security consultant and workshop facilitator." },
  { name: "Paweł Strzałkowski", kind: "person", short_description: "Ruby developer, AI and MCP.", description: "Ruby developer building production AI apps with MCP and OAuth." },
  { name: "Andy Maleh", kind: "person", short_description: "Creator of Glimmer DSL.", description: "Creator of Glimmer DSL, building Rails SPAs with web components." },

  # --- Talks ---
  { name: "JRuby: Professional-Grade Ruby", kind: "talk", short_description: "Talk on JRuby's capabilities.", description: "Talk by Charles Nutter on JRuby as a professional-grade Ruby implementation.", attrs: { "type" => "talk", "status" => "delivered" } },
  { name: "Kamal is not harder than your PaaS", kind: "talk", short_description: "Talk on Kamal deployment.", description: "Talk by Josef Strzibny on using Kamal for deployment.", attrs: { "type" => "talk", "status" => "delivered" } },
  { name: "My core skill never was the typing", kind: "talk", short_description: "Talk on mutation testing philosophy.", description: "Talk by Markus Schirp on the philosophy behind mutation testing and software quality.", attrs: { "type" => "talk", "status" => "delivered" } },
  { name: "Event Sourcing and Actor model in Ruby", kind: "talk", short_description: "Talk on event sourcing and actors.", description: "Talk by Ismael Celis on combining event sourcing with the actor model in Ruby.", attrs: { "type" => "talk", "status" => "delivered" } },
  { name: "Rubyana Gems and the Ractorous Rubetta Stones!", kind: "talk", short_description: "Talk on Ractor and concurrency.", description: "Talk by Louis Antonopoulos on Ruby's Ractor and concurrency gems.", attrs: { "type" => "talk", "status" => "delivered" } },
  { name: "Accidentally building a neural network — A Ruby product recommendation journey", kind: "talk", short_description: "Talk on ML product recommendations in Ruby.", description: "Talk by Nicolò Rebughini on accidentally building a neural network for product recommendations in Ruby.", attrs: { "type" => "talk", "status" => "delivered" } },
  { name: "UringMachine — High Performance Concurrency for Ruby Using io_uring", kind: "talk", short_description: "Talk on io_uring concurrency in Ruby.", description: "Talk by Sharon Rosner on UringMachine — high performance concurrency for Ruby using io_uring.", attrs: { "type" => "talk", "status" => "delivered" } },
  { name: "Forms Are Dead: Building Agentic Workflows in Ruby", kind: "talk", short_description: "Talk on agentic AI workflows.", description: "Talk by Adam Okoń on building agentic workflows in Ruby to replace traditional forms.", attrs: { "type" => "talk", "status" => "delivered" } },
  { name: "Adventures in durable execution", kind: "talk", short_description: "Talk on durable execution patterns.", description: "Talk by Julik Tarkhanov on durable execution patterns.", attrs: { "type" => "talk", "status" => "delivered" } },
  { name: "Building on Bluesky's AT Protocol with Ruby", kind: "talk", short_description: "Talk on AT Protocol and Ruby.", description: "Talk by Kuba Suder on building applications using Bluesky's AT Protocol with Ruby.", attrs: { "type" => "talk", "status" => "delivered" } },
  { name: "When REST is Not Enough: Implementing Alternative Protocols in Ruby on Rails", kind: "talk", short_description: "Talk on alternative protocols in Ruby on Rails.", description: "Talk by Emiliano Della Casa on implementing alternative protocols beyond REST in Ruby on Rails.", attrs: { "type" => "talk", "status" => "delivered" } },
  { name: "No-build Utopia: Modern User Experiences with Rails & Web Standards", kind: "talk", short_description: "Talk on no-build frontend with Rails.", description: "Talk by Ryan Townsend on building modern UX with Rails and web standards without a build step.", attrs: { "type" => "talk", "status" => "delivered" } },

  # --- Workshops ---
  { name: "Setup and operation of mutation testing in agentic world", kind: "talk", short_description: "Workshop on mutation testing in agentic world.", description: "Workshop by Markus Schirp on setup and operation of mutation testing in the agentic world.", attrs: { "type" => "workshop", "status" => "delivered" } },
  { name: "Securing Rails applications", kind: "talk", short_description: "Workshop on Rails security.", description: "Workshop by Greg Molnar on securing Rails applications.", attrs: { "type" => "workshop", "status" => "delivered" } },
  { name: "Building a Production-Ready AI App: MCP & OAuth on Rails", kind: "talk", short_description: "Workshop on AI apps with MCP and OAuth.", description: "Workshop by Paweł Strzałkowski on building a production-ready AI app with MCP and OAuth on Rails.", attrs: { "type" => "workshop", "status" => "delivered" } },
  { name: "Building Rails SPAs in Frontend Ruby with Glimmer DSL for Web", kind: "talk", short_description: "Workshop on Glimmer DSL for Web.", description: "Workshop by Andy Maleh on building Rails SPAs in frontend Ruby with Glimmer DSL for Web.", attrs: { "type" => "workshop", "status" => "delivered" } },

  # --- Sponsors ---
  { name: "Railsware", kind: "company", short_description: "Product engineering company.", description: "Product engineering and consulting company." },
  { name: "Typesense", kind: "company", short_description: "Open-source search engine.", description: "Open-source, typo-tolerant search engine.", attrs: { "industry" => "search" } },
  { name: "Infakt", kind: "company", short_description: "Polish invoicing and accounting platform.", description: "Polish invoicing and accounting SaaS platform.", attrs: { "industry" => "fintech" } },

  # --- Tools ---
  { name: "Ruby", kind: "tool", short_description: "Programming language.", description: "Programming language.", attrs: { "category" => "framework" } },
  { name: "Rails", kind: "tool", short_description: "Web framework for Ruby.", description: "Web application framework for Ruby.", attrs: { "category" => "framework" } },
  { name: "JRuby", kind: "tool", short_description: "Ruby on the JVM.", description: "Ruby implementation running on the Java Virtual Machine.", attrs: { "category" => "platform" } },
  { name: "Kamal", kind: "tool", short_description: "Zero-downtime deployment tool.", description: "Deployment tool for web applications using Docker, created by 37signals.", attrs: { "category" => "service" } },
  { name: "Mutant", kind: "tool", short_description: "Mutation testing tool for Ruby.", description: "Mutation testing tool for Ruby — measures test suite effectiveness.", attrs: { "category" => "library" } },
  { name: "Ractor", kind: "tool", short_description: "Ruby's actor-based concurrency.", description: "Ruby's built-in actor-based parallel execution mechanism.", attrs: { "category" => "library" } },
  { name: "Glimmer DSL", kind: "tool", short_description: "DSL for building desktop and web GUIs.", description: "Ruby DSL framework for building desktop and web user interfaces.", attrs: { "category" => "framework" } },

  # --- Concepts ---
  { name: "Event Sourcing", kind: "concept", short_description: "State from sequence of events.", description: "Architectural pattern — system state reconstructed from a sequence of events.", attrs: { "category" => "architecture" } },
  { name: "Actor Model", kind: "concept", short_description: "Concurrency model using message-passing actors.", description: "Concurrency model where actors are the fundamental unit of computation, communicating via messages.", attrs: { "category" => "architecture" } },
  { name: "Mutation Testing", kind: "concept", short_description: "Testing tests by injecting faults.", description: "Quality assurance technique — systematically modifying code (mutants) to verify that tests detect changes.", attrs: { "category" => "practice" } },
  { name: "Durable Execution", kind: "concept", short_description: "Fault-tolerant workflow execution.", description: "Pattern for running workflows that survive process crashes and restarts.", attrs: { "category" => "architecture" } },
  { name: "Concurrency", kind: "concept", short_description: "Executing multiple tasks simultaneously.", description: "Techniques for executing multiple tasks simultaneously — threads, fibers, actors, io_uring.", attrs: { "category" => "architecture" } },
  { name: "Agentic Workflows", kind: "concept", short_description: "AI agents performing multi-step tasks.", description: "AI-driven workflows where agents autonomously perform multi-step tasks.", attrs: { "category" => "pattern" } },

  # --- Projects ---
  { name: "UringMachine", kind: "project", short_description: "High-performance Ruby concurrency via io_uring.", description: "Ruby library for high-performance concurrency using Linux's io_uring interface.", attrs: { "license" => "open-source", "status" => "active" } },
  { name: "Bluesky AT Protocol", kind: "project", short_description: "Decentralized social networking protocol.", description: "Open protocol for decentralized social networking, created by Bluesky.", attrs: { "license" => "open-source", "status" => "active" } },
]

EDGES = [
  # --- authored (talks) ---
  { source: "Charles Nutter", target: "JRuby: Professional-Grade Ruby", relation: "authored" },
  { source: "Josef Strzibny", target: "Kamal is not harder than your PaaS", relation: "authored" },
  { source: "Markus Schirp", target: "My core skill never was the typing", relation: "authored" },
  { source: "Ismael Celis", target: "Event Sourcing and Actor model in Ruby", relation: "authored" },
  { source: "Louis Antonopoulos", target: "Rubyana Gems and the Ractorous Rubetta Stones!", relation: "authored" },
  { source: "Nicolò Rebughini", target: "Accidentally building a neural network — A Ruby product recommendation journey", relation: "authored" },
  { source: "Sharon Rosner", target: "UringMachine — High Performance Concurrency for Ruby Using io_uring", relation: "authored" },
  { source: "Adam Okoń", target: "Forms Are Dead: Building Agentic Workflows in Ruby", relation: "authored" },
  { source: "Julik Tarkhanov", target: "Adventures in durable execution", relation: "authored" },
  { source: "Kuba Suder", target: "Building on Bluesky's AT Protocol with Ruby", relation: "authored" },
  { source: "Emiliano Della Casa", target: "When REST is Not Enough: Implementing Alternative Protocols in Ruby on Rails", relation: "authored" },
  { source: "Ryan Townsend", target: "No-build Utopia: Modern User Experiences with Rails & Web Standards", relation: "authored" },
  { source: "Markus Schirp", target: "Setup and operation of mutation testing in agentic world", relation: "authored" },
  { source: "Greg Molnar", target: "Securing Rails applications", relation: "authored" },
  { source: "Paweł Strzałkowski", target: "Building a Production-Ready AI App: MCP & OAuth on Rails", relation: "authored" },
  { source: "Andy Maleh", target: "Building Rails SPAs in Frontend Ruby with Glimmer DSL for Web", relation: "authored" },

  # --- presented_at ---
  { source: "JRuby: Professional-Grade Ruby", target: "wroclove.rb 2026", relation: "presented_at" },
  { source: "Kamal is not harder than your PaaS", target: "wroclove.rb 2026", relation: "presented_at" },
  { source: "My core skill never was the typing", target: "wroclove.rb 2026", relation: "presented_at" },
  { source: "Event Sourcing and Actor model in Ruby", target: "wroclove.rb 2026", relation: "presented_at" },
  { source: "Rubyana Gems and the Ractorous Rubetta Stones!", target: "wroclove.rb 2026", relation: "presented_at" },
  { source: "Accidentally building a neural network — A Ruby product recommendation journey", target: "wroclove.rb 2026", relation: "presented_at" },
  { source: "UringMachine — High Performance Concurrency for Ruby Using io_uring", target: "wroclove.rb 2026", relation: "presented_at" },
  { source: "Forms Are Dead: Building Agentic Workflows in Ruby", target: "wroclove.rb 2026", relation: "presented_at" },
  { source: "Adventures in durable execution", target: "wroclove.rb 2026", relation: "presented_at" },
  { source: "Building on Bluesky's AT Protocol with Ruby", target: "wroclove.rb 2026", relation: "presented_at" },
  { source: "When REST is Not Enough: Implementing Alternative Protocols in Ruby on Rails", target: "wroclove.rb 2026", relation: "presented_at" },
  { source: "No-build Utopia: Modern User Experiences with Rails & Web Standards", target: "wroclove.rb 2026", relation: "presented_at" },
  { source: "Setup and operation of mutation testing in agentic world", target: "wroclove.rb 2026", relation: "presented_at" },
  { source: "Securing Rails applications", target: "wroclove.rb 2026", relation: "presented_at" },
  { source: "Building a Production-Ready AI App: MCP & OAuth on Rails", target: "wroclove.rb 2026", relation: "presented_at" },
  { source: "Building Rails SPAs in Frontend Ruby with Glimmer DSL for Web", target: "wroclove.rb 2026", relation: "presented_at" },

  # --- attended (speakers) ---
  { source: "Charles Nutter", target: "wroclove.rb 2026", relation: "attended", attrs: { "role" => "speaker" } },
  { source: "Josef Strzibny", target: "wroclove.rb 2026", relation: "attended", attrs: { "role" => "speaker" } },
  { source: "Markus Schirp", target: "wroclove.rb 2026", relation: "attended", attrs: { "role" => "speaker" } },
  { source: "Ismael Celis", target: "wroclove.rb 2026", relation: "attended", attrs: { "role" => "speaker" } },
  { source: "Louis Antonopoulos", target: "wroclove.rb 2026", relation: "attended", attrs: { "role" => "speaker" } },
  { source: "Nicolò Rebughini", target: "wroclove.rb 2026", relation: "attended", attrs: { "role" => "speaker" } },
  { source: "Sharon Rosner", target: "wroclove.rb 2026", relation: "attended", attrs: { "role" => "speaker" } },
  { source: "Adam Okoń", target: "wroclove.rb 2026", relation: "attended", attrs: { "role" => "speaker" } },
  { source: "Julik Tarkhanov", target: "wroclove.rb 2026", relation: "attended", attrs: { "role" => "speaker" } },
  { source: "Kuba Suder", target: "wroclove.rb 2026", relation: "attended", attrs: { "role" => "speaker" } },
  { source: "Emiliano Della Casa", target: "wroclove.rb 2026", relation: "attended", attrs: { "role" => "speaker" } },
  { source: "Ryan Townsend", target: "wroclove.rb 2026", relation: "attended", attrs: { "role" => "speaker" } },
  { source: "Greg Molnar", target: "wroclove.rb 2026", relation: "attended", attrs: { "role" => "speaker" } },
  { source: "Paweł Strzałkowski", target: "wroclove.rb 2026", relation: "attended", attrs: { "role" => "speaker" } },
  { source: "Andy Maleh", target: "wroclove.rb 2026", relation: "attended", attrs: { "role" => "speaker" } },

  # --- sponsors ---
  { source: "Railsware", target: "wroclove.rb 2026", relation: "sponsors" },
  { source: "Typesense", target: "wroclove.rb 2026", relation: "sponsors" },
  { source: "Infakt", target: "wroclove.rb 2026", relation: "sponsors" },

  # --- about (talks → concepts/tools) ---
  { source: "JRuby: Professional-Grade Ruby", target: "JRuby", relation: "about" },
  { source: "JRuby: Professional-Grade Ruby", target: "Ruby", relation: "about" },
  { source: "Kamal is not harder than your PaaS", target: "Kamal", relation: "about" },
  { source: "My core skill never was the typing", target: "Mutation Testing", relation: "about" },
  { source: "My core skill never was the typing", target: "Mutant", relation: "about" },
  { source: "Event Sourcing and Actor model in Ruby", target: "Event Sourcing", relation: "about" },
  { source: "Event Sourcing and Actor model in Ruby", target: "Actor Model", relation: "about" },
  { source: "Rubyana Gems and the Ractorous Rubetta Stones!", target: "Ractor", relation: "about" },
  { source: "Rubyana Gems and the Ractorous Rubetta Stones!", target: "Concurrency", relation: "about" },
  { source: "UringMachine — High Performance Concurrency for Ruby Using io_uring", target: "UringMachine", relation: "about" },
  { source: "UringMachine — High Performance Concurrency for Ruby Using io_uring", target: "Concurrency", relation: "about" },
  { source: "Forms Are Dead: Building Agentic Workflows in Ruby", target: "Agentic Workflows", relation: "about" },
  { source: "Adventures in durable execution", target: "Durable Execution", relation: "about" },
  { source: "Building on Bluesky's AT Protocol with Ruby", target: "Bluesky AT Protocol", relation: "about" },
  { source: "No-build Utopia: Modern User Experiences with Rails & Web Standards", target: "Rails", relation: "about" },
  { source: "When REST is Not Enough: Implementing Alternative Protocols in Ruby on Rails", target: "Rails", relation: "about" },
  { source: "Setup and operation of mutation testing in agentic world", target: "Mutation Testing", relation: "about" },
  { source: "Setup and operation of mutation testing in agentic world", target: "Mutant", relation: "about" },
  { source: "Securing Rails applications", target: "Rails", relation: "about" },
  { source: "Building Rails SPAs in Frontend Ruby with Glimmer DSL for Web", target: "Glimmer DSL", relation: "about" },
  { source: "Building Rails SPAs in Frontend Ruby with Glimmer DSL for Web", target: "Rails", relation: "about" },

  # --- works_on ---
  { source: "Charles Nutter", target: "JRuby", relation: "works_on", context: "Co-creator and maintainer", attrs: { "role" => "co-creator" } },
  { source: "Markus Schirp", target: "Mutant", relation: "works_on", context: "Creator and maintainer", attrs: { "role" => "creator" } },
  { source: "Sharon Rosner", target: "UringMachine", relation: "works_on", context: "Creator", attrs: { "role" => "creator" } },

  # --- has_skill ---
  { source: "Markus Schirp", target: "Mutation Testing", relation: "has_skill", attrs: { "level" => "expert" } },
  { source: "Charles Nutter", target: "Concurrency", relation: "has_skill", attrs: { "level" => "expert" } },
  { source: "Sharon Rosner", target: "Concurrency", relation: "has_skill", attrs: { "level" => "expert" } },
  { source: "Ismael Celis", target: "Event Sourcing", relation: "has_skill", attrs: { "level" => "expert" } },

  # --- related_to ---
  { source: "Mutant", target: "Mutation Testing", relation: "related_to", context: "Ruby implementation of mutation testing" },
  { source: "UringMachine", target: "Concurrency", relation: "related_to", context: "io_uring-based concurrency for Ruby" },
  { source: "Ractor", target: "Actor Model", relation: "related_to", context: "Ruby's implementation of actor-based concurrency" },
]

ALIASES = {
  "Kuba Suder" => ["Jakub Suder"],
  "Markus Schirp" => ["mbj"],
}

# --- Seed nodes ---
nodes_by_name = {}
NODES.each do |data|
  slug = data[:name].parameterize
  node = Node.find_or_initialize_by(slug: slug)
  node.assign_attributes(name: data[:name], kind: data[:kind], short_description: data[:short_description], description: data[:description], attrs: (node.attrs || {}).merge(data[:attrs] || {}))
  node.save!
  nodes_by_name[data[:name]] = node

  begin
    text = node.short_description.present? ? "#{node.name} — #{node.short_description}" : "#{node.name} (#{node.kind})"
    response = RubyLLM.embed(text, model: "qwen3-embedding:4b", provider: :ollama, assume_model_exists: true)
    node.update_columns(embedding: "[#{response.vectors.join(",")}]")
    print "\rEmbedded #{nodes_by_name.size} nodes..."
  rescue => e
    puts "\nFailed to embed #{data[:name]}: #{e.message}"
  end
end
puts "\nNodes seeded: #{Node.count}"

# --- Seed edges ---
EDGES.each do |data|
  source = nodes_by_name[data[:source]]
  target = nodes_by_name[data[:target]]
  next unless source && target
  edge = Edge.find_or_initialize_by(source_node: source, target_node: target, relation: data[:relation])
  edge.context = data[:context] if data[:context]
  edge.attrs = (edge.attrs || {}).merge(data[:attrs] || {}) if data[:attrs]
  edge.save!
end
puts "Edges seeded: #{Edge.count}"

# --- Seed aliases ---
ALIASES.each do |canonical, alias_names|
  node = nodes_by_name[canonical]
  next unless node
  alias_names.each do |alias_name|
    NodeAlias.find_or_create_by!(node: node, name: alias_name)
  end
end
puts "Aliases seeded: #{NodeAlias.count}"
