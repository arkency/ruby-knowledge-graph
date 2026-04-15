# Captures node and edge IDs read by tools during extraction. Tools pass DB ids
# here as a side-channel, so the LLM-facing tool result can stay free of UUIDs
# while we still build accurate provenance.
class ExtractionReadCollector
  def initialize
    @read_set = Hash.new { |h, k| h[k] = Set.new }
    @edge_reads = Set.new
  end

  def searched(node_ids, tool_name)
    Array(node_ids).each { |id| @read_set[id] << tool_name if id }
  end

  def edges_inspected(anchor_id, edge_ids)
    return unless anchor_id
    @read_set[anchor_id] << "get_node_edges"
    Array(edge_ids).each { |id| @edge_reads << id if id }
  end

  def read_set
    @read_set.map { |node_id, tools| { node_id: node_id, tools: tools.to_a } }
  end

  def edge_reads
    @edge_reads.to_a
  end
end
