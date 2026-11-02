class_name Money
## Money is whole dollars. Every amount on screen goes through this formatter.


## 12 -> "$12", -5 -> "-$5".
static func text(amount: int) -> String:
	return "%s$%d" % ["-" if amount < 0 else "", absi(amount)]
