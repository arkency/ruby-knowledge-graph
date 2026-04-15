class NodeAlias < ApplicationRecord
  belongs_to :node
  validates :name, presence: true
end
