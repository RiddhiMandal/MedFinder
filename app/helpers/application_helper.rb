module ApplicationHelper
  MARKDOWN = Redcarpet::Markdown.new(
    Redcarpet::Render::HTML.new(filter_html: true, no_images: true, safe_links_only: true),
    autolink: true, tables: true, strikethrough: true, no_intra_emphasis: true
  )

  # Renders the model's Markdown answer, then turns citations like [KB #3]
  # and [Product #12] into small badges.
  def render_answer(text)
    html = MARKDOWN.render(text.to_s)
    html = html.gsub(/\[(KB|Product) #(\d+)\]/) do
      kind, id = Regexp.last_match(1), Regexp.last_match(2)
      %(<span class="cite cite-#{kind.downcase}" title="#{kind == "KB" ? "Knowledge base article" : "Catalog product"} ##{id}">#{kind} ##{id}</span>)
    end
    sanitize(html, tags: %w[p ul ol li strong em code pre a h3 h4 table thead tbody tr th td br span del blockquote],
                   attributes: %w[href class title])
  end

  STEP_LABELS = {
    "reasoning" => "Reasoning",
    "note" => "Plan",
    "tool_call" => "Tool call",
    "tool_result" => "Tool result",
    "answer" => "Answer"
  }.freeze

  def step_label(step) = STEP_LABELS.fetch(step["type"], step["type"].to_s.humanize)

  # One-line summary of a tool result for the collapsed view.
  def tool_result_summary(step)
    output = step["output"] || {}
    return "Error: #{output["error"]}" if step["error"]

    case step["tool"]
    when "search_knowledge_base"
      titles = Array(output["results"]).map { |r| "##{r["id"]} #{r["title"]}" }
      titles.any? ? "Found #{titles.size}: #{titles.join("; ")}" : "No articles found"
    when "search_products"
      names = Array(output["results"]).map { |r| "#{r["name"]} (#{r["price"]}#{r["in_stock"] ? "" : ", out of stock"})" }
      names.any? ? "#{names.size} products: #{names.join("; ")}" : "No products found"
    when "check_interactions"
      found = Array(output["interactions"])
      found.any? ? found.map { |i| "#{i["severity"]}: #{i["between"].join(" + ")}" }.join("; ") : "No recorded interactions"
    else
      output.to_json.truncate(160)
    end
  end
end
