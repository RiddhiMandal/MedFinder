require "test_helper"

class ToolsTest < ActiveSupport::TestCase
  test "every tool has a name, description and object schema" do
    SupplementAssistant::TOOLS.each do |tool|
      definition = tool.definition
      assert definition[:name].present?
      assert definition[:description].length > 40, "#{tool} needs a useful description"
      assert_equal "object", definition[:input_schema][:type]
    end
  end

  test "search_knowledge_base ranks the matching article first" do
    result = Tools::SearchKnowledgeBase.new.call("query" => "magnesium sleep")
    assert_equal articles(:magnesium).id, result[:results].first[:id]
  end

  test "search_knowledge_base explains when nothing matches" do
    result = Tools::SearchKnowledgeBase.new.call("query" => "kombucha")
    assert_empty result[:results]
    assert_match(/No articles matched/, result[:note])
  end

  test "search_products filters by stock and price" do
    tool = Tools::SearchProducts.new
    all = tool.call("query" => "magnesium")[:results].map { _1[:name] }
    assert_includes all, "Magnesium Oxide 400"

    in_stock = tool.call("query" => "magnesium", "in_stock_only" => true)[:results].map { _1[:name] }
    assert_equal [ "Magnesium Glycinate 120 mg" ], in_stock

    cheap = tool.call("query" => "magnesium", "max_price_dollars" => 10)[:results].map { _1[:name] }
    assert_equal [ "Magnesium Oxide 400" ], cheap
  end

  test "check_interactions matches loose names in either order" do
    result = Tools::CheckInteractions.new.call("substances" => [ "warfarin", "fish oil" ])
    assert_equal 1, result[:interactions].size
    assert_equal "moderate", result[:interactions].first[:severity]
  end

  test "check_interactions says an empty result is not proof of safety" do
    result = Tools::CheckInteractions.new.call("substances" => [ "b12", "magnesium" ])
    assert_empty result[:interactions]
    assert_match(/not proof/, result[:note])
  end

  test "tools reject bad input with InputError" do
    assert_raises(Tools::InputError) { Tools::SearchProducts.new.call("query" => "  ") }
    assert_raises(Tools::InputError) { Tools::CheckInteractions.new.call("substances" => [ "iron" ]) }
    assert_raises(Tools::InputError) { Tools::SearchProducts.new.call("query" => "b12", "max_price_dollars" => -1) }
  end
end
