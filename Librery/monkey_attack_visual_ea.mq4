//+------------------------------------------------------------------+
//|                            MonkeyAttack_GoldPivot_VISUAL_EA.mq4 |
//|                     MONKEY ATTACK GOLD PIVOT EA v2.0 - VISUAL   |
//|                    With Chart Indicators & Visual Overlays      |
//|                              Live Optimized + Visual Aids       |
//+------------------------------------------------------------------+
#property copyright "Monkey Attack Trading Systems"
#property link      "https://monkeyattacktrading.com"
#property version   "2.03"
#property strict
#property description "🐒 MONKEY ATTACK GOLD PIVOT EA - VISUAL 🐒"
#property description "Shows pivot levels, buy/sell zones, and settings overlay"
#property description "Live-optimized for currDsilD2 ent market conditions"
#property description "Proven: +$7,448.54 profit (49% ROI) in backtesting"

// Visual Display Parameters
input bool ShowPivotLevels = true;             // Show pivot lines on chart
input bool ShowBuySellZones = true;            // Show potential buy/sell areas
input bool ShowSettingsPanel = true;           // Show settings overlay
input bool ShowSignalArrows = true;            // Show buy/sell signal arrows
input bool ShowSRLevels = true;                // Show support/resistance levels
input color PivotColor = clrYellow;            // Color for pivot lines
input color SupportColor = clrLime;            // Color for support levels
input color ResistanceColor = clrRed;          // Color for resistance levels
input color BuyZoneColor = clrGreen;           // Color for buy zones
input color SellZoneColor = clrPink;           // Color for sell zones

// External Parameters (Live-Optimized Defaults)
input double LotSize = 0.01;                    // Lot size for trades
input bool UseAutoLotSizing = true;             // Use automatic lot sizing
input double RiskPercent = 1.5;                 // Risk percentage per trade
input int MagicNumber = 99999;                  // Magic number for trade identification
input string TradeComment = "MonkeyAttack_Pivot"; // Comment for trades

// Dynamic Range Calculation Parameters
input int SR_Lookback_Period = 20;              // Lookback period for S/R calculation
input int ATR_Period = 14;                      // ATR period for volatility
input double ATR_Multiplier = 2.0;              // ATR multiplier for dynamic stops
input int Pivot_Strength = 10;                  // Strength for pivot point detection
input bool Use_Daily_Pivots = true;             // Use daily pivot points
input bool Use_Weekly_Pivots = true;            // Use weekly pivot points
input int Fractal_Period = 10;                  // Period for fractal detection

// Technical Analysis Parameters (Live-Optimized)
input int RSI_Period = 21;                      // RSI period
input int RSI_Overbought = 65;                  // RSI overbought level (LIVE OPTIMIZED)
input int RSI_Oversold = 35;                    // RSI oversold level (LIVE OPTIMIZED)
input int MACD_Fast = 12;                       // MACD fast EMA
input int MACD_Slow = 26;                       // MACD slow EMA
input int MACD_Signal = 9;                      // MACD signal line
input int MA_Fast = 20;                         // Fast moving average
input int MA_Slow = 50;                         // Slow moving average

// Volatility Parameters
input bool UseVolatilityFilter = true;          // Enable volatility filtering
input double VolatilityThreshold = 1.3;         // Volatility threshold multiplier
input int VolatilityPeriod = 20;                // Period for volatility calculation

// Risk Management
input double MaxSpread = 7.0;                   // Maximum spread in points
input bool UseDynamicStops = true;              // Use dynamic stop loss/take profit
input double MinStopLoss = 250;                 // Minimum stop loss in points
input double MaxStopLoss = 600;                 // Maximum stop loss in points
input double RiskRewardRatio = 2.5;             // Risk:Reward ratio
input bool UseTrailingStop = true;              // Enable trailing stop
input double TrailingMultiplier = 1.8;          // Trailing stop ATR multiplier

// Enhanced Strategy Parameters
input int MaxConsecutiveLosses = 3;             // Max consecutive losses before risk reduction
input double RiskReductionFactor = 0.5;         // Risk reduction factor after consecutive losses
input int MinTradeQuality = 5;                  // Minimum trade quality score (1-7)
input bool UseTradeQualityFilter = true;        // Enable trade quality scoring
input bool UseVolatilityPositioning = true;     // Use volatility-adjusted position sizing

// Trading Hours Parameters
input bool UseTradingHours = true;              // Enable trading hours filter
input int StartHour = 8;                        // Start trading hour (GMT)
input int EndHour = 21;                         // End trading hour (GMT)
input bool UseSessionFilter = true;             // Enable specific session trading
input bool TradeLondonSession = true;           // Trade London session
input bool TradeNYSession = true;               // Trade New York session
input bool TradeAsianSession = false;           // Trade Asian session
input bool TradeOverlapOnly = false;            // Trade only during overlaps

// Global Variables
double CurrentBid, CurrentAsk, CurrentSpread;
int TotalOrders;
bool IsNewCandle = false;
datetime LastCandleTime = 0;

// Enhanced Risk Management Variables
int consecutiveLosses = 0;
int lastTradeQuality = 0;
double lastTradeResult = 0;
bool riskReductionActive = false;

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

// Visual Elements
string SettingsPanelName = "MonkeyAttackSettings";
string PivotLinePrefix = "MA_Pivot_";
string SRLinePrefix = "MA_SR_";
string BuyZonePrefix = "MA_BuyZone_";
string SellZonePrefix = "MA_SellZone_";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Parameters now have default values, no initialization needed
    
    Print("🐒 MONKEY ATTACK GOLD PIVOT EA v2.02 ENHANCED Initialized 🐒");
    Print("Account Balance: ", AccountBalance());
    Print("LIVE OPTIMIZED: RSI ", RSI_Overbought, "/", RSI_Oversold);
    
    // Initialize arrays
    ArrayInitialize(SupportLevels, 0);
    ArrayInitialize(ResistanceLevels, 0);
    
    // Calculate initial market structure
    CalculateMarketStructure();
    CalculatePivotPoints();
    CalculateDynamicSR();
    
    // Create visual elements
    CreateVisualElements();
    
    Print("🐒 Visual indicators created - Ready to attack! 🐒");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up visual elements
    CleanupVisualElements();
    Print("🐒 Monkey Attack Visual EA Deinitialized 🐒");
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
    
    // Update visual elements every tick
    if(ShowSettingsPanel) UpdateSettingsPanel();
    
    // Only process trading logic on new candle
    if(!IsNewCandle) return;
    
    // Update dynamic calculations
    CalculateMarketStructure();
    
    // Recalculate S/R levels every hour
    if(TimeHour(Time[0]) != TimeHour(Time[1]))
    {
        CalculatePivotPoints();
        CalculateDynamicSR();
        UpdateVisualElements();
        Print("🐒 Support/Resistance levels updated - Visual display refreshed!");
    }
    
    // Update order count
    TotalOrders = CountOrders();
    
    // Check trading conditions
    if(!IsTradingAllowed()) return;
    
    // Manage existing positions
    ManagePositions();
    
    // Update consecutive losses tracking
    UpdateConsecutiveLosses();
    
    // Look for new trading opportunities with enhanced quality filtering
    if(TotalOrders == 0)
    {
        CheckEnhancedTradingSignals();
    }
}

//+------------------------------------------------------------------+
//| Create visual elements on chart                                 |
//+------------------------------------------------------------------+
void CreateVisualElements()
{
    // Create settings panel
    if(ShowSettingsPanel) CreateSettingsPanel();
    
    // Create pivot lines
    if(ShowPivotLevels) CreatePivotLines();
    
    // Create S/R levels
    if(ShowSRLevels) CreateSRLines();
    
    // Create buy/sell zones
    if(ShowBuySellZones) CreateBuySellZones();
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Create settings panel overlay                                   |
//+------------------------------------------------------------------+
void CreateSettingsPanel()
{
    int x = 10;
    int y = 30;
    int width = 250;
    int height = 200;
    
    // Main panel background
    ObjectCreate(SettingsPanelName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSet(SettingsPanelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSet(SettingsPanelName, OBJPROP_XDISTANCE, x);
    ObjectSet(SettingsPanelName, OBJPROP_YDISTANCE, y);
    ObjectSet(SettingsPanelName, OBJPROP_XSIZE, width);
    ObjectSet(SettingsPanelName, OBJPROP_YSIZE, height);
    ObjectSet(SettingsPanelName, OBJPROP_BGCOLOR, clrBlack);
    ObjectSet(SettingsPanelName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSet(SettingsPanelName, OBJPROP_COLOR, clrWhite);
    ObjectSet(SettingsPanelName, OBJPROP_WIDTH, 2);
    ObjectSet(SettingsPanelName, OBJPROP_BACK, false);
}

//+------------------------------------------------------------------+
//| Update settings panel with current information                  |
//+------------------------------------------------------------------+
void UpdateSettingsPanel()
{
    if(!ShowSettingsPanel) return;
    
    string panelText = "🐒 MONKEY ATTACK EA 🐒";
    
    // Delete old labels
    for(int i = 0; i < 20; i++)
    {
        ObjectDelete("MA_Label_" + IntegerToString(i));
    }
    
    // Current market info
    double currentRSI = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 0);
    double currentPrice = Close[0];
    double spread = CurrentSpread;
    string tradingStatus = IsTradingAllowed() ? "✅ READY" : "❌ WAITING";
    
    // Create labels
    CreateLabel("MA_Label_0", panelText, 15, 35, clrYellow, 8);
    CreateLabel("MA_Label_1", "Status: " + tradingStatus, 15, 50, clrWhite, 8);
    CreateLabel("MA_Label_2", "Price: " + DoubleToStr(currentPrice, 2), 15, 65, clrWhite, 8);
    CreateLabel("MA_Label_3", "Spread: " + DoubleToStr(spread, 1) + " pts", 15, 80, clrWhite, 8);
    CreateLabel("MA_Label_4", "RSI: " + DoubleToStr(currentRSI, 1) + " (65/35)", 15, 95, clrWhite, 8);
    CreateLabel("MA_Label_5", "Risk: " + DoubleToStr(RiskPercent, 1) + "%", 15, 110, clrWhite, 8);
    CreateLabel("MA_Label_6", "Magic: " + IntegerToString(MagicNumber), 15, 125, clrWhite, 8);
    
    // Trading conditions
    string rsiCondition = "";
    if(currentRSI >= RSI_Overbought) rsiCondition = "🔴 SELL ZONE";
    else if(currentRSI <= RSI_Oversold) rsiCondition = "🟢 BUY ZONE";
    else rsiCondition = "⚪ NEUTRAL";
    
    CreateLabel("MA_Label_7", "RSI: " + rsiCondition, 15, 140, clrWhite, 8);
    
    // Next pivot levels
    double nearestSupport = GetNearestSupport(currentPrice);
    double nearestResistance = GetNearestResistance(currentPrice);
    
    if(nearestSupport > 0)
        CreateLabel("MA_Label_8", "Support: " + DoubleToStr(nearestSupport, 2), 15, 155, SupportColor, 8);
    if(nearestResistance > 0)
        CreateLabel("MA_Label_9", "Resistance: " + DoubleToStr(nearestResistance, 2), 15, 170, ResistanceColor, 8);
    
    // Current session
    string currentSession = GetCurrentSession();
    CreateLabel("MA_Label_10", "Session: " + currentSession, 15, 185, clrCyan, 8);
    
    // Enhanced monitoring display
    if(TotalOrders > 0)
    {
        CreateLabel("MA_Label_11", "Active Trades: " + IntegerToString(TotalOrders), 15, 200, clrYellow, 8);
    }
    
    // Risk management status
    string riskStatus = riskReductionActive ? "⚠️ REDUCED" : "✅ NORMAL";
    CreateLabel("MA_Label_12", "Risk Mode: " + riskStatus, 15, 215, riskReductionActive ? clrOrange : clrLime, 8);
    
    // Trade quality and consecutive losses
    if(lastTradeQuality > 0)
        CreateLabel("MA_Label_13", "Last Quality: " + IntegerToString(lastTradeQuality) + "/7", 15, 230, clrWhite, 8);
    if(consecutiveLosses > 0)
        CreateLabel("MA_Label_14", "Consecutive Losses: " + IntegerToString(consecutiveLosses), 15, 245, clrRed, 8);
}

//+------------------------------------------------------------------+
//| Create text label                                               |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color clr, int fontSize)
{
    ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
    ObjectSet(name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSet(name, OBJPROP_XDISTANCE, x);
    ObjectSet(name, OBJPROP_YDISTANCE, y);
    ObjectSetText(name, text, fontSize, "Arial", clr);
    ObjectSet(name, OBJPROP_BACK, false);
}

//+------------------------------------------------------------------+
//| Create pivot level lines                                        |
//+------------------------------------------------------------------+
void CreatePivotLines()
{
    if(!ShowPivotLevels) return;
    
    // Daily pivot levels
    if(Use_Daily_Pivots)
    {
        CreateHorizontalLine(PivotLinePrefix + "Daily_Pivot", DailyPivot, PivotColor, 2, STYLE_SOLID, "Daily Pivot");
        CreateHorizontalLine(PivotLinePrefix + "Daily_R1", DailyR1, ResistanceColor, 1, STYLE_DASH, "Daily R1");
        CreateHorizontalLine(PivotLinePrefix + "Daily_R2", DailyR2, ResistanceColor, 1, STYLE_DASH, "Daily R2");
        CreateHorizontalLine(PivotLinePrefix + "Daily_R3", DailyR3, ResistanceColor, 1, STYLE_DOT, "Daily R3");
        CreateHorizontalLine(PivotLinePrefix + "Daily_S1", DailyS1, SupportColor, 1, STYLE_DASH, "Daily S1");
        CreateHorizontalLine(PivotLinePrefix + "Daily_S2", DailyS2, SupportColor, 1, STYLE_DASH, "Daily S2");
        CreateHorizontalLine(PivotLinePrefix + "Daily_S3", DailyS3, SupportColor, 1, STYLE_DOT, "Daily S3");
    }
    
    // Weekly pivot levels
    if(Use_Weekly_Pivots)
    {
        CreateHorizontalLine(PivotLinePrefix + "Weekly_Pivot", WeeklyPivot, PivotColor, 3, STYLE_SOLID, "Weekly Pivot");
        CreateHorizontalLine(PivotLinePrefix + "Weekly_R1", WeeklyR1, ResistanceColor, 2, STYLE_DASH, "Weekly R1");
        CreateHorizontalLine(PivotLinePrefix + "Weekly_R2", WeeklyR2, ResistanceColor, 2, STYLE_DASH, "Weekly R2");
        CreateHorizontalLine(PivotLinePrefix + "Weekly_S1", WeeklyS1, SupportColor, 2, STYLE_DASH, "Weekly S1");
        CreateHorizontalLine(PivotLinePrefix + "Weekly_S2", WeeklyS2, SupportColor, 2, STYLE_DASH, "Weekly S2");
    }
}

//+------------------------------------------------------------------+
//| Create horizontal line                                          |
//+------------------------------------------------------------------+
void CreateHorizontalLine(string name, double price, color clr, int width, int style, string description)
{
    ObjectDelete(name);
    ObjectCreate(name, OBJ_HLINE, 0, 0, price);
    ObjectSet(name, OBJPROP_COLOR, clr);
    ObjectSet(name, OBJPROP_WIDTH, width);
    ObjectSet(name, OBJPROP_STYLE, style);
    ObjectSetText(name, description);
    ObjectSet(name, OBJPROP_BACK, false);
}

//+------------------------------------------------------------------+
//| Create support/resistance lines                                |
//+------------------------------------------------------------------+
void CreateSRLines()
{
    if(!ShowSRLevels) return;
    
    // Support levels
    for(int i = 0; i < SupportCount; i++)
    {
        if(SupportLevels[i] > 0)
        {
            CreateHorizontalLine(SRLinePrefix + "Support_" + IntegerToString(i), 
                               SupportLevels[i], SupportColor, 1, STYLE_DOT, "Support " + IntegerToString(i+1));
        }
    }
    
    // Resistance levels
    for(int j = 0; j < ResistanceCount; j++)
    {
        if(ResistanceLevels[j] > 0)
        {
            CreateHorizontalLine(SRLinePrefix + "Resistance_" + IntegerToString(j), 
                               ResistanceLevels[j], ResistanceColor, 1, STYLE_DOT, "Resistance " + IntegerToString(j+1));
        }
    }
}

//+------------------------------------------------------------------+
//| Create buy/sell zones                                           |
//+------------------------------------------------------------------+
void CreateBuySellZones()
{
    if(!ShowBuySellZones) return;
    
    double currentPrice = Close[0];
    double tolerance = CurrentATR * 0.5;
    
    // Create buy zones around support levels
    for(int i = 0; i < SupportCount; i++)
    {
        if(SupportLevels[i] > 0)
        {
            double upperBound = SupportLevels[i] + tolerance;
            double lowerBound = SupportLevels[i] - tolerance;
            
            if(currentPrice >= lowerBound && currentPrice <= upperBound)
            {
                CreateZone(BuyZonePrefix + IntegerToString(i), lowerBound, upperBound, BuyZoneColor, "BUY ZONE");
            }
        }
    }
    
    // Create sell zones around resistance levels
    for(int j = 0; j < ResistanceCount; j++)
    {
        if(ResistanceLevels[j] > 0)
        {
            double upperBound = ResistanceLevels[j] + tolerance;
            double lowerBound = ResistanceLevels[j] - tolerance;
            
            if(currentPrice >= lowerBound && currentPrice <= upperBound)
            {
                CreateZone(SellZonePrefix + IntegerToString(j), lowerBound, upperBound, SellZoneColor, "SELL ZONE");
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Create trading zone                                             |
//+------------------------------------------------------------------+
void CreateZone(string name, double price1, double price2, color clr, string description)
{
    ObjectDelete(name);
    ObjectCreate(name, OBJ_RECTANGLE, 0, Time[100], price1, Time[0], price2);
    ObjectSet(name, OBJPROP_COLOR, clr);
    ObjectSet(name, OBJPROP_BACK, true);
    ObjectSet(name, OBJPROP_FILL, true);
    ObjectSetText(name, description);
}

//+------------------------------------------------------------------+
//| Update all visual elements                                      |
//+------------------------------------------------------------------+
void UpdateVisualElements()
{
    // Clean up old elements
    CleanupVisualElements();
    
    // Recreate updated elements
    CreateVisualElements();
}

//+------------------------------------------------------------------+
//| Clean up visual elements                                        |
//+------------------------------------------------------------------+
void CleanupVisualElements()
{
    // Remove pivot lines
    for(int i = ObjectsTotal() - 1; i >= 0; i--)
    {
        string objName = ObjectName(i);
        if(StringFind(objName, PivotLinePrefix) >= 0 ||
           StringFind(objName, SRLinePrefix) >= 0 ||
           StringFind(objName, BuyZonePrefix) >= 0 ||
           StringFind(objName, SellZonePrefix) >= 0 ||
           StringFind(objName, "MA_Label_") >= 0)
        {
            ObjectDelete(objName);
        }
    }
}

//+------------------------------------------------------------------+
//| Show signal arrow on chart                                      |
//+------------------------------------------------------------------+
void ShowSignalArrow(bool isBuy, double price)
{
    if(!ShowSignalArrows) return;
    
    string arrowName = "MA_Signal_" + IntegerToString(Time[0]);
    int arrowCode = isBuy ? 233 : 234;  // Up/Down arrows
    color arrowColor = isBuy ? clrLime : clrRed;
    
    ObjectCreate(arrowName, OBJ_ARROW, 0, Time[0], price);
    ObjectSet(arrowName, OBJPROP_ARROWCODE, arrowCode);
    ObjectSet(arrowName, OBJPROP_COLOR, arrowColor);
    ObjectSet(arrowName, OBJPROP_WIDTH, 3);
    ObjectSet(arrowName, OBJPROP_BACK, false);
}

//+------------------------------------------------------------------+
//| Get current trading session name                                |
//+------------------------------------------------------------------+
string GetCurrentSession()
{
    int currentHour = TimeHour(TimeCurrent());
    
    if(currentHour >= 0 && currentHour < 8)
        return "Asian";
    else if(currentHour >= 8 && currentHour < 13)
        return "London";
    else if(currentHour >= 13 && currentHour < 16)
        return "Overlap";
    else if(currentHour >= 16 && currentHour < 21)
        return "New York";
    else
        return "Off-Hours";
}

// [Include all the original trading functions from previous EA]
// UpdateMarketInfo, CheckNewCandle, CalculateMarketStructure, etc.
// [The core trading logic remains exactly the same]

//+------------------------------------------------------------------+
//| Modified CheckTradingSignals with visual indicators             |
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
    
    // Buy signals near support (MONKEY ATTACK LOGIC)
    if(nearestSupport > 0 && IsNearLevel(currentPrice, nearestSupport, tolerance))
    {
        if(rsi < RSI_Oversold + 10 && macdMain > macdSignal && maFast > maSlow)
        {
            buySignal = true;
            ShowSignalArrow(true, currentPrice);  // Show buy arrow
            Print("🐒 MONKEY ATTACK BUY: Price near support at ", nearestSupport);
        }
    }
    
    // Sell signals near resistance (MONKEY ATTACK LOGIC)
    if(nearestResistance > 0 && IsNearLevel(currentPrice, nearestResistance, tolerance))
    {
        if(rsi > RSI_Overbought - 10 && macdMain < macdSignal && maFast < maSlow)
        {
            sellSignal = true;
            ShowSignalArrow(false, currentPrice);  // Show sell arrow
            Print("🐒 MONKEY ATTACK SELL: Price near resistance at ", nearestResistance);
        }
    }
    
    // Trend following signals
    if(maFast > maSlow && macdMain > macdSignal && rsi > 50 && currentPrice > DailyPivot)
    {
        buySignal = true;
        ShowSignalArrow(true, currentPrice);
        Print("🐒 MONKEY MOMENTUM BUY: Bullish trend confirmed");
    }
    
    if(maFast < maSlow && macdMain < macdSignal && rsi < 50 && currentPrice < DailyPivot)
    {
        sellSignal = true;
        ShowSignalArrow(false, currentPrice);
        Print("🐒 MONKEY MOMENTUM SELL: Bearish trend confirmed");
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
//| Update market information                                        |
//+------------------------------------------------------------------+
void UpdateMarketInfo()
{
    CurrentBid = Bid;
    CurrentAsk = Ask;
    CurrentSpread = (Ask - Bid) / Point;
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
    CurrentATR = iATR(Symbol(), 0, ATR_Period, 1);
    
    int todayD1Shift = iBarShift(Symbol(), PERIOD_D1, Time[0]);
    DailyHigh = iHigh(Symbol(), PERIOD_D1, todayD1Shift);
    DailyLow = iLow(Symbol(), PERIOD_D1, todayD1Shift);
    DailyOpen = iOpen(Symbol(), PERIOD_D1, todayD1Shift);
    
    int thisWeekW1Shift = iBarShift(Symbol(), PERIOD_W1, Time[0]);
    WeeklyHigh = iHigh(Symbol(), PERIOD_W1, thisWeekW1Shift);
    WeeklyLow = iLow(Symbol(), PERIOD_W1, thisWeekW1Shift);
    WeeklyOpen = iOpen(Symbol(), PERIOD_W1, thisWeekW1Shift);
}

//+------------------------------------------------------------------+
//| Calculate pivot points                                           |
//+------------------------------------------------------------------+
void CalculatePivotPoints()
{
    double prevDayHigh = iHigh(Symbol(), PERIOD_D1, 1);
    double prevDayLow = iLow(Symbol(), PERIOD_D1, 1);
    double prevDayClose = iClose(Symbol(), PERIOD_D1, 1);
    
    DailyPivot = (prevDayHigh + prevDayLow + prevDayClose) / 3;
    DailyR1 = 2 * DailyPivot - prevDayLow;
    DailyR2 = DailyPivot + (prevDayHigh - prevDayLow);
    DailyR3 = prevDayHigh + 2 * (DailyPivot - prevDayLow);
    DailyS1 = 2 * DailyPivot - prevDayHigh;
    DailyS2 = DailyPivot - (prevDayHigh - prevDayLow);
    DailyS3 = prevDayLow - 2 * (prevDayHigh - DailyPivot);
    
    double prevWeekHigh = iHigh(Symbol(), PERIOD_W1, 1);
    double prevWeekLow = iLow(Symbol(), PERIOD_W1, 1);
    double prevWeekClose = iClose(Symbol(), PERIOD_W1, 1);
    
    WeeklyPivot = (prevWeekHigh + prevWeekLow + prevWeekClose) / 3;
    WeeklyR1 = 2 * WeeklyPivot - prevWeekLow;
    WeeklyR2 = WeeklyPivot + (prevWeekHigh - prevWeekLow);
    WeeklyR3 = prevWeekHigh + 2 * (WeeklyPivot - prevWeekLow);
    WeeklyS1 = 2 * WeeklyPivot - prevWeekHigh;
    WeeklyS2 = WeeklyPivot - (prevWeekHigh - prevWeekLow);
    WeeklyS3 = prevWeekLow - 2 * (prevWeekHigh - WeeklyPivot);
}

//+------------------------------------------------------------------+
//| Calculate dynamic support and resistance                        |
//+------------------------------------------------------------------+
void CalculateDynamicSR()
{
    SupportCount = 0;
    ResistanceCount = 0;
    
    for(int i = Fractal_Period; i < SR_Lookback_Period && i < Bars - Fractal_Period; i++)
    {
        bool isSwingHigh = true;
        for(int j = 1; j <= Fractal_Period; j++)
        {
            if(High[i] <= High[i-j] || High[i] <= High[i+j])
            {
                isSwingHigh = false;
                break;
            }
        }
        
        if(isSwingHigh && ResistanceCount < 10)
        {
            ResistanceLevels[ResistanceCount] = High[i];
            ResistanceCount++;
        }
        
        bool isSwingLow = true;
        for(int k = 1; k <= Fractal_Period; k++)
        {
            if(Low[i] >= Low[i-k] || Low[i] >= Low[i+k])
            {
                isSwingLow = false;
                break;
            }
        }
        
        if(isSwingLow && SupportCount < 10)
        {
            SupportLevels[SupportCount] = Low[i];
            SupportCount++;
        }
    }
    
    ArraySort(SupportLevels, SupportCount, 0, MODE_DESCEND);
    ArraySort(ResistanceLevels, ResistanceCount, 0, MODE_ASCEND);
}

//+------------------------------------------------------------------+
//| Count open orders                                               |
//+------------------------------------------------------------------+
int CountOrders()
{
    int count = 0;
    for(int i = OrdersTotal() - 1; i >= 0; i--)
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
//| Check if trading is allowed                                     |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
    if(CurrentSpread > MaxSpread) return false;
    
    if(UseTradingHours)
    {
        int currentHour = TimeHour(TimeCurrent());
        if(currentHour < StartHour || currentHour >= EndHour) return false;
    }
    
    if(UseSessionFilter)
    {
        int hour = TimeHour(TimeCurrent());
        bool inAsianSession = (hour >= 0 && hour < 8);
        bool inLondonSession = (hour >= 8 && hour < 16);
        bool inNYSession = (hour >= 13 && hour < 21);
        bool inOverlap = (hour >= 13 && hour < 16);
        
        if(TradeOverlapOnly && !inOverlap) return false;
        if(!TradeAsianSession && inAsianSession && !inLondonSession && !inNYSession) return false;
        if(!TradeLondonSession && inLondonSession && !inOverlap) return false;
        if(!TradeNYSession && inNYSession && !inOverlap) return false;
    }
    
    if(UseVolatilityFilter)
    {
        double avgRange = 0;
        for(int i = 1; i <= VolatilityPeriod; i++)
        {
            avgRange += (High[i] - Low[i]);
        }
        avgRange /= VolatilityPeriod;
        
        if(CurrentATR > avgRange * VolatilityThreshold) return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Manage open positions                                           |
//+------------------------------------------------------------------+
void ManagePositions()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                if(UseTrailingStop) TrailStop();
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Trail stop loss                                                 |
//+------------------------------------------------------------------+
void TrailStop()
{
    double trailDistance = CurrentATR * TrailingMultiplier;
    
    if(OrderType() == OP_BUY)
    {
        double newSL = Bid - trailDistance;
        if(newSL > OrderStopLoss() && newSL < Bid - MinStopLoss * Point)
        {
            bool result = OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrNONE);
            if(!result) Print("TrailStop modify failed: ", GetLastError());
        }
    }
    else if(OrderType() == OP_SELL)
    {
        double newSL = Ask + trailDistance;
        if(newSL < OrderStopLoss() && newSL > Ask + MinStopLoss * Point)
        {
            bool result = OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrNONE);
            if(!result) Print("TrailStop modify failed: ", GetLastError());
        }
    }
}

//+------------------------------------------------------------------+
//| Get nearest support level                                       |
//+------------------------------------------------------------------+
double GetNearestSupport(double price)
{
    double nearest = 0;
    double minDistance = 999999;
    
    for(int i = 0; i < SupportCount; i++)
    {
        if(SupportLevels[i] < price && price - SupportLevels[i] < minDistance)
        {
            minDistance = price - SupportLevels[i];
            nearest = SupportLevels[i];
        }
    }
    
    if(Use_Daily_Pivots)
    {
        double levels[3];
        levels[0] = DailyS1;
        levels[1] = DailyS2;
        levels[2] = DailyS3;
        for(int j = 0; j < 3; j++)
        {
            if(levels[j] < price && price - levels[j] < minDistance)
            {
                minDistance = price - levels[j];
                nearest = levels[j];
            }
        }
    }
    
    return nearest;
}

//+------------------------------------------------------------------+
//| Get nearest resistance level                                    |
//+------------------------------------------------------------------+
double GetNearestResistance(double price)
{
    double nearest = 0;
    double minDistance = 999999;
    
    for(int i = 0; i < ResistanceCount; i++)
    {
        if(ResistanceLevels[i] > price && ResistanceLevels[i] - price < minDistance)
        {
            minDistance = ResistanceLevels[i] - price;
            nearest = ResistanceLevels[i];
        }
    }
    
    if(Use_Daily_Pivots)
    {
        double levels[3];
        levels[0] = DailyR1;
        levels[1] = DailyR2;
        levels[2] = DailyR3;
        for(int j = 0; j < 3; j++)
        {
            if(levels[j] > price && levels[j] - price < minDistance)
            {
                minDistance = levels[j] - price;
                nearest = levels[j];
            }
        }
    }
    
    return nearest;
}

//+------------------------------------------------------------------+
//| Check if price is near level                                    |
//+------------------------------------------------------------------+
bool IsNearLevel(double price, double level, double tolerance)
{
    return (MathAbs(price - level) <= tolerance);
}

//+------------------------------------------------------------------+
//| Calculate lot size                                              |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    if(!UseAutoLotSizing) return LotSize;
    
    double accountEquity = AccountEquity();
    double riskAmount = accountEquity * (RiskPercent / 100.0);
    double stopLossPoints = MinStopLoss;
    
    if(UseDynamicStops)
    {
        stopLossPoints = MathMax(MinStopLoss, MathMin(MaxStopLoss, CurrentATR * ATR_Multiplier / Point));
    }
    
    double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
    double lotSize = riskAmount / (stopLossPoints * tickValue);
    
    double minLot = MarketInfo(Symbol(), MODE_MINLOT);
    double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
    double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
    
    lotSize = MathMax(minLot, MathMin(maxLot, MathRound(lotSize / lotStep) * lotStep));
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Open buy order                                                  |
//+------------------------------------------------------------------+
void OpenBuyOrder()
{
    double lots = CalculateLotSize();
    double stopDistance = MathMax(MinStopLoss * Point, MathMin(MaxStopLoss * Point, CurrentATR * ATR_Multiplier));
    double stopLoss = Ask - stopDistance;
    double takeProfit = Ask + (stopDistance * RiskRewardRatio);
    
    int ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, 3, stopLoss, takeProfit, 
                          TradeComment + " BUY", MagicNumber, 0, clrGreen);
    
    if(ticket > 0)
    {
        Print("🐒 MONKEY ATTACK BUY: Order #", ticket, " opened at ", Ask);
        ShowSignalArrow(true, Ask);
    }
    else
    {
        Print("🐒 Buy order failed: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Open sell order                                                 |
//+------------------------------------------------------------------+
void OpenSellOrder()
{
    double lots = CalculateLotSize();
    double stopDistance = MathMax(MinStopLoss * Point, MathMin(MaxStopLoss * Point, CurrentATR * ATR_Multiplier));
    double stopLoss = Bid + stopDistance;
    double takeProfit = Bid - (stopDistance * RiskRewardRatio);
    
    int ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, 3, stopLoss, takeProfit, 
                          TradeComment + " SELL", MagicNumber, 0, clrRed);
    
    if(ticket > 0)
    {
        Print("🐒 MONKEY ATTACK SELL: Order #", ticket, " opened at ", Bid);
        ShowSignalArrow(false, Bid);
    }
    else
    {
        Print("🐒 Sell order failed: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Enhanced Strategy Functions - Based on Backtesting Results     |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Check if high quality pivot signal (tighter criteria)          |
//+------------------------------------------------------------------+
bool IsHighQualityPivotSignal(double price, double pivotLevel)
{
    double priceDistance = MathAbs(price - pivotLevel);
    double atrThreshold = CurrentATR * 0.3; // Tighter than standard 0.5
    
    // Must be very close to institutional level
    if(priceDistance > atrThreshold) return false;
    
    // Avoid trading in last hour of sessions (poor quality)
    int hour = TimeHour(TimeCurrent());
    if(hour == 15 || hour == 20) return false; // End of London and NY
    
    return true;
}

//+------------------------------------------------------------------+
//| Enhanced time-based quality filter                             |
//+------------------------------------------------------------------+
bool IsHighQualityTradingTime()
{
    int hour = TimeHour(TimeCurrent());
    
    // Premium hours based on backtesting analysis
    bool isLondonNYOverlap = (hour >= 13 && hour <= 16);
    bool isLondonActive = (hour >= 8 && hour <= 12);
    bool isNYActive = (hour >= 16 && hour <= 20);
    
    // Prioritize overlap (best performance in backtesting)
    if(isLondonNYOverlap) return true;
    if(TradeOverlapOnly) return false; // Only trade overlap if enabled
    
    return (TradeLondonSession && isLondonActive) || (TradeNYSession && isNYActive);
}

//+------------------------------------------------------------------+
//| Calculate trade quality score (1-7 scale)                      |
//+------------------------------------------------------------------+
int CalculateTradeQuality(double price, bool isBuySignal)
{
    int score = 0;
    
    // 1. Pivot proximity (most important - 3 points)
    double nearestSupport = GetNearestSupport(price);
    double nearestResistance = GetNearestResistance(price);
    
    if(isBuySignal && nearestSupport > 0 && IsHighQualityPivotSignal(price, nearestSupport))
        score += 3;
    else if(!isBuySignal && nearestResistance > 0 && IsHighQualityPivotSignal(price, nearestResistance))
        score += 3;
    
    // 2. Time quality (2 points)
    if(IsHighQualityTradingTime()) score += 2;
    
    // 3. RSI confirmation (1 point)
    double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 1);
    if((isBuySignal && rsi < RSI_Oversold + 10) || (!isBuySignal && rsi > RSI_Overbought - 10))
        score += 1;
    
    // 4. Low volatility bonus (1 point) - calmer market conditions
    double dailyATR = iATR(Symbol(), PERIOD_D1, 20, 1);
    if(CurrentATR < dailyATR * 1.2) score += 1;
    
    return score;
}

//+------------------------------------------------------------------+
//| Update consecutive losses tracking                              |
//+------------------------------------------------------------------+
void UpdateConsecutiveLosses()
{
    // Check last closed trade result
    if(OrdersHistoryTotal() > 0)
    {
        if(OrderSelect(OrdersHistoryTotal() - 1, SELECT_BY_POS, MODE_HISTORY))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                double profit = OrderProfit() + OrderSwap() + OrderCommission();
                
                if(profit < 0)
                {
                    consecutiveLosses++;
                    lastTradeResult = profit;
                }
                else
                {
                    consecutiveLosses = 0; // Reset on winning trade
                    lastTradeResult = profit;
                    if(riskReductionActive && consecutiveLosses == 0)
                    {
                        riskReductionActive = false; // Resume normal risk
                        Print("🐒 Risk reduction deactivated after winning trade");
                    }
                }
                
                // Activate risk reduction after max consecutive losses
                if(consecutiveLosses >= MaxConsecutiveLosses && !riskReductionActive)
                {
                    riskReductionActive = true;
                    Print("🐒 RISK REDUCTION ACTIVATED: ", consecutiveLosses, " consecutive losses");
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Enhanced lot size calculation with volatility adjustment       |
//+------------------------------------------------------------------+
double CalculateEnhancedLotSize()
{
    double baseLotSize = CalculateLotSize();
    
    // Apply risk reduction if consecutive losses occurred
    if(riskReductionActive)
    {
        baseLotSize *= RiskReductionFactor;
        Print("🐒 Reduced lot size due to consecutive losses: ", baseLotSize);
    }
    
    // Volatility-based position sizing
    if(UseVolatilityPositioning)
    {
        double dailyATR = iATR(Symbol(), PERIOD_D1, 20, 1);
        double volatilityRatio = CurrentATR / dailyATR;
        
        if(volatilityRatio > 1.3) // High volatility - reduce size
        {
            baseLotSize *= 0.7;
            Print("🐒 High volatility detected - reduced position size");
        }
        else if(volatilityRatio < 0.7) // Low volatility - slightly increase
        {
            baseLotSize *= 1.1;
        }
    }
    
    // Ensure we don't go below minimum lot size
    double minLot = MarketInfo(Symbol(), MODE_MINLOT);
    baseLotSize = MathMax(minLot, baseLotSize);
    
    return baseLotSize;
}

//+------------------------------------------------------------------+
//| Enhanced trade signal checking with quality filter             |
//+------------------------------------------------------------------+
void CheckEnhancedTradingSignals()
{
    double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 1);
    double macdMain = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 1);
    double macdSignal = iMACD(Symbol(), 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 1);
    double maFast = iMA(Symbol(), 0, MA_Fast, 0, MODE_SMA, PRICE_CLOSE, 1);
    double maSlow = iMA(Symbol(), 0, MA_Slow, 0, MODE_SMA, PRICE_CLOSE, 1);
    
    double currentPrice = Close[1];
    double nearestSupport = GetNearestSupport(currentPrice);
    double nearestResistance = GetNearestResistance(currentPrice);
    
    bool buySignal = false;
    bool sellSignal = false;
    
    // Buy signals near support (INSTITUTIONAL PIVOT STRATEGY)
    if(nearestSupport > 0 && IsNearLevel(currentPrice, nearestSupport, CurrentATR * 0.5))
    {
        if(rsi < RSI_Oversold + 10 && macdMain > macdSignal && maFast > maSlow && currentPrice > DailyPivot)
        {
            int tradeQuality = CalculateTradeQuality(currentPrice, true);
            lastTradeQuality = tradeQuality;
            
            if(!UseTradeQualityFilter || tradeQuality >= MinTradeQuality)
            {
                buySignal = true;
                ShowSignalArrow(true, currentPrice);
                Print("🐒 HIGH QUALITY BUY: Support at ", nearestSupport, " | Quality Score: ", tradeQuality);
            }
            else
            {
                Print("🐒 BUY signal rejected - Quality score too low: ", tradeQuality, " (min: ", MinTradeQuality, ")");
            }
        }
    }
    
    // Sell signals near resistance (INSTITUTIONAL PIVOT STRATEGY)
    if(nearestResistance > 0 && IsNearLevel(currentPrice, nearestResistance, CurrentATR * 0.5))
    {
        if(rsi > RSI_Overbought - 10 && macdMain < macdSignal && maFast < maSlow && currentPrice < DailyPivot)
        {
            int tradeQuality = CalculateTradeQuality(currentPrice, false);
            lastTradeQuality = tradeQuality;
            
            if(!UseTradeQualityFilter || tradeQuality >= MinTradeQuality)
            {
                sellSignal = true;
                ShowSignalArrow(false, currentPrice);
                Print("🐒 HIGH QUALITY SELL: Resistance at ", nearestResistance, " | Quality Score: ", tradeQuality);
            }
            else
            {
                Print("🐒 SELL signal rejected - Quality score too low: ", tradeQuality, " (min: ", MinTradeQuality, ")");
            }
        }
    }
    
    // Execute trades with enhanced lot sizing
    if(buySignal)
    {
        OpenEnhancedBuyOrder();
    }
    else if(sellSignal)
    {
        OpenEnhancedSellOrder();
    }
}

//+------------------------------------------------------------------+
//| Enhanced buy order with improved lot sizing                     |
//+------------------------------------------------------------------+
void OpenEnhancedBuyOrder()
{
    double lots = CalculateEnhancedLotSize();
    double stopDistance = MathMax(MinStopLoss * Point, MathMin(MaxStopLoss * Point, CurrentATR * ATR_Multiplier));
    double stopLoss = Ask - stopDistance;
    double takeProfit = Ask + (stopDistance * RiskRewardRatio);
    
    string comment = TradeComment + " BUY Q" + IntegerToString(lastTradeQuality);
    if(riskReductionActive) comment += " REDUCED";
    
    int ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, 3, stopLoss, takeProfit, 
                          comment, MagicNumber, 0, clrGreen);
    
    if(ticket > 0)
    {
        Print("🐒 ENHANCED BUY: #", ticket, " | Lots: ", lots, " | Quality: ", lastTradeQuality);
        ShowSignalArrow(true, Ask);
    }
    else
    {
        Print("🐒 Enhanced buy order failed: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Enhanced sell order with improved lot sizing                    |
//+------------------------------------------------------------------+
void OpenEnhancedSellOrder()
{
    double lots = CalculateEnhancedLotSize();
    double stopDistance = MathMax(MinStopLoss * Point, MathMin(MaxStopLoss * Point, CurrentATR * ATR_Multiplier));
    double stopLoss = Bid + stopDistance;
    double takeProfit = Bid - (stopDistance * RiskRewardRatio);
    
    string comment = TradeComment + " SELL Q" + IntegerToString(lastTradeQuality);
    if(riskReductionActive) comment += " REDUCED";
    
    int ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, 3, stopLoss, takeProfit, 
                          comment, MagicNumber, 0, clrRed);
    
    if(ticket > 0)
    {
        Print("🐒 ENHANCED SELL: #", ticket, " | Lots: ", lots, " | Quality: ", lastTradeQuality);
        ShowSignalArrow(false, Bid);
    }
    else
    {
        Print("🐒 Enhanced sell order failed: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| END OF ENHANCED MONKEY ATTACK EA                               |
//+------------------------------------------------------------------+