class Product < ApplicationRecord
  include KeywordSearchable

  search_columns name: 5, tags: 4, category: 3, ingredients: 3, description: 1, form: 1

  validates :name, :brand, :category, presence: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }

  scope :in_stock, -> { where(in_stock: true) }

  def price
    format("$%.2f", price_cents / 100.0)
  end

  # The shape the agent sees. Keep it small: everything here costs tokens.
  def to_tool_json
    {
      id: id,
      name: name,
      brand: brand,
      category: category,
      form: form,
      serving_size: serving_size,
      price: price,
      in_stock: in_stock,
      ingredients: ingredients,
      description: description
    }
  end
end
