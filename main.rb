require_relative 'checkout.rb'
require 'json'

def do_checkout
  print `clear`
  puts " *** Checkout started *** "

  pricing_rules = JSON.parse(File.read('pricing_rules.json'), symbolize_names: false)
  co = Checkout.new(pricing_rules)
  scanned_items = []

  print "Enter code of item to be scanned ('done' to get the total, 'res' to reset):\n > "

  item = gets.chomp
  while item != 'done'
    if item == 'res'
      co.reset
      scanned_items.clear
    else
      co.scan(item)
      scanned_items << item
    end

    print "Enter code of item to be scanned ('done' to get the total, 'res' to reset):\n > "
    item = gets.chomp
  end
  puts "Items: #{scanned_items.join(', ')}"
  puts "Total: #{co.total}"
end

do_checkout
