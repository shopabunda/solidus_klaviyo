# frozen_string_literal: true

module SolidusKlaviyo
  module Serializer
    class Order < Base
      def order
        object
      end

      def as_json(_options = {})
        {
          'OrderNumber' => order.number,
          'Categories' => (order.line_items.flat_map do |line_item|
            line_item.variant.product.taxons.flat_map(&:self_and_ancestors)
          end).uniq.map(&:name),
          'ItemNames' => order.line_items.map { |line_item| line_item.variant.descriptive_name },
          'DiscountCode' => order.order_promotions.map { |op| op.code.value }.join(', '),
          'DiscountValue' => order.promo_total,
          'Items' => order.line_items.map { |line_item| LineItem.serialize(line_item) },
          'BillingAddress' => Address.serialize(order.bill_address),
          'ShippingAddress' => Address.serialize(order.ship_address),
        }
      end
    end
  end
end
