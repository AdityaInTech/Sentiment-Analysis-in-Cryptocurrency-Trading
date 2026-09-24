% function advMetrics = calculate_advanced_metrics(strategyReturns, benchmarkReturns, metricsBasic)
% % CALCULATE_ADVANCED_METRICS Computes institutional quantitative risk analytics.
% %
% % Syntax:
% %   advMetrics = calculate_advanced_metrics(strategyReturns, benchmarkReturns, metricsBasic)
% %
% % Inputs:
% %   strategyReturns  - Vector of 1-hour strategy returns
% %   benchmarkReturns - Vector of 1-hour benchmark returns
% %   metricsBasic     - Basic metrics struct output by backtest_strategy
% %
% % Outputs:
% %   advMetrics       - Struct augmented with risk analytics:
% %                      VaR95, VaR99, CVaR95, CalmarRatio, Beta, Alpha, KellyFraction, WinLossRatio
% %
% % Author: Senior Quantitative Trader & Financial Engineer
% % Project: Comprehensive Quantitative Crypto Trading System
% 
%     if nargin < 3
%         metricsBasic = struct();
%     end
% 
%     % 1. Historical Value at Risk (VaR)
%     sortedReturns = sort(strategyReturns);
%     n = length(sortedReturns);
% 
%     idx95 = max(1, floor(0.05 * n));
%     idx99 = max(1, floor(0.01 * n));
% 
%     var95_hourly = -sortedReturns(idx95) * 100;
%     var99_hourly = -sortedReturns(idx99) * 100;
% 
%     var95_hourly = max(0, var95_hourly);
%     var99_hourly = max(0, var99_hourly);
% 
%     % 2. Conditional Value at Risk (CVaR / Expected Shortfall)
%     cvar95_hourly = -mean(sortedReturns(1:idx95)) * 100;
%     cvar95_hourly = max(0, cvar95_hourly);
% 
%     % 3. Calmar Ratio (Annualized Return / Maximum Drawdown)
%     if isfield(metricsBasic, 'MaxDrawdown') && metricsBasic.MaxDrawdown > 0
%         calmarRatio = metricsBasic.AnnualizedReturnStrat / metricsBasic.MaxDrawdown;
%     else
%         calmarRatio = 0;
%     end
% 
%     % 4. Beta & Alpha against BTC Benchmark
%     covMat = cov(strategyReturns, benchmarkReturns);
%     benchVar = var(benchmarkReturns);
%     if benchVar > 0
%         beta = covMat(1, 2) / benchVar;
%     else
%         beta = 1.0;
%     end
% 
%     % Annualized Alpha (Jensen's Alpha)
%     if isfield(metricsBasic, 'AnnualizedReturnStrat') && isfield(metricsBasic, 'AnnualizedReturnBench')
%         alpha = metricsBasic.AnnualizedReturnStrat - (beta * metricsBasic.AnnualizedReturnBench);
%     else
%         alpha = 0;
%     end
% 
%     % 5. Half-Kelly Criterion Optimal Position Fraction
%     winTrades = strategyReturns(strategyReturns > 0);
%     lossTrades = strategyReturns(strategyReturns < 0);
% 
%     avgWin = mean(winTrades);
%     avgLoss = abs(mean(lossTrades));
% 
%     if isempty(avgWin);  avgWin = 0; end
%     if isempty(avgLoss); avgLoss = 1e-5; end
% 
%     winLossRatio = avgWin / max(avgLoss, 1e-5);
% 
%     if isfield(metricsBasic, 'WinRate')
%         p = metricsBasic.WinRate / 100; % Win probability
%         q = 1 - p;                       % Loss probability
%         if winLossRatio > 0
%             fullKelly = (p * winLossRatio - q) / winLossRatio;
%             halfKelly = 0.50 * fullKelly;
%             halfKellyFraction = max(0, min(1.0, halfKelly));
%         else
%             halfKellyFraction = 0;
%         end
%     else
%         halfKellyFraction = 0;
%     end
% 
%     % Package Struct
%     advMetrics = struct();
%     advMetrics.VaR95_Hourly    = var95_hourly;
%     advMetrics.VaR99_Hourly    = var99_hourly;
%     advMetrics.CVaR95_Hourly   = cvar95_hourly;
%     advMetrics.CalmarRatio     = calmarRatio;
%     advMetrics.Beta            = beta;
%     advMetrics.Alpha           = alpha;
%     advMetrics.WinLossRatio    = winLossRatio;
%     advMetrics.KellyFraction   = halfKellyFraction * 100; % Recommended Half-Kelly %
% 
%     fprintf('[INFO] Advanced risk analytics computed (Calmar: %.2f, Beta: %.2f, Half-Kelly: %.1f%%).\n', ...
%         calmarRatio, beta, advMetrics.KellyFraction);
% end


function metrics = calculate_advanced_metrics(results)
    % CALCULATE_ADVANCED_METRICS Calculates quantitative strategy risk and performance metrics
    %
    % Inputs:
    %   results - Table returned by backtest_strategy (or struct with strategy time-series)
    %
    % Outputs:
    %   metrics - Struct containing SharpeRatio, MaxDrawdown, TotalReturn, and WinRate

    % --- Flexible Data Extraction ---
    if istable(results)
        varNames = results.Properties.VariableNames;
        
        if ismember('StrategyReturns', varNames)
            stratReturns = double(results.StrategyReturns(:));
        else
            stratReturns = double(results{:, 1});
        end

        if ismember('StrategyEquity', varNames)
            equityCurve = double(results.StrategyEquity(:));
        else
            equityCurve = 10000 * cumprod(1 + stratReturns);
        end

        if ismember('Signals', varNames)
            signals = double(results.Signals(:));
        else
            signals = ones(size(stratReturns));
        end

    elseif isstruct(results)
        if isfield(results, 'StrategyReturns')
            stratReturns = double(results.StrategyReturns(:));
        else
            error('Results struct missing StrategyReturns field.');
        end

        if isfield(results, 'StrategyEquity')
            equityCurve = double(results.StrategyEquity(:));
        else
            equityCurve = 10000 * cumprod(1 + stratReturns);
        end

        if isfield(results, 'Signals')
            signals = double(results.Signals(:));
        else
            signals = ones(size(stratReturns));
        end

    else
        error('Input to calculate_advanced_metrics must be a table or struct returned by backtest_strategy.');
    end

    % Clean NaNs or Inf values if present
    stratReturns(isnan(stratReturns) | isinf(stratReturns)) = 0;
    equityCurve(isnan(equityCurve) | isinf(equityCurve))   = 10000;

    % 1. Annualized Sharpe Ratio (Hourly Data scaled by sqrt(8760))
    rfHourly = 0.02 / 8760; % 2% annual risk-free rate
    excessReturns = stratReturns - rfHourly;
    meanExcess    = mean(excessReturns);
    stdReturn     = std(stratReturns);

    if stdReturn == 0
        sharpe = 0;
    else
        sharpe = (meanExcess / stdReturn) * sqrt(8760);
    end

    % 2. Maximum Drawdown Calculation
    peakEquity     = cummax(equityCurve);
    drawdownSeries = (equityCurve - peakEquity) ./ peakEquity;
    maxDD          = abs(min(drawdownSeries));

    % 3. Total Return Calculation
    totalReturn = (equityCurve(end) - equityCurve(1)) / equityCurve(1);

    % 4. Strategy Win Rate (Filtered for active trade periods)
    activeTradeReturns = stratReturns(signals ~= 0);

    if isempty(activeTradeReturns)
        winRate = 0;
    else
        winRate = sum(activeTradeReturns > 0) / length(activeTradeReturns);
    end

    % Assign output struct fields
    metrics.SharpeRatio = sharpe;
    metrics.MaxDrawdown = maxDD;
    metrics.TotalReturn = totalReturn;
    metrics.WinRate     = winRate;
end