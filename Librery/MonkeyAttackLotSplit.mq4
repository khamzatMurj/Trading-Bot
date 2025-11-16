//+------------------------------------------------------------------+
//|                         MonkeyAttackLotSplit_MQL4_TestMode.mq4             |
//| Adds EnableTradeExecution setting for simulation-only testing    |
//+------------------------------------------------------------------+
#property strict

extern double MaxLotPerOrder = 10.0;
extern int Slippage = 3;
extern int MagicNumber = 987654;
extern string LogFileName = "LotSplitLog.csv";
extern string EmailSubject = "MonkeyAttackLotSplit Alert";
extern double AccountRiskPercent = 2.0;
extern double MaxDrawdownPercent = 20.0;
extern double TrailStartPips = 20.0;
extern double TrailStepPips = 5.0;
extern double MaxAllowedSlippagePips = 3.0;
extern bool ShowOverlay = true;
extern bool EnableTradeExecution = true; // NEW: Toggle live trade execution

int lastTicketChecked = -1;
double initialEquity = -1;
double lastMasterLot = 0;
double totalSplitLots = 0;

void ShowStatsOverlay()
{
   if (!ShowOverlay) return;

   double balance = AccountBalance();
   double equity = AccountEquity();
   double drawdown = 100 * (balance - equity) / balance;

   Comment(
      "=== MonkeyAttackLotSplit Stats ===\n",
      "Balance: $", DoubleToString(balance, 2), "\n",
      "Equity: $", DoubleToString(equity, 2), "\n",
      "Drawdown: ", DoubleToString(drawdown, 2), "%\n",
      "Last Master Lot: ", DoubleToString(lastMasterLot, 2), "\n",
      "Total Split Lots: ", DoubleToString(totalSplitLots, 2)
   );
}

int start()
{
   ShowStatsOverlay();

   if (initialEquity < 0) initialEquity = AccountEquity();

   double currentEquity = AccountEquity();
   double equityDrawdownPercent = 100 * (initialEquity - currentEquity) / initialEquity;

   if (equityDrawdownPercent > MaxDrawdownPercent)
   {
      string msg = StringFormat("MonkeyAttackLotSplit: Equity drawdown %.2f%% exceeded limit of %.2f%%. EA halted.", equityDrawdownPercent, MaxDrawdownPercent);
      Alert(msg);
      Print(msg);
      SendMail(EmailSubject, msg);
      return(0);
   }

   int totalOrders = OrdersTotal();
   for (int i = 0; i < totalOrders; i++)
   {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if (OrderMagicNumber() == MagicNumber && OrderType() <= OP_SELL)
         {
            int ticket = OrderTicket();
            double origLots = OrderLots();
            lastMasterLot = origLots;

            if (ticket != lastTicketChecked && origLots >= MaxLotPerOrder + 0.01)
            {
               double remainingLots = origLots - MaxLotPerOrder;
               double sl = OrderStopLoss();
               double tp = OrderTakeProfit();
               int type = OrderType();
               string sym = OrderSymbol();

               double point = MarketInfo(sym, MODE_POINT);
               double price = (type == OP_BUY) ? MarketInfo(sym, MODE_ASK) : MarketInfo(sym, MODE_BID);

               double lotsFromRisk = MaxLotPerOrder;
               if (sl > 0)
               {
                  double stopDist = MathAbs(price - sl);
                  double pipValue = MarketInfo(sym, MODE_TICKVALUE);
                  double riskDollars = AccountBalance() * AccountRiskPercent / 100;
                  lotsFromRisk = NormalizeDouble(riskDollars / (stopDist / point * pipValue), 2);
               }

               int expectedSplits = MathCeil(remainingLots / MaxLotPerOrder);
               string msgHeader = StringFormat("MonkeyAttackLotSplit Alert:\nSymbol: %s\nOriginal Lot Size: %.2f\nExpected Splits: %d\nRisk-Based Lot: %.2f\n\n",
                                               sym, origLots, expectedSplits, lotsFromRisk);

               string ticketLog = "";
               string errorLog = "";
               totalSplitLots = 0;

               while (remainingLots >= 0.01)
               {
                  double lotToSend = MathMin(remainingLots, MaxLotPerOrder);
                  double sendPrice = (type == OP_BUY) ? MarketInfo(sym, MODE_ASK) : MarketInfo(sym, MODE_BID);
                  double deviation = MathAbs(price - sendPrice) / point;

                  if (deviation > MaxAllowedSlippagePips)
                  {
                     errorLog += StringFormat("Aborted split: %.2f lots | Slippage %.2f pips > %.2f\n", lotToSend, deviation, MaxAllowedSlippagePips);
                     break;
                  }

                  if (EnableTradeExecution)
                  {
                     int newTicket = OrderSend(sym, type, lotToSend, sendPrice, Slippage, sl, tp, "Split Order", MagicNumber, 0, clrBlue);
                     if (newTicket > 0)
                     {
                        ticketLog += StringFormat("Split order placed: %.2f lots | Ticket: %d\n", lotToSend, newTicket);
                        totalSplitLots += lotToSend;
                     }
                     else
                     {
                        int err = GetLastError();
                        errorLog += StringFormat("FAILED to place %.2f lots | Error: %d\n", lotToSend, err);
                        Print("Split order failed: ", err);
                        break;
                     }
                  }
                  else
                  {
                     ticketLog += StringFormat("[SIMULATED] Split %.2f lots at price %.5f\n", lotToSend, sendPrice);
                     totalSplitLots += lotToSend;
                  }

                  remainingLots -= lotToSend;
               }

               string finalMsg = msgHeader + ticketLog + errorLog;
               Alert(finalMsg);
               Print(finalMsg);
               SendMail(EmailSubject, finalMsg);

               int file = FileOpen(LogFileName, FILE_CSV|FILE_WRITE|FILE_READ|FILE_SHARE_WRITE, ',');
               if (file != INVALID_HANDLE)
               {
                  FileSeek(file, 0, SEEK_END);
                  FileWrite(file, TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES), sym, origLots, EnableTradeExecution ? "SplitExecuted" : "Simulated");
                  FileClose(file);
               }

               lastTicketChecked = ticket;
            }
         }
      }
   }

   return(0);
}
