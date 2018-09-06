require 'money'

class Checkout
  # validates pricing options and inits the counted items for each kind to 0
  def initialize(pricing_rules)
    validate(pricing_rules)
    @pricing_rules = pricing_rules
    @counter = Hash.new(0)
  end

  # increases of 1 the number of scanned items with the given code.
  # raises if the item code is not found in the pricing rules
  def scan(item_code)
    raise KeyError.new, "Item not found in inventory" if @pricing_rules[item_code.to_sym].nil?
    @counter[item_code.to_sym] += 1
  end

  # returns the properly formatted string expressing the price, using the
  # currency and format options found in the pricing rules
  def total
    I18n.enforce_available_locales = false # avoids the need of setting up locales
    currency = @pricing_rules[:price][:currency]
    prc_format = str_to_sym(@pricing_rules[:price][:format])
    Money.new(total_cents, currency).format(prc_format)
  end

  # resets the counted items and optionally sets new pricing rules
  def reset(pricing_rules = nil)
    @pricing_rules = pricing_rules unless pricing_rules.nil?
    @counter = Hash.new(0)
  end

  private

  # checks if 'pricing_rules' is a hash and that all the numbers it contains are nonnegative
  def validate(pricing_rules)
    raise ArgumentError.new, "pricing_rules is expected to be a Hash" unless pricing_rules.is_a? Hash

    key_seq_hash = {}
    flatten_hash("", pricing_rules, key_seq_hash)
    first_invalid_key = key_seq_hash.select { |_, v| v.is_a? Numeric }.select { |_, v| v < 0 }.keys[0]
    raise ArgumentError.new, "Negative value read at key #{first_invalid_key}" unless first_invalid_key.nil?
  end

  # recursively unwinds a hash to its basic values and stores them, along with
  # the sequence of the keys leading to each, separated by '.',
  # in the 'key_seq_hash' hash
  def flatten_hash(parent, hash, key_seq_hash)
    hash.each do |key, value|
      total_key = parent == "" ? key : "#{parent}.#{key}"
      if value.is_a? Hash
        flatten_hash(total_key, value, key_seq_hash)
      else
        key_seq_hash[total_key] = value
      end
    end
  end

  # total price in cents
  def total_cents
    sum = 0
    @counter.each do |k, v|
      sum += item_price(v, @pricing_rules[k])
    end
    sum
  end

  # price of a pack of 'num' of one kind of item given the pricing rules for that item
  def item_price(num, item_rules)
    fp = item_rules[:full_price]
    prices = [num * fp]

    unless item_rules[:n_for_m].nil?
      # generic 'n for m' discount (2x1, 3x2, ...)
      n = item_rules[:n_for_m][:n]
      m = item_rules[:n_for_m][:m]
      groups_of_n = num / n
      # remainder items have to be accounted for
      ungrouped = num % n
      prices += [(groups_of_n * m + ungrouped) * fp]
    end

    unless item_rules[:bulk_discount].nil?
      bp = item_rules[:bulk_discount][:bulk_price]
      thr = item_rules[:bulk_discount][:threshold]
      # bulk price over a certain number purchased
      if num >= thr
        prices += [num * bp]
      else
        prices += [num * fp]
      end
    end

    # returns the most convenient price given all the promotions found
    # in the pricing rules
    prices.min
  end

  # needed for using the price format options hash coming from the JSON file
  def str_to_sym(hsh)
    sym_hash = hsh.map do |k, v|
      if (v.is_a? String) && v =~ /\w+/
        # strings have to be converted in symbols except the non-word characters
        # (e.g. the '.' separator)
        [k, v.to_sym]
      else
        [k, v]
      end
    end
    Hash[sym_hash]
  end
end
