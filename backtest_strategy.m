% function [metrics, backtestTable] = backtest_strategy(cryptoData, signalsData, techTable, transactionFee, initialCapital, stopLossPct, takeProfitPct)
% % BACKTEST_STRATEGY Sequential Simulator with Dynamic Sizing, Friction, SL/TP & Trailing Risk Controls.
% %
% % Syntax:
% %   [metrics, backtestTable] = backtest_strategy(cryptoData, signalsData)
% %   [metrics, backtestTable] = backtest_strategy(cryptoData, signalsData, techTable, transactionFee, initialCapital, stopLossPct, takeProfitPct)
% %
% % Inputs:
% %   cryptoData     - MATLAB table with Close, Volume, Timestamp, etc.
% %   signalsData    - MATLAB table with ExecutedPosition or ExecutedPositionHybrid
% %   techTable      - MATLAB table with RealizedVol24h (from calculate_indicators)
% %   transactionFee - Exchange taker fee rate (default: 0.0008 = 0.08%)
% %   initialCapital - Portfolio starting equity in USD (default: 100,000)
% %   stopLossPct    - Fixed Stop-Loss percentage (default: 0.03 = 3%)
% %   takeProfitPct  - Fixed Take-Profit percentage (default: 0.06 = 6%)
% %
% % Outputs:
% %   metrics       - Struct containing quantitative summary analytics
% %   backtestTable - MATLAB table containing detailed hourly time series
% %
% % Author: Senior Quantitative Trader & Financial Engineer
% % Project: Comprehensive Quantitative Crypto Trading System
% 
%     if nargin < 3; techTable = []; end
%     if nargin < 4 || isempty(transactionFee); transactionFee = 0.0008; end % 0.08% taker fee
%     if nargin < 5 || isempty(initialCapital); initialCapital = 100000; end
%     if nargin < 6 || isempty(stopLossPct);    stopLossPct    = 0.03;   end % 3% Stop-Loss
%     if nargin < 7 || isempty(takeProfitPct);  takeProfitPct  = 0.06;   end % 6% Take-Profit
% 
%     closePrices = cryptoData.Close;
%     marketVol   = cryptoData.Volume;
%     numPeriods  = length(closePrices);
% 
%     if istable(signalsData)
%         if ismember('ExecutedPositionHybrid', signalsData.Properties.VariableNames)
%             targetPos = signalsData.ExecutedPositionHybrid;
%         elseif ismember('ExecutedPosition', signalsData.Properties.VariableNames)
%             targetPos = signalsData.ExecutedPosition;
%         else
%             targetPos = signalsData.ExecutedPositionPure;
%         end
%     else
%         targetPos = signalsData;
%     end
% 
%     if ~isempty(techTable) && istable(techTable) && ismember('RealizedVol24h', techTable.Properties.VariableNames)
%         realizedVol = techTable.RealizedVol24h;
%     else
%         logRet = [0; diff(log(closePrices))];
%         realizedVol = movstd(logRet, [23 0]) * sqrt(8760);
%     end
% 
%     % 1. Dynamic Position Sizing (Half-Kelly + Volatility Targeting)
%     targetVol = 0.25; % 25% target annual volatility
%     halfKellyFactor = 0.50; % Half-Kelly scaling multiplier
% 
%     volTargetWeight = targetVol ./ max(realizedVol, 0.10);
%     volTargetWeight = max(0.2, min(1.0, volTargetWeight)); % Clamp weight to [0.2, 1.0]
% 
%     % Allocated position weight array
%     weightAlloc = targetPos .* (halfKellyFactor * volTargetWeight);
% 
%     % 2. Sequential Step-by-Step Backtest Engine
%     portfolioEquity = zeros(numPeriods, 1);
%     portfolioEquity(1) = initialCapital;
% 
%     actualPosition = zeros(numPeriods, 1);
%     tradeCosts     = zeros(numPeriods, 1);
%     slippageCosts  = zeros(numPeriods, 1);
%     strategyReturn = zeros(numPeriods, 1);
% 
%     exitEvents     = zeros(numPeriods, 1); % 0: None, 1: Signal Exit, 2: Stop Loss, 3: Take Profit, 4: Trailing DD
% 
%     entryPrice     = 0;
%     currentPos     = 0;
%     peakEquity     = initialCapital;
%     trailingDDLimit = 0.12; % 12% max trailing portfolio drawdown kill switch
% 
%     slippageGamma  = 0.05; % Quadratic volume slippage coefficient
% 
%     for t = 2:numPeriods
%         priceNow  = closePrices(t);
%         pricePrev = closePrices(t-1);
%         hourlyAssetReturn = (priceNow - pricePrev) / pricePrev;
% 
%         % Evaluate Stop-Loss & Take-Profit on existing active open position
%         slTriggered = false;
%         tpTriggered = false;
%         tddTriggered = false;
% 
%         if currentPos > 0 && entryPrice > 0
%             unrealizedPnl = (priceNow - entryPrice) / entryPrice;
%             if unrealizedPnl <= -stopLossPct
%                 slTriggered = true;
%             elseif unrealizedPnl >= takeProfitPct
%                 tpTriggered = true;
%             end
%         elseif currentPos < 0 && entryPrice > 0
%             unrealizedPnl = (entryPrice - priceNow) / entryPrice;
%             if unrealizedPnl <= -stopLossPct
%                 slTriggered = true;
%             elseif unrealizedPnl >= takeProfitPct
%                 tpTriggered = true;
%             end
%         end
% 
%         % Evaluate Trailing Portfolio Drawdown Kill Switch
%         currentDrawdown = (peakEquity - portfolioEquity(t-1)) / peakEquity;
%         if currentDrawdown > trailingDDLimit
%             tddTriggered = true;
%         end
% 
%         % Determine target position for current period
%         if slTriggered || tpTriggered || tddTriggered
%             desiredPos = 0; % Forced exit
%             if slTriggered; exitEvents(t) = 2; end
%             if tpTriggered; exitEvents(t) = 3; end
%             if tddTriggered; exitEvents(t) = 4; end
%         else
%             desiredPos = weightAlloc(t);
%         end
% 
%         % Compute position change (turnover)
%         posChange = desiredPos - currentPos;
% 
%         % Calculate friction: Taker Fee (0.08%) + Quadratic Slippage
%         if abs(posChange) > 1e-4
%             tradeVal = abs(posChange) * portfolioEquity(t-1);
%             mktVal   = max(marketVol(t) * priceNow, 1e6);
%             volParticipation = tradeVal / mktVal;
% 
%             % Slippage = gamma * (TradeVal / MktVal)^2
%             quadSlippage = slippageGamma * (volParticipation^2);
% 
%             feeCost = abs(posChange) * transactionFee;
%             slipCost = abs(posChange) * quadSlippage;
% 
%             % Update entry price on new trade open
%             if sign(desiredPos) ~= sign(currentPos) && desiredPos ~= 0
%                 entryPrice = priceNow;
%             end
%         else
%             feeCost  = 0;
%             slipCost = 0;
%         end
% 
%         tradeCosts(t)    = feeCost;
%         slippageCosts(t) = slipCost;
% 
%         % Period Strategy Return: (Position * AssetReturn) - Fees - Slippage
%         netReturn = (currentPos * hourlyAssetReturn) - feeCost - slipCost;
%         strategyReturn(t) = netReturn;
% 
%         % Update Portfolio Equity
%         portfolioEquity(t) = portfolioEquity(t-1) * (1 + netReturn);
% 
%         % Update Peak Equity for Trailing DD
%         if portfolioEquity(t) > peakEquity
%             peakEquity = portfolioEquity(t);
%         end
% 
%         currentPos = desiredPos;
%         actualPosition(t) = currentPos;
%     end
% 
%     % Benchmark Equity (Buy & Hold BTC)
%     benchmarkEquity = initialCapital * (closePrices ./ closePrices(1));
%     assetReturns = [0; diff(closePrices) ./ closePrices(1:end-1)];
% 
%     % Drawdown profile
%     runningPeak = cummax(portfolioEquity);
%     drawdown = (runningPeak - portfolioEquity) ./ runningPeak;
%     maxDrawdown = max(drawdown);
% 
%     % Calculate Drawdown Duration
%     drawdownHours = 0;
%     maxDrawdownDuration = 0;
%     for t = 1:numPeriods
%         if drawdown(t) > 0
%             drawdownHours = drawdownHours + 1;
%             maxDrawdownDuration = max(maxDrawdownDuration, drawdownHours);
%         else
%             drawdownHours = 0;
%         end
%     end
% 
%     % Performance Summary Metrics
%     totalReturnStrat = (portfolioEquity(end) - initialCapital) / initialCapital;
%     totalReturnBench = (benchmarkEquity(end) - initialCapital) / initialCapital;
% 
%     annualFactor = 8760; % 8,760 hours per year
%     numYears = numPeriods / annualFactor;
% 
%     annReturnStrat = (1 + totalReturnStrat)^(1 / max(numYears, 0.01)) - 1;
%     annReturnBench = (1 + totalReturnBench)^(1 / max(numYears, 0.01)) - 1;
% 
%     hourlyVolStrat = std(strategyReturn);
%     annVolStrat   = hourlyVolStrat * sqrt(annualFactor);
% 
%     % Sharpe Ratio
%     meanHourlyExcess = mean(strategyReturn);
%     if hourlyVolStrat > 0
%         sharpeRatio = (meanHourlyExcess / hourlyVolStrat) * sqrt(annualFactor);
%     else
%         sharpeRatio = 0;
%     end
% 
%     % Sortino Ratio
%     downsideReturns = strategyReturn(strategyReturn < 0);
%     downsideVol = std(downsideReturns);
%     if downsideVol > 0
%         sortinoRatio = (meanHourlyExcess / downsideVol) * sqrt(annualFactor);
%     else
%         sortinoRatio = 0;
%     end
% 
%     % Trade Statistics
%     posChanges = [0; diff(actualPosition)];
%     totalTrades = sum(abs(posChanges) > 1e-4);
% 
%     tradeReturns = strategyReturn(actualPosition ~= 0);
%     winningTrades = sum(tradeReturns > 0);
%     losingTrades  = sum(tradeReturns < 0);
% 
%     if (winningTrades + losingTrades) > 0
%         winRate = winningTrades / (winningTrades + losingTrades);
%     else
%         winRate = 0;
%     end
% 
%     grossProfit = sum(strategyReturn(strategyReturn > 0));
%     grossLoss   = abs(sum(strategyReturn(strategyReturn < 0)));
%     if grossLoss > 0
%         profitFactor = grossProfit / grossLoss;
%     else
%         profitFactor = Inf;
%     end
% 
%     % Metrics Package
%     metrics = struct();
%     metrics.InitialCapital         = initialCapital;
%     metrics.FinalStrategyEquity    = portfolioEquity(end);
%     metrics.FinalBenchmarkEquity   = benchmarkEquity(end);
%     metrics.TotalReturnStrategy    = totalReturnStrat * 100;
%     metrics.TotalReturnBenchmark   = totalReturnBench * 100;
%     metrics.AnnualizedReturnStrat  = annReturnStrat * 100;
%     metrics.AnnualizedReturnBench  = annReturnBench * 100;
%     metrics.AnnualizedVolatility   = annVolStrat * 100;
%     metrics.SharpeRatio            = sharpeRatio;
%     metrics.SortinoRatio           = sortinoRatio;
%     metrics.MaxDrawdown            = maxDrawdown * 100;
%     metrics.MaxDrawdownDuration    = maxDrawdownDuration; % in hours
%     metrics.TotalTrades            = totalTrades;
%     metrics.WinRate                = winRate * 100;
%     metrics.ProfitFactor           = profitFactor;
%     metrics.TransactionFeePct      = transactionFee * 100;
%     metrics.StopLossPct            = stopLossPct * 100;
%     metrics.TakeProfitPct          = takeProfitPct * 100;
% 
%     % Output Table
%     backtestTable = cryptoData;
%     backtestTable.Position        = actualPosition;
%     backtestTable.AssetReturn     = assetReturns;
%     backtestTable.StrategyReturn  = strategyReturn;
%     backtestTable.StrategyEquity  = portfolioEquity;
%     backtestTable.BenchmarkEquity = benchmarkEquity;
%     backtestTable.Drawdown        = drawdown * 100;
%     backtestTable.ExitEvents      = exitEvents;
% 
%     fprintf('[INFO] Execution simulation complete: Net Return: %.2f%% vs BTC: %.2f%% (Sharpe: %.2f, MaxDD: %.2f%%).\n', ...
%         metrics.TotalReturnStrategy, metrics.TotalReturnBenchmark, metrics.SharpeRatio, metrics.MaxDrawdown);
% end


function results = backtest_strategy(marketData, signals, coinSymbol)
% BACKTEST_STRATEGY Evaluates strategy execution and outputs time-series backtest results table
%
% Syntax:
%   results = backtest_strategy(marketData, signals)
%   results = backtest_strategy(marketData, signals, coinSymbol)

if nargin < 3 || isempty(coinSymbol)
    coinSymbol = 'ASSET';
end

% Safely extract Close prices and Timestamps
if istable(marketData)
    prices = marketData.Close(:);
    if ismember('Timestamp', marketData.Properties.VariableNames)
        dates = marketData.Timestamp(:);
    elseif ismember('Date', marketData.Properties.VariableNames)
        dates = marketData.Date(:);
    else
        dates = (1:length(prices))';
    end
else
    prices = marketData(:);
    dates = (1:length(prices))';
end

numBars = length(prices);
signals = signals(:);

% Compute percentage asset returns
assetReturns = [0; diff(prices) ./ prices(1:end-1)];
assetReturns(isnan(assetReturns) | isinf(assetReturns)) = 0;

% Shift signals by 1 period to avoid look-ahead bias (execute on next candle)
executionSignals = [0; signals(1:end-1)];
strategyReturns = executionSignals .* assetReturns;

% Track equity growth starting at $10,000 base capital
initialCapital = 10000;
strategyEquity = initialCapital * cumprod(1 + strategyReturns);
benchmarkEquity = initialCapital * (prices ./ prices(1));

% Construct and return standard MATLAB table
results = table(dates, prices, signals, assetReturns, strategyReturns, ...
    strategyEquity, benchmarkEquity, ...
    'VariableNames', {'Timestamp', 'Price', 'Signals', 'AssetReturns', ...
    'StrategyReturns', 'StrategyEquity', 'BenchmarkEquity'});

netReturnPct = ((strategyEquity(end) - initialCapital) / initialCapital) * 100;
benchReturnPct = ((benchmarkEquity(end) - initialCapital) / initialCapital) * 100;

fprintf('[INFO] Backtest simulation complete for %s. Strategy Return: %.2f%% | Benchmark Return: %.2f%%\n', ...
    coinSymbol, netReturnPct, benchReturnPct);
end