class_name Money
## Money is counted in whole cents (ints), so prices and payouts can have fractions
## without float drift. This formats cents as dollars.


## 1250 -> "$12.50", 40 -> "$0.40", -5 -> "-$0.05".
static func text(cents: int) -> String:
	var sign := "-" if cents < 0 else ""
	cents = absi(cents)
	return "%s$%d.%02d" % [sign, cents / 100, cents % 100]
