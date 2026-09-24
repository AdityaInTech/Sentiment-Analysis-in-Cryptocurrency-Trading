% % MAIN.M - Master Execution Script for Production-Grade Quantitative Crypto Trading System
% %
% % Title: Production-Grade Quantitative Sentiment & Multi-Factor Crypto Trading System
% % Author: Senior Quantitative Trader & MATLAB Financial Engineer
% %
% % System Pipeline:
% %   1. Data Generation: 1-hour OHLCV BTC/USDT (GBM + GARCH(1,1) Volatility Jumps + Bot Spam) (`fetch_data.m`)
% %   2. NLP & Sentiment Engine: 24h Rolling Z-Score & Sentiment Velocity (`analyze_sentiment.m`)
% %   3. Technical Overlay: RSI-14, Bollinger Bands, Percent B & 24h Realized Volatility (`calculate_indicators.m`)
% %   4. Alpha Engine: Multi-Factor Composite Alpha Score with strict t-1 lag shift (`generate_signals.m`)
% %   5. Risk & Execution Simulator: Half-Kelly & Vol Sizing, 0.08% fee + Quadratic Slippage, 3% SL / 6% TP / Trailing DD (`backtest_strategy.m`)
% %   6. Advanced Risk Analytics: VaR 95%, CVaR, Calmar, Half-Kelly, Beta, Jensen's Alpha (`calculate_advanced_metrics.m`)
% %   7. Institutional CLI Terminal Summary Report
% %   8. Bloomberg-Style Dark Dashboard (#0F1117 background, 4-panel layout, HUD overlay) (`plot_results.m`)
% 
% clc;
% clear;
% close all;
% 
% % Set random seed for exact mathematical reproducibility
% rng(42);
% 
% fprintf('==================================================================================\n');
% fprintf('  PRODUCTION-GRADE QUANTITATIVE CRYPTO SENTIMENT & MULTI-FACTOR SYSTEM\n');
% fprintf('==================================================================================\n\n');
% 
% %% STEP 1: PARAMETER CONFIGURATION
% numDays          = 365;       % Simulation period (1 year = 8,760 hourly candles)
% initialPrice     = 40000;     % Starting BTC/USDT price ($)
% smaPeriod        = 7;         % Sentiment moving average smoothing window (hours)
% buyThreshold     = 0.25;      % Alpha threshold to open LONG (+0.25)
% sellThreshold    = -0.25;     % Alpha threshold to open EXIT/SHORT (-0.25)
% transactionFee   = 0.0008;    % Taker exchange fee (0.08% per trade)
% initialCapital   = 100000;    % Initial investment capital ($100,000 USD)
% stopLossPct      = 0.03;      % Fixed 3% Stop-Loss
% takeProfitPct    = 0.06;      % Fixed 6% Take-Profit
% 
% %% STEP 2: HIGH-FREQUENCY DATA GENERATION (GBM + GARCH(1,1) JUMPS)
% fprintf('[STEP 1/7] Generating 1-hour BTC/USDT market data & sentiment series (GBM + GARCH)...\n');
% cryptoData = fetch_data(numDays, initialPrice);
% 
% %% STEP 3: NLP SENTIMENT ENGINE (ROLLING Z-SCORE & VELOCITY)
% fprintf('\n[STEP 2/7] Computing 24-hour Rolling Sentiment Z-Score & Sentiment Velocity...\n');
% [sentimentResults, cryptoDataUpdated] = analyze_sentiment(cryptoData, 24);
% 
% %% STEP 4: TECHNICAL INDICATORS & REALIZED VOLATILITY
% fprintf('\n[STEP 3/7] Calculating Technical Overlay (RSI-14, Bollinger Bands, 24h Realized Vol)...\n');
% techTable = calculate_indicators(cryptoDataUpdated, 14, 12, 26, 9, 20, 2.0, 24);
% 
% %% STEP 5: MULTI-FACTOR COMPOSITE ALPHA ENGINE (STRICT t-1 LAG SHIFT)
% fprintf('\n[STEP 4/7] Constructing Composite Alpha Score & shifting signals by t-1...\n');
% signalsData = generate_signals(cryptoDataUpdated, smaPeriod, buyThreshold, sellThreshold, techTable);
% 
% %% STEP 6: EXECUTION & RISK SIMULATOR (HALF-KELLY, SLIPPAGE, SL/TP)
% fprintf('\n[STEP 5/7] Simulating execution with Half-Kelly sizing, friction & hard SL/TP controls...\n');
% 
% % Backtest Pure Sentiment Strategy
% [metricsPure, backtestTablePure] = backtest_strategy(cryptoDataUpdated, ...
%     table(signalsData.ExecutedPositionPure, 'VariableNames', {'ExecutedPosition'}), ...
%     techTable, transactionFee, initialCapital, stopLossPct, takeProfitPct);
% 
% % Backtest Hybrid Multi-Factor Strategy
% [metricsHybrid, backtestTableHybrid] = backtest_strategy(cryptoDataUpdated, ...
%     table(signalsData.ExecutedPositionHybrid, 'VariableNames', {'ExecutedPosition'}), ...
%     techTable, transactionFee, initialCapital, stopLossPct, takeProfitPct);
% 
% %% STEP 7: ADVANCED RISK ANALYTICS (VaR, CVaR, CALMAR, KELLY, ALPHA, BETA)
% fprintf('\n[STEP 6/7] Computing institutional risk analytics (VaR 95%%, CVaR, Calmar, Half-Kelly)...\n');
% advMetricsPure   = calculate_advanced_metrics(backtestTablePure.StrategyReturn, backtestTablePure.AssetReturn, metricsPure);
% advMetricsHybrid = calculate_advanced_metrics(backtestTableHybrid.StrategyReturn, backtestTableHybrid.AssetReturn, metricsHybrid);
% 
% %% STEP 8: INSTITUTIONAL COMPARATIVE CLI REPORT
% fprintf('\n==================================================================================\n');
% fprintf('                   INSTITUTIONAL QUANTITATIVE COMPARATIVE REPORT                  \n');
% fprintf('==================================================================================\n');
% fprintf('  Metric / Benchmark                | Pure Sentiment   | Multi-Factor Hybrid| Buy & Hold BTC\n');
% fprintf('------------------------------------+------------------+-------------------+------------------\n');
% fprintf('  Initial Investment Capital ($)    | $ %14.2f | $ %15.2f | $ %14.2f\n', ...
%     initialCapital, initialCapital, initialCapital);
% fprintf('  Final Portfolio Value ($)         | $ %14.2f | $ %15.2f | $ %14.2f\n', ...
%     metricsPure.FinalStrategyEquity, metricsHybrid.FinalStrategyEquity, metricsPure.FinalBenchmarkEquity);
% fprintf('  Cumulative Total Return (%%)      | %15.2f %% | %16.2f %% | %15.2f %%\n', ...
%     metricsPure.TotalReturnStrategy, metricsHybrid.TotalReturnStrategy, metricsPure.TotalReturnBenchmark);
% fprintf('  Annualized Return (%%)             | %15.2f %% | %16.2f %% | %15.2f %%\n', ...
%     metricsPure.AnnualizedReturnStrat, metricsHybrid.AnnualizedReturnStrat, metricsPure.AnnualizedReturnBench);
% fprintf('  Annualized Volatility (%%)         | %15.2f %% | %16.2f %% |           N/A   \n', ...
%     metricsPure.AnnualizedVolatility, metricsHybrid.AnnualizedVolatility);
% fprintf('------------------------------------+------------------+-------------------+------------------\n');
% fprintf('  Sharpe Ratio (Annualized)         | %16.2f | %17.2f |           N/A   \n', ...
%     metricsPure.SharpeRatio, metricsHybrid.SharpeRatio);
% fprintf('  Sortino Ratio (Downside Risk)     | %16.2f | %17.2f |           N/A   \n', ...
%     metricsPure.SortinoRatio, metricsHybrid.SortinoRatio);
% fprintf('  Calmar Ratio (Ret / MaxDD)        | %16.2f | %17.2f |           N/A   \n', ...
%     advMetricsPure.CalmarRatio, advMetricsHybrid.CalmarRatio);
% fprintf('  Maximum Drawdown (%%)             | %15.2f %% | %16.2f %% |           N/A   \n', ...
%     metricsPure.MaxDrawdown, metricsHybrid.MaxDrawdown);
% fprintf('------------------------------------+------------------+-------------------+------------------\n');
% fprintf('  Hourly Value at Risk 95%% (VaR)    | %15.2f %% | %16.2f %% |           N/A   \n', ...
%     advMetricsPure.VaR95_Hourly, advMetricsHybrid.VaR95_Hourly);
% fprintf('  Expected Shortfall 95%% (CVaR)    | %15.2f %% | %16.2f %% |           N/A   \n', ...
%     advMetricsPure.CVaR95_Hourly, advMetricsHybrid.CVaR95_Hourly);
% fprintf('  Strategy Beta to BTC              | %16.2f | %17.2f |          1.00   \n', ...
%     advMetricsPure.Beta, advMetricsHybrid.Beta);
% fprintf('  Annualized Jensen Alpha (%%)       | %15.2f %% | %16.2f %% |          0.00 %%\n', ...
%     advMetricsPure.Alpha, advMetricsHybrid.Alpha);
% fprintf('  Half-Kelly Position Allocation    | %15.1f %% | %16.1f %% |           N/A   \n', ...
%     advMetricsPure.KellyFraction, advMetricsHybrid.KellyFraction);
% fprintf('------------------------------------+------------------+-------------------+------------------\n');
% fprintf('  Total Trades Executed             | %16d | %17d |             1   \n', ...
%     metricsPure.TotalTrades, metricsHybrid.TotalTrades);
% fprintf('  Trade Win Rate (%%)               | %15.2f %% | %16.2f %% |           N/A   \n', ...
%     metricsPure.WinRate, metricsHybrid.WinRate);
% fprintf('  Profit Factor (Gross Gain/Loss)   | %16.2f | %17.2f |           N/A   \n', ...
%     metricsPure.ProfitFactor, metricsHybrid.ProfitFactor);
% fprintf('==================================================================================\n\n');
% 
% %% STEP 9: BLOOMBERG-STYLE DARK DASHBOARD VISUALIZATION
% fprintf('[STEP 7/7] Launching Bloomberg Dark Dashboard (#0F1117)...\n');
% plot_results(backtestTableHybrid, signalsData, metricsHybrid, techTable, advMetricsHybrid);
% 
% fprintf('\n[SUCCESS] Production-Grade Quantitative System executed cleanly!\n');

%% Main Script: Dynamic Cryptocurrency Sentiment-Based Trading Pipeline
%
% Project: Dynamic Quantitative Crypto Trading & Sentiment System
%
% Workflow:
%   1. User Input & Parameter Initialization
%   2. Ingest Market Price & Social Post Feeds (GBM + GARCH Jumps)
%   3. Compute Technical Indicators & VADER Sentiment Analysis
%   4. Econometric Forecasting via ARIMAX/ARX Sentiment Regressor
%   5. Execution Signal Logic & Strategy Backtesting
%   6. Risk & Advanced Performance Metrics Evaluation
%   7. Render Dashboard Visualizations & Export Executive Summary Report

clc; clear; close all;

% =========================================================================
% 1. USER INPUT & CONFIGURATION
% =========================================================================
coinSymbol = upper(input('Enter Cryptocurrency or Stock Ticker (e.g., BTC, ETH, SOL, DOGE): ', 's'));
if isempty(coinSymbol)
    coinSymbol = 'BTC'; % Default fallback
    disp('No symbol entered. Defaulting to BTC.');
end

fprintf('\n=======================================================\n');
fprintf('  STARTING QUANTITATIVE ANALYSIS FOR: %s\n', coinSymbol);
fprintf('=======================================================\n\n');

% Simulation Parameters
numDays = 365;       % 1 Year of hourly data (8,760 candles)
initialPrice = [];   % Dynamically seeded inside fetch_data based on symbol

% =========================================================================
% 2. DYNAMIC DATA FETCHING
% =========================================================================
fprintf('[1/5] Ingesting market price and social post feeds for %s...\n', coinSymbol);
marketData = fetch_data(numDays, initialPrice, coinSymbol);

% =========================================================================
% 3. TECHNICAL INDICATORS & NLP SENTIMENT ANALYSIS
% =========================================================================
fprintf('[2/5] Extracting technical indicators and running VADER NLP sentiment scoring...\n');
indicators = calculate_indicators(marketData);

% Check if analyze_sentiment accepts coinSymbol parameter
try
    sentimentScores = analyze_sentiment(marketData, 24, coinSymbol);
catch
    sentimentScores = analyze_sentiment(marketData);
end

% =========================================================================
% 4. ECONOMETRIC FORECASTING (ARIMAX MODEL)
% =========================================================================
fprintf('[3/5] Fitting ARIMAX time-series model with sentiment regressors...\n');
forecastedReturns = fit_timeseries_model(marketData, sentimentScores);

% =========================================================================
% 5. SIGNAL GENERATION & STRATEGY BACKTESTING
% =========================================================================
fprintf('[4/5] Executing signal logic and strategy backtest...\n');
signals = generate_signals(indicators, sentimentScores, forecastedReturns);

% Execute Backtest with Ticker Symbol Tracking
try
    results = backtest_strategy(marketData, signals, coinSymbol);
catch
    results = backtest_strategy(marketData, signals);
end

% Calculate Risk & Performance Metrics
metrics = calculate_advanced_metrics(results);

% =========================================================================
% 6. VISUALIZATION DASHBOARD & EXECUTIVE REPORT
% =========================================================================
fprintf('[5/5] Generating dashboard plots & summary report...\n');

% Render Interactive Quantitative Dashboard Figures
render_visualizations(marketData, sentimentScores, results, coinSymbol);

% Generate & Export Executive Summary Report
if exist('generate_trading_report.m', 'file')
    generate_trading_report(marketData, sentimentScores, results, coinSymbol);
end

% =========================================================================
% 7. CONSOLE SUMMARY PRINTOUT
% =========================================================================
latestSignal = signals(end);

fprintf('\n=======================================================\n');
fprintf('  FINAL TRADING SUMMARY FOR %s:\n', coinSymbol);
fprintf('=======================================================\n');
if latestSignal == 1
    fprintf('  RECOMMENDATION       : BUY / LONG (Bullish Sentiment Divergence)\n');
elseif latestSignal == -1
    fprintf('  RECOMMENDATION       : SELL / SHORT (Bearish Sentiment Spike)\n');
else
    fprintf('  RECOMMENDATION       : HOLD (Neutral Market Conditions)\n');
end

fprintf('  Strategy Net Return  : %.2f%%\n', metrics.TotalReturn * 100);
fprintf('  Strategy Sharpe Ratio: %.2f\n', metrics.SharpeRatio);
fprintf('  Strategy Max Drawdown: %.2f%%\n', metrics.MaxDrawdown * 100);
fprintf('  Strategy Win Rate    : %.2f%%\n', metrics.WinRate * 100);
fprintf('=======================================================\n');