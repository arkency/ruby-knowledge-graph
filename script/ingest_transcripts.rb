# Usage: bin/rails runner script/ingest_transcripts.rb [folder]
# Example: bin/rails runner script/ingest_transcripts.rb weekly
#          bin/rails runner script/ingest_transcripts.rb          (all folders)

FOLDERS = {
  "meetings"   => "team-meeting",
  "book_club"  => "book-club",
  "sales_call" => "sales-call"
}.freeze

dir = Rails.root.join("transcripts")
event_store = Rails.configuration.event_store

folders = if ARGV.first
  { ARGV.first => FOLDERS.fetch(ARGV.first) }
else
  FOLDERS
end

files = folders.flat_map do |folder, kind|
  Dir.glob(dir.join(folder, "*.vtt")).map { |path| [path, kind] }
end

files.sort_by! { |path, _| File.basename(path) }

files.each do |path, kind|
  filename = File.basename(path)
  content = File.read(path)
  content_hash = Digest::SHA256.hexdigest(content)
  ingestion_id = SecureRandom.uuid

  # GMT20260220-125851_Recording.transcript.vtt → 2026-02-20 12:58:51 UTC
  match = filename.match(/GMT(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})/)
  unless match
    puts "  SKIP #{filename} — could not parse date"
    next
  end

  meeting_time = Time.utc(*match.captures.map(&:to_i))

  event = TranscriptIngested.new(
    data: {
      ingestion_id: ingestion_id,
      format: "transcript",
      kind: kind,
      content_hash: content_hash,
      content: content,
      external_id: filename,
      metadata: { filename: filename }
    },
    metadata: {
      valid_at: meeting_time
    }
  )

  begin
    event_store.publish(
      event,
      stream_name: "Ingestion$#{content_hash}",
      expected_version: :none
    )
    puts "  OK  #{filename} → #{kind} (valid_at: #{meeting_time.iso8601})"
  rescue RubyEventStore::WrongExpectedEventVersion
    puts "  DUP #{filename} — already ingested"
  end
end
