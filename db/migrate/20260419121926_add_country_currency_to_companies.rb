class AddCountryCurrencyToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :country, :string
    add_column :companies, :currency, :string
    add_column :companies, :currency_symbol, :string
  end
end
