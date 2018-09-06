require 'money'

class Checkout
  def initialize(pricing_rules)
    validate(pricing_rules)
    @pricing_rules = pricing_rules
    @counter = Hash.new(0)
  end

  def scan(item_code)
    raise KeyError.new, "Item not found in inventory" if @pricing_rules[item_code.to_sym].nil?
    @counter[item_code.to_sym] += 1
  end

  def total
    I18n.enforce_available_locales = false
    currency = @pricing_rules[:price][:currency]
    prc_format = str_to_sym(@pricing_rules[:price][:format])
    Money.new(total_cents,currency).format(prc_format)
  end

  def reset(pricing_rules = nil)
    @pricing_rules = pricing_rules unless pricing_rules.nil?
    @counter = Hash.new(0)
  end

  private

  def validate(pricing_rules)
    raise ArgumentError.new, "pricing_rules is expected to be a Hash" unless pricing_rules.is_a? Hash

    key_seq_hash = {}
    hash_flatten("",pricing_rules,key_seq_hash)
    first_invalid_key = key_seq_hash.select{ |_ ,v| v.is_a? (Numeric) }.select{ |_ ,v| v < 0 }.keys[0]
    raise ArgumentError.new, "Negative value read at key #{first_invalid_key}" unless first_invalid_key.nil?
  end

  def hash_flatten(parent, myHash, key_seq_hash)
    myHash.each do |key, value|
      total_key = parent == "" ? key : "#{parent}.#{key}"
      if value.is_a? Hash
        hash_flatten(total_key, value, key_seq_hash)
      else
        key_seq_hash[total_key] = value
      end
    end
  end

  def total_cents
    sum = 0
    @counter.each do |k,v|
      sum += item_price(v, @pricing_rules[k])
    end
    sum
  end

  def item_price(num, item_rules)
    fp = item_rules[:full_price]
    prices = [num * fp]

    unless item_rules[:n_for_m].nil?
      n = item_rules[:n_for_m][:n]
      m = item_rules[:n_for_m][:m]
      groups_of_n = num / n
      ungrouped = num % n
      prices += [(groups_of_n * m + ungrouped) * fp]
    end

    unless item_rules[:bulk_discount].nil?
      bp = item_rules[:bulk_discount][:bulk_price]
      thr = item_rules[:bulk_discount][:threshold]
      if num >= thr
        prices += [num * bp]
      else
        prices += [num * fp]
      end
    end

    prices.min
  end

  def str_to_sym(hsh)
    sym_hash = hsh.map do |k, v|
      if (v.is_a? String) && v =~ /\w+/
        [k, v.to_sym]
      else
        [k, v]
      end
    end
    Hash[sym_hash]
  end

end
