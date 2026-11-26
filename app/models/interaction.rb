# A known interaction between two substances (supplement, nutrient or drug
# class). Names are stored lowercase so lookups are simple.
class Interaction < ApplicationRecord
  SEVERITIES = %w[low moderate high].freeze

  validates :substance_a, :substance_b, :summary, presence: true
  validates :severity, inclusion: { in: SEVERITIES }

  before_validation { self.substance_a = substance_a&.downcase&.strip; self.substance_b = substance_b&.downcase&.strip }

  # Every stored interaction between any two of the given substances.
  # Matching is loose ("fish oil" matches "fish oil (omega-3)") so the agent
  # doesn't need to know our exact naming.
  def self.between(substances)
    names = substances.map { |s| s.to_s.downcase.strip }.reject(&:blank?).uniq
    all.select do |i|
      a = names.find { |n| loose_match?(i.substance_a, n) }
      b = names.find { |n| n != a && loose_match?(i.substance_b, n) }
      a && b
    end
  end

  def self.loose_match?(stored, given)
    stored.include?(given) || given.include?(stored)
  end

  def to_tool_json
    { between: [ substance_a, substance_b ], severity: severity, summary: summary }
  end
end
