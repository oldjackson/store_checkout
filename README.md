# Ruby checkout tool

This package includes a `Checkout` class able to apply a pricing policy and a simple command line program that makes use of it, along with the suitable `rspec` tests.

## Specifications
A `Checkout` object should
- be initialized passing it a `pricing_rules` argument containing in itself the prices of all the items in shop and the possible promotions on them
- have a `#scan(item_code)` method allowing to add one item to the checkout
- have a `#total` method returning the total price of the scanned items.

The checkout process should go like
```ruby
co = Checkout.new(pricing_rules)
co.scan("VOUCHER")
co.scan("MUG")
co.scan("VOUCHER")
co.scan("TSHIRT")
price = co.total
```
The order the items are 'scanned' in must obviously be irrelevant.

#### Pricing rules
It must be possible for the user to specify prices of items, for example as in the following price list.
```
Code         | Name         |  Price
-------------------------------------
VOUCHER      | Voucher      |   5.00€
TSHIRT       | T-Shirt      |  20.00€
MUG          | Coffee Mug   |   7.50€
```
Also, at least two kinds of promotions can be endowed to each product:
- a 2-for-1 (pay one every 2 purchased)
- a bulk discount (reduced per-item price) for purchases of more than 3 items of the product.
Supposing to have the 2-for-1 on vouchers and a bulk price of 19.00€ if you buy at least 3 t-shirts, a checkout output should read like
```
Items: VOUCHER, TSHIRT, VOUCHER, VOUCHER, MUG, TSHIRT, TSHIRT
Total: 74.50€
```

## `Checkout` class implementation
Given the potential complexity of the pricing policy, I chose the `pricing_rules` initialization argument to be a `Hash`. The validation of a new `Checkout` object raises an exception if `pricing_rules` is `nil` or not a `Hash`.

The keys of `pricing_rules` are taken as the codes of the products in the inventory. `#scan` will raise an exception if given a code not included in `pricing_rules`' keys. The value of each item key is a hash itself including the full price and the promotions. I generalized the 2-for-1 promotion to an N-for-M (3x2, 4x3, ...), and the bulk discount to an arbitrary number of items triggering the reduced price. The `n_for_m` key will then have `n` and `m` as subkeys, while `bulk_discount` will contain the bulk price and the 'threshold' item number.

To treat properly the prices and have `#total` return the checkout price gracefully formatted, I used the [`money`](https://github.com/RubyMoney/money) gem. The prices will then be stored in cents, while the price list currency and desired price [formatting options](https://github.com/RubyMoney/money/blob/master/lib/money/money/formatter.rb) can also be stored in the `pricing_rules` under the `price` key. To have the ouput formatted as in the specifications, all in all `pricing_rules` will look like
```ruby
{
  "price"=>{
    "currency"=>"EUR",
    "format"=> {
      "decimal_mark"=>".",
      "symbol_position"=>"after",
      "symbol_after_without_space"=>true
    }
  },
  "VOUCHER"=>{
    "full_price"=>500,
    "n_for_m"=>{
      "n"=>2,
      "m"=>1
    }
  },
  "TSHIRT"=>{
    "full_price"=>2000,
    "bulk_discount"=>{
      "threshold"=>3,
      "bulk_price"=>1900
    }
  },
  "MUG"=>{"full_price"=>750}
}
```
A thorough validation of the rules details should also be performed, but to keep the code simple I simply imposed that every number should be nonnegative. If the opposite happens, the exception raised by the validator returns in the message the complete hash key sequence to the negative number.

I also provided an extra `#reset` allowing to zero the item count and optionally rewrite the pricing rules without having to create a new `Checkout`.

### Tests
The `rspec` tests are pretty self-explanatory and test the specified interface and the validation. By running `rake`, the test suite will be executed along with a style check performed by `rubocop`. The pricing rules used in the tests are stored in JSON files in the `data` folder.

## Interactive program
A checkout process can be performed by the user by launching
```sh
ruby main.rb
```
The pricing rules used in the checkout are stored in `data/pricing_rules.json`.

The user is prompted to enter the codes of the items being scanned, one at a time. The total price computation is triggered by entering `done`, while `res` will reset the counter (while keeping the same pricing rules).

The output should look like the one in the specifications.

## Installation
The `money` gem needs to be installed if not already present.
