class_name Money
## Money is whole dollars. Every amount on screen goes through this formatter.


## 12 -> "$12", -5 -> "-$5".
static func text(amount: int) -> String:
	return "%s$%d" % ["-" if amount < 0 else "", absi(amount)]


## The points-to-money rate, which can be a fraction: 0.5 -> "$0.5".
static func rate_text(rate: float) -> String:
	return "$%s" % String.num(rate)
