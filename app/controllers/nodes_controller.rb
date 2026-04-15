class NodesController < ApplicationController
  def index
    @kind_counts = Node.group(:kind).order(:kind).count
    @query = params[:q].to_s.strip

    if @query.length >= 2
      @nodes = Node.hybrid_search(@query)
      @current_kind = nil
    else
      @current_kind = params[:kind] || @kind_counts.keys.first
      @nodes = Node.where(kind: @current_kind).order(Arel.sql("outgoing_edges_count + incoming_edges_count DESC, name"))
    end
  end

  def show
    @node = Node.includes(:creating_extraction, :last_updating_extraction)
                .find_by!(slug: params[:slug])
    outgoing = @node.outgoing_edges.includes(:source_node, :target_node)
    incoming = @node.incoming_edges.includes(:source_node, :target_node)
    @edges_by_relation = (outgoing + incoming)
      .group_by(&:relation)
      .sort_by { |relation, _| relation }
  end
end
