# Usage: bin/rails runner script/ingest_fake_transcript.rb
#
# Publishes a short fake TranscriptIngested event to test
# the extraction pipeline with SearchNodes tool use.

transcript = <<~VTT
  [10:00] Alice: Hi everyone, let's do a quick recap of wroclove.rb day one.
  [10:01] Bob: The JRuby talk by Charles Nutter was great. He showed how JRuby handles concurrency way better than CRuby for certain workloads.
  [10:02] Alice: Agreed. I also really liked Ismael Celis's talk on event sourcing and the actor model. He combined both patterns elegantly.
  [10:03] Carol: I went to the mutation testing workshop by Markus Schirp. Setting up Mutant was easier than I expected. We should try it on our project.
  [10:04] Bob: Good idea. What about the deployment talk? Josef Strzibny made a strong case for Kamal over PaaS solutions.
  [10:05] Alice: Yes, especially the cost comparison. We're paying too much for Heroku. Let's evaluate Kamal for our next deploy.
  [10:06] Carol: One more — Sharon Rosner's UringMachine talk was mind-blowing. The io_uring benchmarks were 10x faster than traditional I/O.
  [10:07] Bob: I want to experiment with that. Could be useful for our websocket server.
  [10:08] Alice: OK, action items: Carol evaluates Mutant, Bob looks into UringMachine, I'll do a Kamal spike. Let's sync next week.
  [10:08] Carol: Sounds good.
  [10:09] Bob: Done.
VTT

content_hash = Digest::SHA256.hexdigest(transcript)
ingestion_id = SecureRandom.uuid

event = TranscriptIngested.new(
  data: {
    ingestion_id: ingestion_id,
    format: "fake",
    kind: "team-meeting",
    content_hash: content_hash,
    content: transcript,
    external_id: "fake_weekly_test",
    metadata: { filename: "fake_weekly_test.vtt" }
  },
  metadata: {
    valid_at: Time.current
  }
)

event_store = Rails.configuration.event_store

begin
  event_store.publish(
    event,
    stream_name: "Ingestion$#{content_hash}",
    expected_version: :none
  )
  puts "Published TranscriptIngested (ingestion_id: #{ingestion_id})"
  puts "Content hash: #{content_hash}"
  puts "Now run the job: ExtractKnowledge.perform_now(event)"
rescue RubyEventStore::WrongExpectedEventVersion
  puts "Already ingested — delete stream first or change transcript"
end
