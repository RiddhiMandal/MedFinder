module Tools
  class SearchKnowledgeBase < Base
    name_as "search_knowledge_base"
    description <<~DESC.squish
      Search the supplement knowledge base: short articles on what supplements do, forms,
      typical doses, timing, side effects and safety. Use this before answering any
      question about how a supplement works or how to take it, and cite the article ids
      you relied on. Pass a few keywords (e.g. "magnesium forms sleep"), not a full sentence.
    DESC
    input_schema(
      type: "object",
      properties: {
        query: { type: "string", description: "Keywords to search for." }
      },
      required: [ "query" ],
      additionalProperties: false
    )

    def call(input)
      query = require_string(input, "query")
      hits = Article.keyword_search(query, limit: 3)

      {
        query: query,
        results: hits.map { |article, score| article.to_tool_json.merge(relevance: score) },
        note: hits.empty? ? "No articles matched. Try different keywords, or tell the user the knowledge base doesn't cover this." : nil
      }.compact
    end
  end
end
