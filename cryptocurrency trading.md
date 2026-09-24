# Sentiment Analysis & Hybrid Technical Trading in Cryptocurrency (MATLAB)

An institutional-grade, production-ready MATLAB quantitative trading platform integrating NLP-based crypto sentiment scoring, technical analysis (RSI, MACD, Bollinger Bands), risk analytics (VaR 95%, CVaR, Calmar Ratio, Kelly Criterion), backtesting with 0.1% transaction fee modeling, and interactive visualization dashboards.

---

## 📁 Project Architecture & File Structure

| File | Description |
| :--- | :--- |
| **`main.m`** | Master execution script orchestrating the pipeline & comparing Pure Sentiment vs Hybrid Strategy side-by-side. |
| **`fetch_data.m`** | Data generator simulating BTC/USD OHLCV price series and correlated news/social headlines over 365 days. |
| **`analyze_sentiment.m`** | NLP engine executing tokenization, stop-words filtering, negation handling, and VADER sentiment scoring. |
| **`calculate_indicators.m`** | Technical analysis engine computing **RSI (14)**, **MACD (12, 26, 9)**, and **Bollinger Bands (20, 2.0)**. |
| **`generate_signals.m`** | Generates lag-adjusted Buy/Sell signals for both **Pure Sentiment** and **Hybrid Sentiment + Technical** strategies. |
| **`backtest_strategy.m`** | Quantitative engine modeling 0.1% transaction costs, equity growth, Sharpe Ratio, drawdown, and win rate. |
| **`calculate_advanced_metrics.m`** | Institutional risk engine computing **VaR 95%**, **CVaR 95%**, **Calmar Ratio**, **Alpha**, **Beta**, and **Kelly Criterion**. |
| **`plot_results.m`** | Visualization engine launching **3 rich interactive figures** (Signals, Technical Dashboard, Risk & Monthly Heatmap). |

---

## 🚀 Step-by-Step Instructions to Run `main.m`

### 1. Open MATLAB
Open your MATLAB desktop application (R2020a or newer).

### 2. Set Working Directory
In the MATLAB Command Window, navigate to your project directory:
```matlab
cd('c:\Users\YASH\OneDrive\Desktop\Crypto_Sentiment_Trading');
```

### 3. Execute Main Script
Type `main` and press **Enter**:
```matlab
main
```

---

## 📊 Outputs Produced

1. **CLI Quantitative Comparative Report**:
   - Compares **Pure Sentiment Strategy** vs **Hybrid Technical + Sentiment Strategy** vs **Buy & Hold BTC Benchmark**.
   - Displays Cumulative Return, Annualized Return, Volatility, Sharpe Ratio, Sortino Ratio, Calmar Ratio, Max Drawdown, Daily VaR 95%, Expected Shortfall (CVaR), Alpha, Beta, Kelly Allocation %, Win Rate %, and Profit Factor.

2. **3 Interactive Figure Dashboards**:
   - **Figure 1**: BTC/USD Price chart with Buy ($\mathbf{\hat{}}$) / Sell ($\mathbf{\check{}}$) execution markers + Sentiment index & thresholds.
   - **Figure 2**: Technical Indicators Dashboard (Bollinger Bands, RSI-14 overbought/oversold, MACD histogram).
   - **Figure 3**: Institutional Risk Analytics (Multi-Equity Growth Comparison, Underwater Drawdown, Daily Return Distribution with VaR 95% & CVaR markers, and Monthly Performance Heatmap Matrix).
