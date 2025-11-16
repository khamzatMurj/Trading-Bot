#property copyright "MIT"
#property version   "1.0"
#property strict
#property description "EMA50/200 + RSI confirmation"

// ===== Inputs =====
// Trend / confirmation
input int    EMA_Fast             = 50;
input int    EMA_Slow             = 200;
input int    RSI_Period           = 14;
input int    RSI_BuyLevel         = 55;      // >= to buy
input int    RSI_SellLevel        = 45;      // <= to sell

// Risk: fixed lot + TP/SL (in pips)
input double Lots                 = 0.01;
input int    StopLossPips         = 300;     // 0 = no SL
input int    TakeProfitPips       = 500;     // 0 = no TP
input int    Slippage             = 3;       // broker points

// Filters
input int    MaxSpreadPoints      = 350;     // 0 = disable spread check
input bool   UseTimeWindow        = false;
input int    TradeStartHour       = 7;       // server hour
input int    TradeEndHour         = 20;

// Behavior
input bool   AllowLongs           = true;
input bool   AllowShorts          = true;
input bool   OneTradePerDirection = true;    // if true, only 1 BUY and/or 1 SELL at a time
input int    Magic                = 20251018;

// ===== Helpers =====
bool SpreadOK()
{
   if(MaxSpreadPoints <= 0) return true;
   int sp = (int)MarketInfo(Symbol(), MODE_SPREAD);
   return (sp <= MaxSpreadPoints);
}

bool TimeOK()
{
   if(!UseTimeWindow) return true;
   int h = TimeHour(TimeCurrent());
   if(TradeStartHour <= TradeEndHour) return (h >= TradeStartHour && h < TradeEndHour);
   return (h >= TradeStartHour || h < TradeEndHour); // window that crosses midnight
}

double PipToPoints()
{
   // For 5/3 digit brokers a pip is 10 * Point; else 1 * Point
   return (Digits==5 || Digits==3) ? 10*Point : Point;
}

double EMA(int period, int shift=0)
{
   return iMA(Symbol(), PERIOD_CURRENT, period, 0, MODE_EMA, PRICE_CLOSE, shift);
}

double RSIv(int period, int shift=0)
{
   return iRSI(Symbol(), PERIOD_CURRENT, period, PRICE_CLOSE, shift);
}

bool BuySignal()
{
   // Trend up: Close > EMA50 and EMA50 > EMA200, plus RSI >= level
   double eFast = EMA(EMA_Fast, 0);
   double eSlow = EMA(EMA_Slow, 0);
   double rsi   = RSIv(RSI_Period, 0);
   return (Close[0] > eFast && eFast > eSlow && rsi >= RSI_BuyLevel);
}

bool SellSignal()
{
   // Trend down: Close < EMA50 and EMA50 < EMA200, plus RSI <= level
   double eFast = EMA(EMA_Fast, 0);
   double eSlow = EMA(EMA_Slow, 0);
   double rsi   = RSIv(RSI_Period, 0);
   return (Close[0] < eFast && eFast < eSlow && rsi <= RSI_SellLevel);
}

int CountOpen(int type) // by symbol + magic
{
   int c=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && OrderType()==type)
         c++;
   }
   return c;
}

double NormalizePrice(double price)
{
   return NormalizeDouble(price, Digits);
}

int SendMarketOrder(int type, double lots)
{
   RefreshRates();
   double price = (type==OP_BUY) ? Ask : Bid;

   // SL/TP price
   double sl=0, tp=0;
   double pp = PipToPoints();

   if(StopLossPips > 0)
   {
      if(type==OP_BUY)  sl = price - StopLossPips * pp;
      else              sl = price + StopLossPips * pp;
   }
   if(TakeProfitPips > 0)
   {
      if(type==OP_BUY)  tp = price + TakeProfitPips * pp;
      else              tp = price - TakeProfitPips * pp;
   }

   price = NormalizePrice(price);
   if(sl>0) sl = NormalizePrice(sl);
   if(tp>0) tp = NormalizePrice(tp);

   int tk = OrderSend(Symbol(), type, lots, price, Slippage, sl, tp, "EMA_RSI_Confirm", Magic, 0, clrNONE);
   if(tk<0) Print("OrderSend failed: ", GetLastError());
   return tk;
}

// ===== MT4 Entry Points =====
int OnInit()   { return(INIT_SUCCEEDED); }
void OnDeinit(const int reason) {}

void OnTick()
{
   if(!SpreadOK() || !TimeOK()) return;

   // BUY
   if(AllowLongs && BuySignal())
   {
      if(!OneTradePerDirection || CountOpen(OP_BUY)==0)
         SendMarketOrder(OP_BUY, Lots);
   }

   // SELL
   if(AllowShorts && SellSignal())
   {
      if(!OneTradePerDirection || CountOpen(OP_SELL)==0)
         SendMarketOrder(OP_SELL, Lots);
   }
}
