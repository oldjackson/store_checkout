require 'money'

PRICE_FORMAT = { decimal_mark: '.', symbol_position: :after, symbol_after_without_space: true }

class Checkout
  def initialize(pricing_rules)
    @pricing_rules = pricing_rules
    @counter = Hash.new(0)
  end

  def scan(item_code)
    if @pricing_rules[item_code].nil?
      puts "Item not found in inventory"
    else
      @counter[item_code] += 1
    end
  end

  def total
    I18n.enforce_available_locales = false
    Money.new(total_cents,@pricing_rules["currency"]).format(PRICE_FORMAT)
  end

  def reset(pricing_rules = nil)
    @pricing_rules = pricing_rules unless pricing_rules.nil?
    @counter = Hash.new(0)
  end

  private

  def total_cents
    sum = 0
    @counter.each do |k,v|
      sum += item_price(v, @pricing_rules[k])
    end
    sum
  end

  def item_price(num, item_rules)
    fp = item_rules["full_price"]
    prices = [num * fp]

    unless item_rules['n_for_m'].nil?
      n = item_rules['n_for_m']["n"]
      m = item_rules['n_for_m']["m"]
      groups_of_n = num / n
      ungrouped = num % n
      prices += [(groups_of_n * m + ungrouped) * fp]
    end

    unless item_rules['bulk_discount'].nil?
      bp = item_rules['bulk_discount']["bulk_price"]
      thr = item_rules['bulk_discount']["threshold"]
      if num >= thr
        prices += [num * bp]
      else
        prices += [num * fp]
      end
    end

    prices.min
  end
end
