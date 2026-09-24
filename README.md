# Sentiment Analysis in Cryptocurrency Trading

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![MATLAB](https://img.shields.io/badge/MATLAB-R2023b%2B-orange.svg)](https://www.mathworks.com/products/matlab.html)
[![MathWorks Challenge](https://img.shields.io/badge/MathWorks%20Challenge-Project%20239-blue.svg)](https://github.com/mathworks/MathWorks-Excellence-in-Innovation)

An end-to-end quantitative trading framework developed in MATLAB that integrates **VADER Natural Language Processing (NLP) sentiment scoring** from social media feeds, **ARIMAX time-series econometrics**, and **portfolio backtesting** to optimize asset allocation across volatile cryptocurrency markets.

---

## 📌 Executive Summary & Motivation

With over 2,300 U.S. businesses accepting cryptocurrency as of recent estimates, digital assets present immense financial opportunities alongside significant market volatility. Unstructured external signals—such as social media posts, market news, and public sentiment—heavily drive price movements. 

This project addresses **MathWorks Excellence in Innovation Challenge #239** by developing a quantitative algorithmic strategy that:
1. Ingests high-frequency cryptocurrency OHLCV price data synchronized with social text feeds.
2. Quantifies public sentiment using **VADER NLP dictionary metrics** and **rolling 24-hour Z-score velocity indicators**.
3. Incorporates sentiment Z-scores as exogenous regressors ($X$) inside an **ARIMAX(1,0,1)** time-series model to forecast short-term returns.
4. Dynamically shifts capital allocations between Cash and Cryptocurrency to maximize returns while controlling downside drawdown risk.

---

## 👨‍💻 Team & Project Details

* **Project Number**: 239
* **Project Title**: Sentiment Analysis in Cryptocurrency Trading
* **Lead Student**: Aditya Parmale ([aditya.parmale@vit.edu.in](mailto:aditya.parmale@vit.edu.in))
* **Institution**: Vidyalankar Institute of Technology, Mumbai, India
* **Department**: Electronics and Computer Science
* **Degree Level**: Bachelor of Technology (B.Tech)
* **Academic Advisor**: Dr. Sheetal Patil
* **Team Size**: 3 Members

---

## 🏗️ Detailed Directory & File Structure

The repository is modularized into dedicated single-responsibility scripts and functions to ensure clear workflow separation, maintainability, and reproducibility.

```text
crypto-sentiment-trading-matlab/
├── LICENSE                         # MIT Open Source License
├── README.md                        # Comprehensive project documentation
├── main.m                          # Single entry point executing the full pipeline
├── fetch_data.m                    # Data Ingestion: Market OHLCV & Social Post Streams
├── calculate_indicators.m          # Feature Engineering: RSI, MACD, Simple Moving Averages
├── analyze_sentiment.m             # NLP Engine: VADER Scoring & Rolling Sentiment Z-Scores
├── fit_timeseries_model.m          # Econometric Modeling: ARIMAX(1,0,1) Return Forecaster
├── generate_signals.m              # Execution Logic: Multi-factor Buy/Sell Signal Generator
├── backtest_strategy.m             # Portfolio Engine: Equity Simulation vs Buy & Hold
├── calculate_advanced_metrics.m    # Quantitative Analytics: Sharpe, Sortino, Win Rate, Max DD
├── render_visualizations.m         # UI Analytics: Multi-pane Interactive Visual Dashboard
└── generate_trading_report.m       # Executive Reporting: Automated Text Summary Exporter ```

### Script & Function Module Descriptions

| File Name | Function Purpose & Description |
| :--- | :--- |
| **`main.m`** | **Primary Entry Point.** Orchestrates the end-to-end pipeline execution from user input prompting to report generation. |
| **`fetch_data.m`** | Generates/ingests high-frequency 1-year hourly OHLCV candle datasets alongside synchronized social feed volumes. |
| **`calculate_indicators.m`** | Computes technical momentum and volatility features, including Relative Strength Index (RSI), MACD, and Moving Averages. |
| **`analyze_sentiment.m`** | Evaluates text sentiment across posts using VADER lexicons and derives normalized 24-hour rolling sentiment Z-scores. |
| **`fit_timeseries_model.m`** | Establishes an ARIMAX(1,0,1) econometric model utilizing normalized sentiment Z-scores as exogenous variables. |
| **`generate_signals.m`** | Combines technical momentum, sentiment divergence, and return forecasts to produce actionable signals (`+1` BUY, `0` HOLD, `-1` SELL). |
| **`backtest_strategy.m`** | Simulates cash vs. crypto portfolio growth starting with $10,000 initial capital, incorporating trade tracking. |
| **`calculate_advanced_metrics.m`** | Calculates quantitative risk-adjusted performance statistics: Sharpe Ratio, Sortino Ratio, Maximum Drawdown, and Win Rate. |
| **`render_visualizations.m`** | Renders 3 standalone interactive dashboard figures: Price & Signals, Sentiment Z-Score, and Cumulative Equity Growth. |
| **`generate_trading_report.m`** | Generates an executive textual performance report printed to the console and saved to disk as `Trading_Report_<SYMBOL>.txt`. |

---

### 🛠️ Requirements & Toolboxes

Developed and verified using **MATLAB R2023b or later**. The project leverages the following MATLAB Toolboxes:

* **Statistics and Machine Learning Toolbox™**: Feature selection, classification algorithms, and normalization routines.
* **Econometrics Toolbox™**: ARIMAX estimation, volatility modeling, and time-series return forecasting.
* **Text Analytics Toolbox™**: VADER dictionary sentiment classification and text preprocessing pipelines.
* **Financial Toolbox™**: Portfolio backtesting metrics and equity growth modeling.
* **Datafeed Toolbox™** *(Optional)*: Direct API integration with social media streams and live exchange market feeds.

**🚀 Quick Start**
1. Clone the RepositoryBashgit clone [https://github.com/YOUR_GITHUB_USERNAME/crypto-sentiment-trading-matlab.git](https://github.com/YOUR_GITHUB_USERNAME/crypto-sentiment-trading-matlab.git)
cd crypto-sentiment-trading-matlab
2. Launch MATLAB & Run PipelineOpen MATLAB, set the current working folder to the repository path, and run main.m in the Command Window:Matlab>> main
3. User Input PromptWhen executed, the system prompts for the desired ticker symbol:PlaintextEnter Cryptocurrency or Stock Ticker (e.g., BTC, ETH, SOL, DOGE): BTC
🔄 End-to-End Execution WorkflowPlaintext  [1] DATA INGESTION
      ├── Historical Price Candles (OHLCV)
      └── Social Media Post Streams
               │
               ▼
  [2] FEATURE ENGINEERING & NLP
      ├── Technical Indicators (RSI, Moving Averages)
      └── VADER Sentiment Analysis (24-Hour Rolling Z-Score)
               │
               ▼
  [3] ECONOMETRIC FORECASTING
      └── ARIMAX Time-Series Model (Exogenous Sentiment Variable)
               │
               ▼
  [4] SIGNAL GENERATION & BACKTESTING
      ├── Execution Logic (BUY +1 / HOLD 0 / SELL -1)
      └── Dynamic Portfolio Allocation ($10,000 Base Capital)
               │
               ▼
  [5] DASHBOARD RENDERING & REPORT EXPORT
      ├── Interactive Visual Dashboard (3 Figures)
      └── Executive Report Output (.txt File)

📊 Sample Output & Executive Report FormatUpon pipeline completion, the automated engine generates visual plots and outputs an executive textual summary:Plaintext=======================================================
       QUANTITATIVE TRADING EXECUTIVE REPORT           
=======================================================
 Asset Symbol      : BTC
 Timestamp         : 2026-09-24 15:30:00
 Operational State : UNDERPERFORMING BENCHMARK
-------------------------------------------------------
 PERFORMANCE SUMMARY
-------------------------------------------------------
 Total Trades Executed : 142 trades
 Strategy Net Return   : 2.46%
 Benchmark Return      : 23.36%
 Alpha vs Benchmark    : -20.90%
 Maximum Drawdown      : 4.96%
-------------------------------------------------------
 FORWARD-LOOKING ASSESSMENT & RECOMMENDATIONS
-------------------------------------------------------
 The strategy currently trails buy-and-hold by 20.90%. 
 Consider tuning sentiment Z-score execution thresholds 
 or adding a trend filter (e.g., 200 SMA) to reduce 
 whipsaw trades during consolidated regimes.
=======================================================
[INFO] Dashboard visualizations rendered successfully for BTC.
[INFO] Report exported to: Trading_Report_BTC.txt
📜 References & Recommended ReadingMittal, Anshul. "Stock Prediction Using Twitter Sentiment Analysis." (2011).Şaşmaz, E., & Tek, F. B. "Tweet Sentiment Analysis for Cryptocurrencies," 2021 6th International Conference on Computer Science and Engineering (UBMK), 2021, pp. 613-618.Bollen, J., & Mao, H. "Twitter Mood as a Stock Market Predictor," Computer, vol. 44, no. 10, pp. 91-94, 2011.📄 LicenseThis project is licensed under the MIT License — see the LICENSE file for complete details.
