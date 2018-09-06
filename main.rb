require_relative 'checkout.rb'
require 'json'

PRICING_RULES_PATH = 'data/pricing_rules.json'

def do_checkout
  print `clear`
  puts " *** Checkout started *** "

  pricing_rules = JSON.parse(File.read(PRICING_RULES_PATH))
  co = Checkout.new(pricing_rules)
  scanned_items = []

  print "Enter code of item to be scanned ('done' to get the total, 'res' to reset):\n > "

  item = gets.chomp
  while item != 'done'
    if item == 'res'
      co.reset
      scanned_items.clear
    else
      begin
        co.scan(item)
        scanned_items << item
      rescue KeyError => e
        puts "*** #{e.message.upcase} ***"
      end
    end

    print "Enter code of item to be scanned ('done' to get the total, 'res' to reset):\n > "
    item = gets.chomp
  end
  items_string = scanned_items.empty? ? "none" : scanned_items.join(', ')
  puts "Items: #{items_string}"
  puts "Total: #{co.total}"
  puts "**************"
end

do_checkout
