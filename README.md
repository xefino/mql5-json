# mql5-json
This library contains an improved version of the [JAson library](https://www.mql5.com/en/code/13663) with better documentation and readability.

## Installation
To install, simply clone this repository to your `MQL5/Include` directory, for MT5. For MT4, clone this repository to your `MQL4/Include` directory.

## Examples
This library is extremely easy to use, if a bit verbose. This section contains details on how to serialize and deserialize data.

### Serialization
Serializing data is as simple as filling up the `JSONNode` object and then calling `Serialize`. This example shows how you could convert an `MqlTradeRequest` to JSON:

```
#include <mql5-json/Json.mqh>

string ConverToJson(const MqlTradeRequest &request) {
   JSONNode *js = new JSONNode();
   js["action"] = (int)request.action;
   js["comment"] = request.comment;
   js["deviation"] = (long)request.deviation;
   js["expiration"] = IntegerToString(request.expiration, 10, '0');
   js["magic"] = (long)request.magic;
   js["order_id"] = (long)request.order;
   js["position_id"] = (long)request.position;
   js["opposite_position_id"] = (long)request.position_by;
   js["price"] = request.price;
   js["stop_loss"] = request.sl;
   js["stop_limit"] = request.stoplimit;
   js["symbol"] = request.symbol;
   js["take_profit"] = request.tp;
   js["type"] = (int)request.type;
   js["fill_type"] = (int)request.type_filling;
   js["expiration_type"] = (int)request.type_time;
   js["volume"] = request.volume;
   
   return js.Serialize();
}
```

Note that in this example, many of the types had to be casted because the `operator=` function is not capable of accepting enums or datetimes. This functionality will be included in a future release.
