# EMA50/200 + RSI Trading Bot (MT4)

Expert Advisor based on **EMA 50/200 trend** confirmation combined with **RSI filtering**.  
It uses simple risk management (fixed lot, SL/TP), spread control, and an optional trading time window.

⚙️ **Project Status:**  
This EA is **still under improvement** — the main goal is to **enhance its profitability and overall performance**.  
After early backtests, results show a **Profit Factor close to 1**, meaning there is still **room for optimization** in trade exits and signal accuracy.


I’m **open to any suggestions** to help improve the **profitability and stability** of this strategy.  


## Example Backtest (XAUUSD – 15M)

| Metric | Result |
|---------|--------|
| Win Rate | 36–38 % |
| Max Drawdown | 131.16 (1.31%) |
| Total Trades | 894 |

> These results indicate consistent logic but suboptimal profitability.  


---

## Key Features
- Entry logic based on **EMA50/EMA200 trend + RSI confirmation**
- Optional **spread filter** and **trading time window**
- Simple fixed-lot **risk management** (configurable SL/TP)
- Supports **hedging mode** for flexible position management
- Integrated **grid trading logic** for progressive entries
- Clean and modular code structure — easy to extend or optimize

---

## Note
This strategy is designed to serve as a **foundation for testing and research**, not as a finalized profitable EA yet.  

