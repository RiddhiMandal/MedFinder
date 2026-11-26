module Tools
  class SearchProducts < Base
    name_as "search_products"
    description <<~DESC.squish
      Look up products in the store's catalog database. Returns matching products with id,
      brand, form, serving size, price, stock status and ingredients. Use it whenever the
      user asks for a product, a recommendation, a price, or what is in stock. Only
      recommend products this tool returns; never invent products.
    DESC
    input_schema(
      type: "object",
      properties: {
        query: { type: "string", description: "Keywords, e.g. \"magnesium glycinate\" or \"vegan omega-3\"." },
        max_price_dollars: { type: "number", description: "Only return products at or below this price." },
        in_stock_only: { type: "boolean", description: "Only return products that are in stock. Defaults to false." }
      },
      required: [ "query" ],
      additionalProperties: false
    )

    def call(input)
      query = require_string(input, "query")
      scope = Product.all
      scope = scope.in_stock if input["in_stock_only"] == true

      if (max = input["max_price_dollars"])
        raise InputError, "`max_price_dollars` must be a positive number" unless max.is_a?(Numeric) && max.positive?

        scope = scope.where(price_cents: ..(max * 100).round)
      end

      hits = Product.keyword_search(query, scope: scope, limit: 5)
      {
        query: query,
        filters: input.slice("max_price_dollars", "in_stock_only"),
        results: hits.map { |product, _score| product.to_tool_json },
        note: hits.empty? ? "No products matched these filters." : nil
      }.compact
    end
  end
end
