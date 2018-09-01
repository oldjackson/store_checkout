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
    sum = 0
    @counter.each do |k,v|
      sum += item_price(v, @pricing_rules[k])
    end
    sum
  end

  def reset(pricing_rules = nil)
    @pricing_rules = pricing_rules unless pricing_rules.nil?
    @counter = Hash.new(0)
  end

  private

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
