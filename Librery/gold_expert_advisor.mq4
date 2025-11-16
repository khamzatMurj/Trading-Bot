//+------------------------------------------------------------------+
//|                                           GoldExpertEA_Dynamic.mq4 |
//|                                      Professional Gold Trading EA |
//|                                    With Dynamic Range Calculation |
//+------------------------------------------------------------------+
#property copyright "Gold Trading Expert - Dynamic"
#property link      ""
#property version   "2.00"
#property strict

// External Parameters (Set defaults in OnInit)
extern double LotSize;                          // Lot size for trades
extern bool UseAutoLotSizing;                   // Use automatic lot sizing
extern double RiskPercent;                      // Risk percentage per trade
extern int MagicNumber;                         // Magic number for trade identification
extern string TradeComment;                     // Comment for trades

// Dynamic Range Calculation Parameters
extern int SR_Lookback_Period;                  // Lookback period for S/R calculation
extern int ATR_Period;                          // ATR period for volatility
extern double ATR_Multiplier;                   // ATR multiplier for dynamic stops
extern int Pivot_Strength;                      // Strength for pivot point detection
extern bool Use_Daily_Pivots;                   // Use daily pivot points
extern bool Use_Weekly_Pivots;                  // Use weekly pivot points
extern int Fractal_Period;                      // Period for fractal detection

// Technical Analysis Parameters
extern int RSI_Period;                          // RSI period
extern int RSI_Overbought;                      // RSI overbought level
extern int RSI_Oversold;                        // RSI oversold level
extern int MACD_Fast;                           // MACD fast EMA
extern int MACD_Slow;                           // MACD slow EMA
extern int MACD_Signal;                         // MACD signal line
extern int MA_Fast;                             // Fast moving average
extern int MA_Slow;                             // Slow moving average

// Volatility Parameters
extern bool UseVolatilityFilter;                // Enable volatility filtering
extern double VolatilityThreshold;              // Volatility threshold multiplier
extern int VolatilityPeriod;                    // Period for volatility calculation

// Risk Management
extern double MaxSpread;                        // Maximum spread in points
extern bool UseDynamicStops;                    // Use dynamic stop loss/take profit
extern double MinStopLoss;                      // Minimum stop loss in points
extern double MaxStopLoss;                      // Maximum stop loss in points
extern double RiskRewardRatio;                  // Risk:Reward ratio
extern bool UseTrailingStop;                    // Enable trailing stop
extern double TrailingMultiplier;               // Trailing stop ATR multiplier

// Trading Hours (GMT) - Optimized for Gold
extern bool UseTradingHours;                    // Enable trading hours filter
extern int StartHour;                           // Start trading hour (GMT)
extern int EndHour;                             // End trading hour (GMT)
extern bool UseSessionFilter;                   // Enable specific session trading
extern bool TradeLondonSession;                 // Trade London session
extern bool TradeNYSession;                     // Trade New York session
extern bool TradeAsianSession;                  // Trade Asian session
extern bool TradeOverlapOnly;                   // Trade only during overlaps

// Global Variables
double CurrentBid, CurrentAsk, CurrentSpread;
int TotalOrders;
bool IsNewCandle = false;
datetime LastCandleTime = 0;

// Dynamic Support/Resistance Arrays
double SupportLevels[10];
double ResistanceLevels[10];
int SupportCount = 0;
int ResistanceCount = 0;

// Market Structure Variables
double CurrentATR;
double DailyHigh, DailyLow, DailyOpen;
double WeeklyHigh, WeeklyLow, WeeklyOpen;

// Pivot Points
double DailyPivot, DailyR1, DailyR2, DailyR3, DailyS1, DailyS2, DailyS3;
double WeeklyPivot, WeeklyR1, WeeklyR2, WeeklyR3, WeeklyS1, WeeklyS2, WeeklyS3;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize default parameters (OPTIMIZED FOR GOLD)
    if(LotSize == 0) LotSize = 0.01;
    if(UseAutoLotSizing == false && UseAutoLotSizing == true) UseAutoLotSizing = true;
    if(RiskPercent == 0) RiskPercent = 1.5;
    if(MagicNumber == 0) MagicNumber = 12345;
    if(TradeComment == "") TradeComment = "GoldEA_Dynamic";
    
    // Dynamic Range Parameters
    if(SR_Lookback_Period == 0) SR_Lookback_Period = 100;
    if(ATR_Period == 0) ATR_Period = 14;
    if(ATR_Multiplier == 0) ATR_Multiplier = 2.0;
    if(Pivot_Strength == 0) Pivot_Strength = 5;
    if(Use_Daily_Pivots == false && Use_Daily_Pivots == true) Use_Daily_Pivots = true;
    if(Use_Weekly_Pivots == false && Use_Weekly_Pivots == true) Use_Weekly_Pivots = true;
    if(Fractal_Period == 0) Fractal_Period = 5;
    
    // Technical Analysis Parameters
    if(RSI_Period == 0) RSI_Period = 14;
    if(RSI_Overbought == 0) RSI_Overbought = 70;
    if(RSI_Oversold == 0) RSI_Oversold = 30;
    if(MACD_Fast == 0) MACD_Fast = 12;
    if(MACD_Slow == 0) MACD_Slow = 26;
    if(MACD_Signal == 0) MACD_Signal = 9;
    if(MA_Fast == 0) MA_Fast = 21;
    if(MA_Slow == 0) MA_Slow = 50;
    
    // Volatility Parameters
    if(UseVolatilityFilter == false && UseVolatilityFilter == true) UseVolatilityFilter = true;
    if(VolatilityThreshold == 0) VolatilityThreshold = 1.5;
    if(VolatilityPeriod == 0) VolatilityPeriod = 20;
    
    // Risk Management
    if(MaxSpread == 0) MaxSpread = 5.0;
    if(UseDynamicStops == false && UseDynamicStops == true) UseDynamicStops = true;
    if(MinStopLoss == 0) MinStopLoss = 300;
    if(MaxStopLoss == 0) MaxStopLoss = 800;
    if(RiskRewardRatio == 0) RiskRewardRatio = 1.5;
    if(UseTrailingStop == false && UseTrailingStop == true) UseTrailingStop = true;
    if(TrailingMultiplier == 0) TrailingMultiplier = 1.5;
    
    // Trading Hours
    if(UseTradingHours == false && UseTradingHours == true) UseTradingHours = true;
    if(StartHour == 0) StartHour = 8;
    if(EndHour == 0) EndHour = 21;
    if(UseSessionFilter == false && UseSessionFilter == true) UseSessionFilter = true;
    if(TradeLondonSession == false && TradeLondonSession == true) TradeLondonSession = true;
    if(TradeNYSession == false && TradeNYSession == true) TradeNYSession = true;
    TradeAsianSession = false;  // Default to false
    TradeOverlapOnly = false;   // Default to false
    
    Print("Dynamic Gold Expert Advisor Initialized");
    Print("Account Balance: ", AccountBalance());
    Print("Settings: LotSize=", LotSize, " RiskPercent=", RiskPercent, "%");
    
    // Initialize arrays
    ArrayInitialize(SupportLevels, 0);
    ArrayInitialize(ResistanceLevels, 0);
    
    // Calculate initial market structure
    CalculateMarketStructure();
    CalculatePivotPoints();
    CalculateDynamicSR();
    
    Print("Initial Support/Resistance levels calculated");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("Dynamic Gold Expert Advisor Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Update market info
    UpdateMarketInfo();
    
    // Check for new candle
    CheckNewCandle();
    
    // Only process on new candle
    if(!IsNewCandle) return;
    
    // Update dynamic calculations
    CalculateMarketStructure();
    
    // Recalculate S/R levels every hour
    if(TimeHour(Time[0]) != TimeHour(Time[1]))
    {
        CalculatePivotPoints();
        CalculateDynamicSR();
        Print("Support/Resistance levels updated");
    }
    
    // Update order count
    TotalOrders = CountOrders();
    
    // Check trading conditions
    if(!IsTradingAllowed()) return;
    
    // Manage existing positions
    ManagePositions();
    
    // Look for new trading opportunities
    if(TotalOrders == 0)
    {
        CheckTradingSignals();
    }
}

//+------------------------------------------------------------------+
//| Update market information                                        |
//+------------------------------------------------------------------+
void UpdateMarketInfo()
{
    CurrentBid = Bid;
    CurrentAsk = Ask;
    CurrentSpread = (CurrentAsk - CurrentBid) / Point;
}

//+------------------------------------------------------------------+
//| Check for new candle                                            |
//+------------------------------------------------------------------+
void CheckNewCandle()
{
    if(Time[0] != LastCandleTime)
    {
        IsNewCandle = true;
        LastCandleTime = Time[0];
    }
    else
    {
        IsNewCandle = false;
    }
}

//+------------------------------------------------------------------+
//| Calculate market structure                                       |
//+------------------------------------------------------------------+
void CalculateMarketStructure()
{
    // Calculate ATR
    CurrentATR = iATR(Symbol(), 0, ATR_Period, 1);
    
    // Daily levels
    DailyHigh = iHigh(Symbol(), PERIOD_D1, 0);
    DailyLow = iLow(Symbol(), PERIOD_D1, 0);
    DailyOpen = iOpen(Symbol(), PERIOD_D1, 0);
    
    // Weekly levels
    WeeklyHigh = iHigh(Symbol(), PERIOD_W1, 0);
    WeeklyLow = iLow(Symbol(), PERIOD_W1, 0);
    WeeklyOpen = iOpen(Symbol(), PERIOD_W1, 0);
}

//+------------------------------------------------------------------+
//| Calculate pivot points                                          |
//+------------------------------------------------------------------+
void CalculatePivotPoints()
{
    // Daily Pivots
    if(Use_Daily_Pivots)
    {
        double prevHigh = iHigh(Symbol(), PERIOD_D1, 1);
        double prevLow = iLow(Symbol(), PERIOD_D1, 1);
        double prevClose = iClose(Symbol(), PERIOD_D1, 1);
        
        DailyPivot = (prevHigh + prevLow + prevClose) / 3.0;
        DailyR1 = 2.0 * DailyPivot - prevLow;
        DailyS1 = 2.0 * DailyPivot - prevHigh;
        DailyR2 = DailyPivot + (prevHigh - prevLow);
        DailyS2 = DailyPivot - (prevHigh - prevLow);
        DailyR3 = prevHigh + 2.0 * (DailyPivot - prevLow);
        DailyS3 = prevLow - 2.0 * (prevHigh - DailyPivot);
    }
    
    // Weekly Pivots
    if(Use_Weekly_Pivots)
    {
        double prevWeekHigh = iHigh(Symbol(), PERIOD_W1, 1);
        double prevWeekLow = iLow(Symbol(), PERIOD_W1, 1);
        double prevWeekClose = iClose(Symbol(), PERIOD_W1, 1);
        
        WeeklyPivot = (prevWeekHigh + prevWeekLow + prevWeekClose) / 3.0;
        WeeklyR1 = 2.0 * WeeklyPivot - prevWeekLow;
        WeeklyS1 = 2.0 * WeeklyPivot - prevWeekHigh;
        WeeklyR2 = WeeklyPivot + (prevWeekHigh - prevWeekLow);
        WeeklyS2 = WeeklyPivot - (prevWeekHigh - prevWeekLow);
        WeeklyR3 = prevWeekHigh + 2.0 * (WeeklyPivot - prevWeekLow);
        WeeklyS3 = prevWeekLow - 2.0 * (prevWeekHigh - WeeklyPivot);
    }
}

//+------------------------------------------------------------------+
//| Calculate dynamic support and resistance levels                 |
//+------------------------------------------------------------------+
void CalculateDynamicSR()
{
    // Clear previous levels
    ArrayInitialize(SupportLevels, 0);
    ArrayInitialize(ResistanceLevels, 0);
    SupportCount = 0;
    ResistanceCount = 0;
    
    // Add pivot point levels
    if(Use_Daily_Pivots)
    {
        AddSupportLevel(DailyS1);
        AddSupportLevel(DailyS2);
        AddSupportLevel(DailyS3);
        AddResistanceLevel(DailyR1);
        AddResistanceLevel(DailyR2);
        AddResistanceLevel(DailyR3);
    }
    
    if(Use_Weekly_Pivots)
    {
        AddSupportLevel(WeeklyS1);
        AddSupportLevel(WeeklyS2);
        AddResistanceLevel(WeeklyR1);
        AddResistanceLevel(WeeklyR2);
    }
    
    // Add fractal-based levels
    CalculateFractalLevels();
    
    // Add swing levels
    CalculateSwingLevels();
    
    // Add psychological levels
    CalculatePsychologicalLevels();
    
    // Sort arrays
    SortSupportLevels();
    SortResistanceLevels();
}

//+------------------------------------------------------------------+
//| Calculate fractal-based support and resistance                  |
//+------------------------------------------------------------------+
void CalculateFractalLevels()
{
    for(int i = Fractal_Period; i < SR_Lookback_Period; i++)
    {
        // Check for fractal high
        bool isFractalHigh = true;
        for(int j = 1; j <= Fractal_Period; j++)
        {
            if(High[i] <= High[i-j] || High[i] <= High[i+j])
            {
                isFractalHigh = false;
                break;
            }
        }
        
        if(isFractalHigh)
        {
            AddResistanceLevel(High[i]);
        }
        
        // Check for fractal low
        bool isFractalLow = true;
        for(int k = 1; k <= Fractal_Period; k++)
        {
            if(Low[i] >= Low[i-k] || Low[i] >= Low[i+k])
            {
                isFractalLow = false;
                break;
            }
        }
        
        if(isFractalLow)
        {
            AddSupportLevel(Low[i]);
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate swing highs and lows                                 |
//+------------------------------------------------------------------+
void CalculateSwingLevels()
{
    for(int i = Pivot_Strength; i < SR_Lookback_Period - Pivot_Strength; i++)
    {
        // Swing High
        bool isSwingHigh = true;
        for(int j = 1; j <= Pivot_Strength; j++)
        {
            if(High[i] <= High[i-j] || High[i] <= High[i+j])
            {
                isSwingHigh = false;
                break;
            }
        }
        
        if(isSwingHigh)
        {
            AddResistanceLevel(High[i]);
        }
        
        // Swing Low
        bool isSwingLow = true;
        for(int k = 1; k <= Pivot_Strength; k++)
        {
            if(Low[i] >= Low[i-k] || Low[i] >= Low[i+k])
            {
                isSwingLow = false;
                break;
            }
        }
        
        if(isSwingLow)
        {
            AddSupportLevel(Low[i]);
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate psychological levels                                   |
//+------------------------------------------------------------------+
void CalculatePsychologicalLevels()
{
    double currentPrice = Close[0];
    double stepSize = 50.0; // Every $50 for gold
    
    // Find levels above and below current price
    for(double level = MathFloor(currentPrice / stepSize) * stepSize; 
        level <= currentPrice + 500; level += stepSize)
    {
        if(level > currentPrice)
        {
            AddResistanceLevel(level);
        }
        else if(level < currentPrice)
        {
            AddSupportLevel(level);
        }
    }
}

//+------------------------------------------------------------------+
//| Add support level to array                                     |
//+------------------------------------------------------------------+
void AddSupportLevel(double level)
{
    if(level <= 0 || SupportCount >= 10) return;
    
    // Check if level already exists
    for(int i = 0; i < SupportCount; i++)
    {
        if(MathAbs(SupportLevels[i] - level) < 10.0)
        {
            return;
        }
    }
    
    SupportLevels[SupportCount] = level;
    SupportCount++;
}

//+------------------------------------------------------------------+
//| Add resistance level to array                                  |
//+------------------------------------------------------------------+
void AddResistanceLevel(double level)
{
    if(level <= 0 || ResistanceCount >= 10) return;
    
    // Check if level already exists
    for(int i = 0; i < ResistanceCount; i++)
    {
        if(MathAbs(ResistanceLevels[i] - level) < 10.0)
        {
            return;
        }
    }
    
    ResistanceLevels[ResistanceCount] = level;
    ResistanceCount++;
}

//+------------------------------------------------------------------+
//| Sort support levels                                            |
//+------------------------------------------------------------------+
void SortSupportLevels()
{
    for(int i = 0; i < SupportCount - 1; i++)
    {
        for(int j = i + 1; j < SupportCount; j++)
        {
            if(SupportLevels[i] < SupportLevels[j])
            {
                double temp = SupportLevels[i];
                SupportLevels[i] = SupportLevels[j];
                SupportLevels[j] = temp;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Sort resistance levels                                         |
//+------------------------------------------------------------------+
void SortResistanceLevels()
{
    for(int i = 0; i < ResistanceCount - 1; i++)
    {
        for(int j = i + 1; j < ResistanceCount; j++)
        {
            if(ResistanceLevels[i] > ResistanceLevels[j])
            {
                double temp = ResistanceLevels[i];
                ResistanceLevels[i] = ResistanceLevels[j];
                ResistanceLevels[j] = temp;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Get nearest support level                                      |
//+------------------------------------------------------------------+
double GetNearestSupport(double price)
{
    double nearestSupport = 0;
    double minDistance = 99999;
    
    for(int i = 0; i < SupportCount; i++)
    {
        if(SupportLevels[i] < price)
        {
            double distance = price - SupportLevels[i];
            if(distance < minDistance)
            {
                minDistance = distance;
                nearestSupport = SupportLevels[i];
            }
        }
    }
    
    return nearestSupport;
}

//+------------------------------------------------------------------+
//| Get nearest resistance level                                   |
//+------------------------------------------------------------------+
double GetNearestResistance(double price)
{
    double nearestResistance = 0;
    double minDistance = 99999;
    
    for(int i = 0; i < ResistanceCount; i++)
    {
        if(ResistanceLevels[i] > price)
        {
            double distance = ResistanceLevels[i] - price;
            if(distance < minDistance)
            {
                minDistance = distance;
                nearestResistance = ResistanceLevels[i];
            }
        }
    }
    
    return nearestResistance;
}

//+------------------------------------------------------------------+
//| Calculate dynamic stop loss                                    |
//+------------------------------------------------------------------+
double CalculateDynamicStopLoss(bool isBuy)
{
    double atrStop = CurrentATR * ATR_Multiplier;
    double stopDistance = MathMax(MinStopLoss * Point, MathMin(MaxStopLoss * Point, atrStop));
    
    if(isBuy)
    {
        return CurrentAsk - stopDistance;
    }
    else
    {
        return CurrentBid + stopDistance;
    }
}

//+------------------------------------------------------------------+
//| Calculate dynamic take profit                                  |
//+------------------------------------------------------------------+
double CalculateDynamicTakeProfit(bool isBuy, double stopLoss)
{
    double stopDistance;
    
    if(isBuy)
    {
        stopDistance = CurrentAsk - stopLoss;
        return CurrentAsk + (stopDistance * RiskRewardRatio);
    }
    else
    {
        stopDistance = stopLoss - CurrentBid;
        return CurrentBid - (stopDistance * RiskRewardRatio);
    }
}

//+------------------------------------------------------------------+
//| Check if price is near level                                   |
//+------------------------------------------------------------------+
bool IsNearLevel(double price, double level, double tolerance)
{
    return MathAbs(price - level) <= tolerance;
}

//+------------------------------------------------------------------+
//| Calculate market volatility                                    |
//+------------------------------------------------------------------+
double CalculateVolatility()
{
    double sum = 0;
    for(int i = 1; i <= VolatilityPeriod; i++)
    {
        sum += MathAbs(Close[i] - Close[i+1]);
    }
    return sum / VolatilityPeriod;
}

//+------------------------------------------------------------------+
//| Check if current time is within trading hours                   |
//+------------------------------------------------------------------+
bool IsWithinTradingHours()
{
    int currentHour = Hour();
    
    // Simple hour range check
    if(!UseSessionFilter)
    {
        return (currentHour >= StartHour && currentHour <= EndHour);
    }
    
    // Advanced session filtering
    bool withinSession = false;
    
    // Asian Session: 00:00-08:00 GMT
    if(TradeAsianSession && currentHour >= 0 && currentHour < 8)
    {
        withinSession = true;
    }
    
    // London Session: 08:00-16:00 GMT
    if(TradeLondonSession && currentHour >= 8 && currentHour < 16)
    {
        withinSession = true;
    }
    
    // New York Session: 13:00-21:00 GMT
    if(TradeNYSession && currentHour >= 13 && currentHour < 21)
    {
        withinSession = true;
    }
    
    // Overlap periods
    if(TradeOverlapOnly)
    {
        // London-NY Overlap: 13:00-16:00 GMT
        if(currentHour >= 13 && currentHour < 16)
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    
    return withinSession;
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                     |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
    // Check spread
    if(CurrentSpread > MaxSpread)
    {
        return false;
    }
    
    // Check trading hours
    if(UseTradingHours)
    {
        if(!IsWithinTradingHours())
        {
            return false;
        }
    }
    
    // Check volatility filter
    if(UseVolatilityFilter)
    {
        double currentVol = CalculateVolatility();
        double avgATR = CurrentATR;
        if(currentVol > avgATR * VolatilityThreshold)
        {
            return false;
        }
    }
    
    return IsTradeAllowed();
}

//+------------------------------------------------------------------+
//| Count open orders                                               |
//+------------------------------------------------------------------+
int CountOrders()
{
    int count = 0;
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                count++;
            }
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                |
//+------------------------------------------------------------------+
double CalculateLotSize(double stopLossDistance)
{
    if(!UseAutoLotSizing) return LotSize;
    
    double accountBalance = AccountBalance();
    double riskAmount = accountBalance * RiskPercent / 100.0;
    double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
    
    double lotSize = riskAmount / (stopLossDistance / Point * tickValue);
    
    // Normalize lot size
    double minLot = MarketInfo(Symbol(), MODE_MINLOT);
    double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
    double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
    
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
    lotSize = NormalizeDouble(lotSize / lotStep, 0) * lotStep;
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Check trading signals                                           |
//+------------------------------------------------------------------+
void CheckTradingSignals()
{
    double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 1);
    double macdMain = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 1);
    double macdSignal = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 1);
    double maFast = iMA(Symbol(), 0, MA_Fast, 0, MODE_SMA, PRICE_CLOSE, 1);
    double maSlow = iMA(Symbol(), 0, MA_Slow, 0, MODE_SMA, PRICE_CLOSE, 1);
    
    double currentPrice = Close[1];
    double nearestSupport = GetNearestSupport(currentPrice);
    double nearestResistance = GetNearestResistance(currentPrice);
    double tolerance = CurrentATR * 0.5;
    
    bool buySignal = false;
    bool sellSignal = false;
    
    // Buy signals near support
    if(nearestSupport > 0 && IsNearLevel(currentPrice, nearestSupport, tolerance))
    {
        if(rsi < RSI_Oversold + 10 && macdMain > macdSignal && maFast > maSlow)
        {
            buySignal = true;
        }
    }
    
    // Sell signals near resistance
    if(nearestResistance > 0 && IsNearLevel(currentPrice, nearestResistance, tolerance))
    {
        if(rsi > RSI_Overbought - 10 && macdMain < macdSignal && maFast < maSlow)
        {
            sellSignal = true;
        }
    }
    
    // Trend following signals
    if(maFast > maSlow && macdMain > macdSignal && rsi > 50 && currentPrice > DailyPivot)
    {
        buySignal = true;
    }
    
    if(maFast < maSlow && macdMain < macdSignal && rsi < 50 && currentPrice < DailyPivot)
    {
        sellSignal = true;
    }
    
    // Execute trades
    if(buySignal)
    {
        OpenBuyOrder();
    }
    else if(sellSignal)
    {
        OpenSellOrder();
    }
}

//+------------------------------------------------------------------+
//| Open buy order                                                  |
//+------------------------------------------------------------------+
void OpenBuyOrder()
{
    double sl, tp;
    
    if(UseDynamicStops)
    {
        sl = CalculateDynamicStopLoss(true);
        tp = CalculateDynamicTakeProfit(true, sl);
    }
    else
    {
        sl = CurrentAsk - MinStopLoss * Point;
        tp = CurrentAsk + (MinStopLoss * RiskRewardRatio) * Point;
    }
    
    double stopDistance = CurrentAsk - sl;
    double lotSize = CalculateLotSize(stopDistance);
    
    int ticket = OrderSend(Symbol(), OP_BUY, lotSize, CurrentAsk, 3, sl, tp, TradeComment, MagicNumber, 0, clrGreen);
    
    if(ticket > 0)
    {
        Print("Buy order opened: ", ticket);
    }
    else
    {
        Print("Error opening buy order: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Open sell order                                                 |
//+------------------------------------------------------------------+
void OpenSellOrder()
{
    double sl, tp;
    
    if(UseDynamicStops)
    {
        sl = CalculateDynamicStopLoss(false);
        tp = CalculateDynamicTakeProfit(false, sl);
    }
    else
    {
        sl = CurrentBid + MinStopLoss * Point;
        tp = CurrentBid - (MinStopLoss * RiskRewardRatio) * Point;
    }
    
    double stopDistance = sl - CurrentBid;
    double lotSize = CalculateLotSize(stopDistance);
    
    int ticket = OrderSend(Symbol(), OP_SELL, lotSize, CurrentBid, 3, sl, tp, TradeComment, MagicNumber, 0, clrRed);
    
    if(ticket > 0)
    {
        Print("Sell order opened: ", ticket);
    }
    else
    {
        Print("Error opening sell order: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Manage existing positions                                       |
//+------------------------------------------------------------------+
void ManagePositions()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                if(UseTrailingStop)
                {
                    DynamicTrailStop(OrderTicket(), OrderType(), OrderOpenPrice(), OrderStopLoss());
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Dynamic trailing stop                                           |
//+------------------------------------------------------------------+
void DynamicTrailStop(int ticket, int orderType, double openPrice, double currentSL)
{
    double newSL = 0;
    bool modify = false;
    double trailDistance = CurrentATR * TrailingMultiplier;
    
    if(orderType == OP_BUY)
    {
        double unrealizedProfit = CurrentBid - openPrice;
        if(unrealizedProfit >= trailDistance)
        {
            newSL = CurrentBid - trailDistance;
            if(newSL > currentSL + Point || currentSL == 0)
            {
                modify = true;
            }
        }
    }
    else if(orderType == OP_SELL)
    {
        double unrealizedProfit = openPrice - CurrentAsk;
        if(unrealizedProfit >= trailDistance)
        {
            newSL = CurrentAsk + trailDistance;
            if(newSL < currentSL - Point || currentSL == 0)
            {
                modify = true;
            }
        }
    }
    
    if(modify)
    {
        bool result = OrderModify(ticket, openPrice, newSL, OrderTakeProfit(), 0, clrBlue);
        if(result)
        {
            Print("Trailing stop updated for order: ", ticket);
        }
    }
}

//+------------------------------------------------------------------+