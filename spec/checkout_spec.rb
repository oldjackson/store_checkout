require_relative '../checkout'

PRICING_RULES_PATH = 'data/pricing_rules.json'
NO_HASH_PRICING_RULES_PATH = 'data/pricing_rules_no_hash.json'
NEG_VALUE_PRICING_RULES_PATH = 'data/pricing_rules_neg_value.json'
ALT_PRICING_RULES_PATH = 'data/alt_pricing_rules.json'

describe Checkout do
  describe "#initialize" do
    it "should not raise errors if passed valid pricing rules" do
      pricing_rules = JSON.parse(File.read(PRICING_RULES_PATH), symbolize_names: true)
      expect { Checkout.new(pricing_rules) }.to_not raise_error
    end
    it "should raise an argument error if passed invalid data (not hash)" do
      pricing_rules = JSON.parse(File.read(NO_HASH_PRICING_RULES_PATH), symbolize_names: true)
      expect { Checkout.new(pricing_rules) }.to raise_error ArgumentError
    end

    it "should raise an argument error if passed invalid data (negative numbers)" do
      pricing_rules = JSON.parse(File.read(NEG_VALUE_PRICING_RULES_PATH), symbolize_names: true)
      expect { Checkout.new(pricing_rules) }.to raise_error ArgumentError
    end
  end

  describe "#scan" do
    pricing_rules = JSON.parse(File.read(PRICING_RULES_PATH), symbolize_names: true)
    co = Checkout.new(pricing_rules)

    it "should accept \"VOUCHER\" as a valid item in the inventory" do
      expect {co.scan("VOUCHER")}.to_not raise_error
    end

    it "should accept \"TSHIRT\" as a valid item in the inventory" do
      expect {co.scan("TSHIRT")}.to_not raise_error
    end

    it "should accept \"MUG\" as a valid item in the inventory" do
      expect {co.scan("MUG")}.to_not raise_error
    end

    it "should reject \"CAP\" as an item not in the inventory" do
      expect {co.scan("CAP")}.to raise_error KeyError
    end

    it "should reject \"FIDDLER\" as an item not in the inventory" do
      expect {co.scan("FIDDLER")}.to raise_error KeyError
    end
  end

  describe "#total" do
    pricing_rules = JSON.parse(File.read(PRICING_RULES_PATH), symbolize_names: true)
    co = Checkout.new(pricing_rules)

    it "should return 32.50€ for a tshirt, a voucher and a mug" do
      items = %w(TSHIRT VOUCHER MUG)
      items.each{ |i| co.scan(i) }
      expect(co.total).to eq("32.50€")
    end

    it "should return 25.00€ for a tshirt and two vouchers" do
      co.reset
      items = %w(VOUCHER TSHIRT VOUCHER)
      items.each{ |i| co.scan(i) }

      expect(co.total).to eq("25.00€")
    end

    it "should return 81.00€ for 4 tshirts and a voucher" do
      co.reset
      items = %w(TSHIRT TSHIRT TSHIRT VOUCHER TSHIRT)
      items.each{ |i| co.scan(i) }

      expect(co.total).to eq("81.00€")
    end

    it "should return 74.50€ for 3 vouchers, 3 tshirts and a mug" do
      co.reset
      items = %w(VOUCHER TSHIRT VOUCHER VOUCHER MUG TSHIRT TSHIRT)
      items.each{ |i| co.scan(i) }

      expect(co.total).to eq("74.50€")
    end

    it "should return the same price no matter the scanning order" do
      co.reset
      items = %w(VOUCHER TSHIRT VOUCHER VOUCHER MUG TSHIRT TSHIRT)
      items.each{ |i| co.scan(i) }
      first_total = co.total

      co.reset
      items = %w(TSHIRT VOUCHER MUG VOUCHER TSHIRT VOUCHER TSHIRT)
      items.each{ |i| co.scan(i) }

      expect(co.total).to eq(first_total)
    end

    it "should return 30.00€ for a tshirt and two vouchers under alternative pricing rules" do
      alt_pricing_rules = JSON.parse(File.read(ALT_PRICING_RULES_PATH), symbolize_names: true)
      co.reset(alt_pricing_rules)
      items = %w(VOUCHER TSHIRT VOUCHER)
      items.each{ |i| co.scan(i) }

      expect(co.total).to eq("30.00€")
    end

    it "should return 81.00€ for 4 tshirts and a voucher under alternative pricing rules" do
      alt_pricing_rules = JSON.parse(File.read(ALT_PRICING_RULES_PATH), symbolize_names: true)
      co.reset(alt_pricing_rules)
      items = %w(TSHIRT TSHIRT TSHIRT VOUCHER TSHIRT)
      items.each{ |i| co.scan(i) }

      expect(co.total).to eq("81.00€")
    end

    it "should return 77.50€ for 3 vouchers, 3 tshirts and a mug under alternative pricing rules" do
      alt_pricing_rules = JSON.parse(File.read(ALT_PRICING_RULES_PATH), symbolize_names: true)
      co.reset(alt_pricing_rules)
      items = %w(VOUCHER TSHIRT VOUCHER VOUCHER MUG TSHIRT TSHIRT)
      items.each{ |i| co.scan(i) }

      expect(co.total).to eq("77.50€")
    end

  end



end
