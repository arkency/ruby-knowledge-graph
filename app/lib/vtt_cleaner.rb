module VttCleaner
  # Strips VTT metadata (header, cue numbers, timestamps, blank lines)
  # keeping only "Speaker: text" lines for LLM extraction.
  #
  # Input:
  #   WEBVTT
  #
  #   1
  #   00:00:22.005 --> 00:00:24.689
  #   Andrzej: Sobie od 6 minut.
  #
  # Output:
  #   Andrzej: Sobie od 6 minut.
  def self.clean(content)
    return content unless content.start_with?("WEBVTT")

    content
      .sub(/\AWEBVTT\n*/, "")
      .gsub(/^\d+\n/, "")
      .gsub(/^\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3}\n/, "")
      .gsub(/\n{2,}/, "\n")
      .strip
  end
end
