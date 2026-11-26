module Tools
  class CheckInteractions < Base
    name_as "check_interactions"
    description <<~DESC.squish
      Check the interactions database for known interactions between two or more
      substances: supplements, nutrients or medication types (e.g. ["iron", "calcium"] or
      ["fish oil", "warfarin"]). Call this whenever the user mentions taking more than one
      thing together or mentions any medication. An empty result means no interaction is
      recorded in this small database, not that the combination is safe.
    DESC
    input_schema(
      type: "object",
      properties: {
        substances: {
          type: "array",
          items: { type: "string" },
          description: "Two or more substance names."
        }
      },
      required: [ "substances" ],
      additionalProperties: false
    )

    def call(input)
      substances = Array(input["substances"]).grep(String).map(&:strip).reject(&:empty?)
      raise InputError, "`substances` must list at least two names" if substances.size < 2

      found = Interaction.between(substances)
      {
        checked: substances,
        interactions: found.map(&:to_tool_json),
        note: found.empty? ? "No interaction recorded in this database. That is not proof the combination is safe; suggest checking with a pharmacist." : nil
      }.compact
    end
  end
end
