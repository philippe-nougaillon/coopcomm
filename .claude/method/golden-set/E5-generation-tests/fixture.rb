# app/services/pricing_service.rb
#
# Computes the total monetary discount to apply to a cart, given a set of
# candidate discount codes. Used by the checkout pipeline.
#
# All amounts are BigDecimal. All datetimes are tz-aware
# (ActiveSupport::TimeWithZone — typically Time.current / Time.zone.local(...)).

require "bigdecimal"
require "bigdecimal/util"

module PricingService
  # A minimal cart for pricing purposes.
  Cart = Struct.new(:subtotal, keyword_init: true) do
    def initialize(subtotal:)
      raise ArgumentError, "subtotal must be strictly positive" if subtotal <= BigDecimal("0")
      super
    end
  end

  # A discount code. `pct` is in percent (e.g. BigDecimal("15") => 15%).
  DiscountCode = Struct.new(
    :code, :pct,
    :valid_from, :valid_until,
    :exclusive,
    :min_subtotal, :max_discount,
    keyword_init: true
  ) do
    def initialize(code:, pct:,
                   valid_from: nil, valid_until: nil,
                   exclusive: false,
                   min_subtotal: nil, max_discount: nil)
      super
    end
  end

  module_function

  # Compute the total discount amount to apply to `cart`.
  #
  # Rules:
  #   1. A code is "valid" iff:
  #        (valid_from.nil?    || valid_from <= now)  &&
  #        (valid_until.nil?   || valid_until >  now) &&
  #        (min_subtotal.nil?  || cart.subtotal >= min_subtotal).
  #   2. If any valid code has `exclusive: true`, only that code applies
  #      (no stacking with anything else).
  #   3. Otherwise, all valid codes stack: their per-code discounts sum up.
  #   4. Optional global cap: if `max_total_pct` is set, the total discount
  #      is capped at `max_total_pct%` of `cart.subtotal`.
  #
  # @param cart [PricingService::Cart]
  # @param codes [Enumerable<PricingService::DiscountCode>]
  # @param now [ActiveSupport::TimeWithZone, nil] defaults to Time.current
  # @param max_total_pct [BigDecimal, nil]
  # @return [BigDecimal] amount, always >= 0 and <= cart.subtotal
  def compute_total_discount(cart:, codes:, now: nil, max_total_pct: nil)
    now ||= Time.current

    valid = codes.reject do |c|
      (!c.valid_from.nil?   && c.valid_from > now) ||
        (!c.valid_until.nil?  && c.valid_until <= now) ||
        (!c.min_subtotal.nil? && cart.subtotal < c.min_subtotal)
    end

    return BigDecimal("0") if valid.empty?

    exclusive = valid.find(&:exclusive)
    total =
      if exclusive
        apply_one(cart, exclusive)
      else
        valid.sum(BigDecimal("0")) { |c| apply_one(cart, c) }
      end

    if max_total_pct
      cap = cart.subtotal * max_total_pct / BigDecimal("100")
      total = cap if total > cap
    end

    # Final safety: cannot discount more than the subtotal.
    total = cart.subtotal if total > cart.subtotal
    total
  end

  def apply_one(cart, code)
    raw = cart.subtotal * code.pct / BigDecimal("100")
    return code.max_discount if !code.max_discount.nil? && raw > code.max_discount
    raw
  end
  private_class_method :apply_one
end
