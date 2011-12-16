module Spree
  class TaxRate < ActiveRecord::Base
    belongs_to :zone
    belongs_to :tax_category

    validates :amount, :presence => true, :numericality => true
    validates :tax_category_id, :presence => true

    calculated_adjustments
    scope :by_zone, lambda { |zone| where(:zone_id => zone) }

    # Gets the array of TaxRates appropriate for the specified order
    def self.match(order)
      all.select { |rate| rate.zone == order.tax_zone }
    end

    # For Vat the default rate is the rate that is configured for the default category
    # It is needed for every price calculation (as all customer facing prices include vat )
    # The function returns the actual amount, which may be 0 in case of wrong setup, but is never nil
    def self.default
      category = TaxCategory.includes(:tax_rates).where(:is_default => true).first
      return 0 unless category

      category.effective_amount || 0
    end

    # Creates necessary tax adjustments for the order.
    def adjust(order)
      label = "#{calculator.description} #{amount * 100}%"
      if self.inc_tax
        if Zone.default_tax.contains? order.tax_zone
          order.line_items.each { |line_item| puts ">>> create!"; create_adjustment(label, line_item, line_item) }
        else

        end
      else
        create_adjustment(label, order, order)
      end
    end
  end
end
