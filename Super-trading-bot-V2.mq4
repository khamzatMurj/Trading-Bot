// MLq4_librery_V2.mq4  —  Version 2 (Sessions + Cooldown)
// © MLq4 librery

#property copyright "© MLq4 librery"
#property link      "MLq4 librery"
#property version   "2.00"
#property strict
#property description "MLq4 librery – V2 adds London/NY session filter + per-side cooldown"

// ======== Inputs ========
extern string   EA_Name         = "MLq4_librery_V2";
extern double   Lots            = 0.05;
extern int      Magic           = 1111111;
extern int      Max_Spread      = 20;     // in points
extern int      StepPoints      = 30;     // pending distance from market, in points
extern int      SL_Points       = 600;    // fixed SL in points
extern int      TP_Points       = 900;    // fixed TP in points
extern double   SarPeriod       = 0.56;   // SAR accel
extern double   SarAccel        = 0.20;   // SAR max accel
extern int      Trail_Points    = 300;    // classic trailing in points
extern int      MinVolume       = 2;      // ignore first tick of bar if Volume[0] < MinVolume
extern bool     OneOrderPerSide = true;   // prevent stacking same-side pendings

// --- NEW (V2): Sessions + Cooldown (hours are broker/server time) ---
extern bool     UseSessions     = true;   // trade only in these windows
extern int      LondonStart     = 8;      // hour start (e.g., UTC+1)
extern int      LondonEnd       = 12;     // hour end (exclusive)
extern int      NYStart         = 14;     // hour start
extern int      NYEnd           = 20;     // hour end (exclusive)
extern int      CooldownMin     = 10;     // minutes between same-side planned orders

// ======== Globals ========
datetime lastBuyPlan  = 0;
datetime lastSellPlan = 0;

// ======== Lifecycle ========
int init(){ return(0); }
int deinit(){ return(0); }

int start()
{
   if(!SpreadOk())  return(0);
   if(!VolumeOk())  return(0);

   // Direction: SAR bias + Bands context
   double sar   = iSAR(NULL,0,SarPeriod,SarAccel,0);
   double bbTop = iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_UPPER,0);
   double bbBot = iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_LOWER,0);

   bool biasBuy  = (Close[0] > sar) && (Ask < bbTop);
   bool biasSell = (Close[0] < sar) && (Bid  > bbBot);

   // Sessions gate
   if(UseSessions && !InTradingWindow())
   {
      biasBuy  = false;
      biasSell = false;
   }

   // Manage existing positions
   TrailOpenPositions();
   DeleteFarPendings();

   // Entries via pending stops (reduce slippage)
   if(biasBuy && (!OneOrderPerSide || !HasPending(OP_BUYSTOP)) && IsCooldownOk(true))
   {
      PlaceBuyStop();
      lastBuyPlan = TimeCurrent();
   }

   if(biasSell && (!OneOrderPerSide || !HasPending(OP_SELLSTOP)) && IsCooldownOk(false))
   {
      PlaceSellStop();
      lastSellPlan = TimeCurrent();
   }

   return(0);
}

// ======== Helpers ========
bool SpreadOk()
{
   double spr = NormalizeDouble((Ask-Bid)/Point,Digits);
   return (spr <= Max_Spread);
}

bool VolumeOk()
{
   return (Volume[0] >= MinVolume);
}

bool HasPending(int type)
{
   for(int i=OrdersTotal()-1;i>=0;i--)
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && OrderType()==type)
            return(true);
   return(false);
}

void DeleteFarPendings()
{
   // If price moved through a pending by > 2*Step, remove and await re-eval
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=Magic) continue;

      if(OrderType()==OP_BUYSTOP && Bid + 2*StepPoints*Point > OrderOpenPrice())
         OrderDelete(OrderTicket());

      if(OrderType()==OP_SELLSTOP && Ask - 2*StepPoints*Point < OrderOpenPrice())
         OrderDelete(OrderTicket());
   }
}

void PlaceBuyStop()
{
   double price = NormalizeDouble(Ask + StepPoints*Point,Digits);
   double sl    = NormalizeDouble(price - SL_Points*Point,Digits);
   double tp    = NormalizeDouble(price + TP_Points*Point,Digits);
   double lot   = ClampLot(Lots);

   if(AccountFreeMarginCheck(Symbol(),OP_BUYSTOP,lot)<=0) return;

   OrderSend(Symbol(),OP_BUYSTOP,lot,price,3,sl,tp,EA_Name,Magic,0,clrBlue);
}

void PlaceSellStop()
{
   double price = NormalizeDouble(Bid - StepPoints*Point,Digits);
   double sl    = NormalizeDouble(price + SL_Points*Point,Digits);
   double tp    = NormalizeDouble(price - TP_Points*Point,Digits);
   double lot   = ClampLot(Lots);

   if(AccountFreeMarginCheck(Symbol(),OP_SELLSTOP,lot)<=0) return;

   OrderSend(Symbol(),OP_SELLSTOP,lot,price,3,sl,tp,EA_Name,Magic,0,clrRed);
}

double ClampLot(double lot)
{
   double step = MarketInfo(Symbol(),MODE_LOTSTEP);
   double minL = MarketInfo(Symbol(),MODE_MINLOT);
   double maxL = MarketInfo(Symbol(),MODE_MAXLOT);

   if(step<=0) step=0.01;
   lot = MathFloor(lot/step)*step;

   if(lot<minL) lot=minL;
   if(lot>maxL) lot=maxL;

   return(NormalizeDouble(lot,2));
}

void TrailOpenPositions()
{
   if(Trail_Points<=0) return;

   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=Magic) continue;

      if(OrderType()==OP_BUY)
      {
         double newSL = NormalizeDouble(Bid - Trail_Points*Point,Digits);
         if((OrderStopLoss()==0) || (newSL>OrderStopLoss()))
            OrderModify(OrderTicket(),OrderOpenPrice(),newSL,OrderTakeProfit(),0,clrBlue);
      }
      if(OrderType()==OP_SELL)
      {
         double newSL = NormalizeDouble(Ask + Trail_Points*Point,Digits);
         if((OrderStopLoss()==0) || (newSL<OrderStopLoss()))
            OrderModify(OrderTicket(),OrderOpenPrice(),newSL,OrderTakeProfit(),0,clrRed);
      }
   }
}

// ---------- V2 Utilities ----------
bool InTradingWindow()
{
   // Uses server/broker time from TimeCurrent(); adjust hours via inputs if needed.
   int h = TimeHour(TimeCurrent());

   bool london = (h >= LondonStart && h < LondonEnd);
   bool ny     = (h >= NYStart     && h < NYEnd);

   return (london || ny);
}

bool IsCooldownOk(bool buySide)
{
   if(CooldownMin<=0) return true;
   datetime last = buySide ? lastBuyPlan : lastSellPlan;
   if(last==0) return true;
   return (TimeCurrent() - last) >= CooldownMin*60;
}
