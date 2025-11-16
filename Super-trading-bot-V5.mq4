// MLq4_librery_V5.mq4  —  Version 5 (BE + Partial Close + Time Exit)
// © MLq4 librery

#property copyright "© MLq4 librery"
#property link      "MLq4 librery"
#property version   "5.00"
#property strict
#property description "MLq4 librery – V5 adds break-even, partial close, and time-based exit"

// ======== Inputs ========
extern string   EA_Name         = "MLq4_librery_V5";
extern int      Magic           = 1111111;

// Trade filters / logic
extern int      Max_Spread      = 20;     // in points
extern int      StepPoints      = 30;     // pending distance from market, in points
extern int      SL_Points       = 600;    // fixed SL in points (also used for risk sizing)
extern int      TP_Points       = 900;    // fixed TP in points
extern double   SarPeriod       = 0.56;   // SAR accel
extern double   SarAccel        = 0.20;   // SAR max accel
extern int      Trail_Points    = 300;    // classic trailing in points
extern int      MinVolume       = 2;      // ignore first tick of bar if Volume[0] < MinVolume
extern bool     OneOrderPerSide = true;   // prevent stacking same-side pendings

// Sessions + cooldown (server time)
extern bool     UseSessions     = true;
extern int      LondonStart     = 8;
extern int      LondonEnd       = 12;     // exclusive
extern int      NYStart         = 14;
extern int      NYEnd           = 20;     // exclusive
extern int      CooldownMin     = 10;     // minutes between same-side planned orders

// Risk-based lot sizing + Equity guard (from V3)
extern bool     UseRiskSizing   = true;   // if false -> uses FixedLots
extern double   FixedLots       = 0.05;
extern double   RiskPercent     = 1.0;    // % of balance per trade
extern double   MaxDrawdownPct  = 35.0;   // stop trading if equity drawdown >= this %

// Higher-Timeframe Trend Filter (from V4)
extern bool     UseHTFTrend     = true;          // enable/disable HTF filter
extern int      HTF_EMA_Period  = 200;           // default 200 EMA
extern int      HTF_TF          = PERIOD_H1;     // higher timeframe (e.g., PERIOD_H1 or PERIOD_H4)

// ======== NEW (V5): BE + Partial + Time Exit ========
extern bool     UseBreakEven       = true;
extern int      BE_TriggerPoints   = 400;        // when profit >= this, move SL to BE+lock
extern int      BE_LockPoints      = 50;         // lock-in points beyond BE
extern bool     UsePartialClose    = true;
extern double   PartialClosePct    = 0.50;       // 50% close (0.1 .. 0.9)
extern int      TimeExitMin        = 180;        // close after N minutes in market (0 = off)

/*
  Notes:
  - BE triggers once profit >= BE_TriggerPoints (points). SL set to OpenPrice +/- BE_LockPoints.
  - Partial close executes once position reaches ~RR 1:1/1.5 (here: >= TP/2 distance). It may repeat
    if lots remain; to minimize repeats, we clamp to min lot and only close if result reduces lots.
  - TimeExitMin closes any still-open trade after the specified minutes since open.
*/

// ======== Globals ========
datetime lastBuyPlan  = 0;
datetime lastSellPlan = 0;

// ======== Lifecycle ========
int init(){ return(0); }
int deinit(){ return(0); }

int start()
{
   // --- Equity guard: stop trading if drawdown exceeded
   if(MaxDrawdownPct > 0.0)
   {
      double eq  = AccountEquity();
      double bal = AccountBalance();
      if(bal > 0)
      {
         double pct = (eq / bal) * 100.0;
         if(pct < (100.0 - MaxDrawdownPct)) return(0); // halt entries
      }
   }

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

   // HTF EMA trend filter
   if(UseHTFTrend && HTF_EMA_Period > 0)
   {
      double emaHTF = iMA(NULL, HTF_TF, HTF_EMA_Period, 0, MODE_EMA, PRICE_CLOSE, 0);
      if(emaHTF > 0)
      {
         if(biasBuy  && Close[0] < emaHTF) biasBuy  = false; // only buy above EMA
         if(biasSell && Close[0] > emaHTF) biasSell = false; // only sell below EMA
      }
   }

   // Manage existing positions (now includes BE/Partial/TimeExit)
   ManageOpenPositions();
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
   double lot   = SelectLotByRisk(SL_Points);

   if(AccountFreeMarginCheck(Symbol(),OP_BUYSTOP,lot)<=0) return;

   OrderSend(Symbol(),OP_BUYSTOP,lot,price,3,sl,tp,EA_Name,Magic,0,clrBlue);
}

void PlaceSellStop()
{
   double price = NormalizeDouble(Bid - StepPoints*Point,Digits);
   double sl    = NormalizeDouble(price + SL_Points*Point,Digits);
   double tp    = NormalizeDouble(price - TP_Points*Point,Digits);
   double lot   = SelectLotByRisk(SL_Points);

   if(AccountFreeMarginCheck(Symbol(),OP_SELLSTOP,lot)<=0) return;

   OrderSend(Symbol(),OP_SELLSTOP,lot,price,3,sl,tp,EA_Name,Magic,0,clrRed);
}

// --------- Lot sizing ---------
double SelectLotByRisk(int slPoints)
{
   if(!UseRiskSizing) return ClampLot(FixedLots);

   double lot = CalcRiskLot(slPoints);
   return ClampLot(lot);
}

double CalcRiskLot(int slPoints)
{
   // perLotRisk = (SL price distance in ticks) * tickValue
   double tickSize  = MarketInfo(Symbol(), MODE_TICKSIZE);
   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   if(tickSize <= 0.0 || tickValue <= 0.0 || slPoints <= 0)
      return ClampLot(FixedLots);

   double priceDist = slPoints * Point;              // price distance for SL
   double ticks     = priceDist / tickSize;          // number of ticks to SL
   double perLotRisk= ticks * tickValue;             // money risk per 1.0 lot

   double riskMoney = AccountBalance() * (RiskPercent/100.0);
   if(perLotRisk <= 0.0) return ClampLot(FixedLots);

   double lots = riskMoney / perLotRisk;
   return lots;
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

// --------- Trade management (V5) ---------
void ManageOpenPositions()
{
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=Magic) continue;

      int    type     = OrderType();
      double open     = OrderOpenPrice();
      double lots     = OrderLots();
      double minLot   = MarketInfo(Symbol(),MODE_MINLOT);
      double stepLot  = MarketInfo(Symbol(),MODE_LOTSTEP);
      if(stepLot<=0) stepLot=0.01;

      // --- BUY management
      if(type==OP_BUY)
      {
         // Classic trailing
         if(Trail_Points>0)
         {
            double newSL = NormalizeDouble(Bid - Trail_Points*Point,Digits);
            if((OrderStopLoss()==0) || (newSL>OrderStopLoss()))
               OrderModify(OrderTicket(),open,newSL,OrderTakeProfit(),0,clrBlue);
         }

         // Break-even
         if(UseBreakEven && BE_TriggerPoints>0)
         {
            double profitPts = (Bid - open)/Point;
            if(profitPts >= BE_TriggerPoints)
            {
               double beSL = NormalizeDouble(open + BE_LockPoints*Point,Digits);
               if(OrderStopLoss() < beSL)
                  OrderModify(OrderTicket(),open,beSL,OrderTakeProfit(),0,clrBlue);
            }
         }

         // Partial close (once/if enough profit)
         if(UsePartialClose && PartialClosePct>0.0 && PartialClosePct<1.0)
         {
            double triggerPts = MathMax(TP_Points/2.0, BE_TriggerPoints); // mid-way or BE trigger, whichever larger
            double profitPts  = (Bid - open)/Point;
            if(profitPts >= triggerPts)
            {
               double closeLots = NormalizeDouble(lots * PartialClosePct, 2);
               // Only close if it reduces the position and stays above min lot
               if(closeLots >= minLot && closeLots < lots)
                  OrderClose(OrderTicket(), closeLots, Bid, 3, clrBlue);
            }
         }

         // Time-based exit
         if(TimeExitMin>0)
            if((TimeCurrent()-OrderOpenTime()) >= TimeExitMin*60)
               OrderClose(OrderTicket(), lots, Bid, 3, clrBlue);
      }

      // --- SELL management
      if(type==OP_SELL)
      {
         // Classic trailing
         if(Trail_Points>0)
         {
            double newSL = NormalizeDouble(Ask + Trail_Points*Point,Digits);
            if((OrderStopLoss()==0) || (newSL<OrderStopLoss()))
               OrderModify(OrderTicket(),open,newSL,OrderTakeProfit(),0,clrRed);
         }

         // Break-even
         if(UseBreakEven && BE_TriggerPoints>0)
         {
            double profitPts = (open - Ask)/Point;
            if(profitPts >= BE_TriggerPoints)
            {
               double beSL = NormalizeDouble(open - BE_LockPoints*Point,Digits);
               if(OrderStopLoss()==0 || OrderStopLoss()>beSL)
                  OrderModify(OrderTicket(),open,beSL,OrderTakeProfit(),0,clrRed);
            }
         }

         // Partial close
         if(UsePartialClose && PartialClosePct>0.0 && PartialClosePct<1.0)
         {
            double triggerPts = MathMax(TP_Points/2.0, BE_TriggerPoints);
            double profitPts  = (open - Ask)/Point;
            if(profitPts >= triggerPts)
            {
               double closeLots = NormalizeDouble(lots * PartialClosePct, 2);
               if(closeLots >= minLot && closeLots < lots)
                  OrderClose(OrderTicket(), closeLots, Ask, 3, clrRed);
            }
         }

         // Time-based exit
         if(TimeExitMin>0)
            if((TimeCurrent()-OrderOpenTime()) >= TimeExitMin*60)
               OrderClose(OrderTicket(), lots, Ask, 3, clrRed);
      }
   }
}

// ---------- Utilities (V2+) ----------
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
