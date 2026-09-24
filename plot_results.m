function plot_results(backtestTable, signalsData, metrics, techTable, advMetrics)
% PLOT_RESULTS Premium Bloomberg-Style Dark-Themed Quantitative Dashboard (#0F1117).
%
% Syntax:
%   plot_results(backtestTable, signalsData, metrics)
%   plot_results(backtestTable, signalsData, metrics, techTable, advMetrics)
%
% Visual Dashboards Produced:
%   4-Panel Visual Dashboard using tiledlayout(4,1):
%   - Panel 1: Price Action with Buy/Sell execution scatter markers & Bollinger Bands.
%   - Panel 2: Sentiment Velocity and Z-Score with Overbought/Oversold thresholds.
%   - Panel 3: Strategy Cumulative PnL vs. Benchmark (Buy & Hold) with Fill Area.
%   - Panel 4: Underwater Plot (Drawdown profile over time).
%   - Integrated HUD/Text Box overlay showing key performance metrics.
%
% Author: Senior Quantitative Trader & Financial Engineer
% Project: Comprehensive Quantitative Crypto Trading System

    if nargin < 4; techTable = []; end
    if nargin < 5; advMetrics = []; end

    timeVec     = backtestTable.Timestamp;
    closePrice  = backtestTable.Close;
    stratEquity = backtestTable.StrategyEquity;
    benchEquity = backtestTable.BenchmarkEquity;
    drawdownVec = backtestTable.Drawdown;
    positions   = backtestTable.Position;
    
    if ismember('ExitEvents', backtestTable.Properties.VariableNames)
        exitEvents = backtestTable.ExitEvents;
    else
        exitEvents = zeros(length(positions), 1);
    end

    if ismember('SentimentZScore', signalsData.Properties.VariableNames)
        sentZ = signalsData.SentimentZScore;
    else
        sentZ = zeros(length(closePrice), 1);
    end
    
    if ismember('SentimentVelocity', signalsData.Properties.VariableNames)
        sentVel = signalsData.SentimentVelocity;
    else
        sentVel = zeros(length(closePrice), 1);
    end

    % Execution Signal Indices
    buyIdx  = find(positions > 0 & [0; positions(1:end-1)] <= 0);
    sellIdx = find(positions < 0 & [0; positions(1:end-1)] >= 0);
    slIdx   = find(exitEvents == 2);
    tpIdx   = find(exitEvents == 3);

    % Color Palette Definitions
    bgDark   = '#0F1117';
    axDark   = '#161922';
    gridDark = '#2B2D42';
    cGreen   = '#00E676';
    cRed     = '#FF1744';
    cGold    = '#FFD600';
    cCyan    = '#00E5FF';
    cWhite   = '#E0E6ED';

    cGreenRGB = [0/255, 230/255, 118/255];
    cRedRGB   = [255/255, 23/255, 68/255];
    cGoldRGB  = [255/255, 214/255, 0/255];
    cCyanRGB  = [0/255, 229/255, 255/255];
    cBenchRGB = [120/255, 125/255, 145/255];

    % Set figure and graphics defaults
    fig = figure('Name', 'Bloomberg Quantitative Crypto Trading System Dashboard', ...
           'Color', bgDark, 'Position', [80, 50, 1250, 880]);

    % Create 4-Panel Tiled Layout
    t = tiledlayout(4, 1, 'Padding', 'compact', 'TileSpacing', 'compact');
    title(t, 'BLOOMBERG QUANTITATIVE CRYPTO SYSTEM — BTC/USDT HIGH-FREQUENCY DASHBOARD', ...
        'Color', cGold, 'FontSize', 13, 'FontWeight', 'bold');

    % =====================================================================
    % PANEL 1: PRICE ACTION, BOLLINGER BANDS & EXECUTION SCATTER MARKERS
    % =====================================================================
    nexttile;
    ax1 = gca;
    set(ax1, 'Color', axDark, 'XColor', cWhite, 'YColor', cWhite, 'GridColor', gridDark, 'GridAlpha', 0.6);
    hold on;
    
    plot(timeVec, closePrice, 'Color', cCyanRGB, 'LineWidth', 1.5, 'DisplayName', 'BTC/USDT Close');
    
    if ~isempty(techTable) && istable(techTable) && ismember('UpperBB', techTable.Properties.VariableNames)
        plot(timeVec, techTable.UpperBB, '--', 'Color', cGoldRGB, 'LineWidth', 1.0, 'DisplayName', 'Upper BB (20,2)');
        plot(timeVec, techTable.MiddleBB, ':', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.8, 'DisplayName', 'SMA 20');
        plot(timeVec, techTable.LowerBB, '--', 'Color', cGoldRGB, 'LineWidth', 1.0, 'DisplayName', 'Lower BB (20,2)');
    end
    
    if ~isempty(buyIdx)
        plot(timeVec(buyIdx), closePrice(buyIdx), '^', 'MarkerSize', 7, ...
            'MarkerFaceColor', cGreenRGB, 'MarkerEdgeColor', 'none', 'DisplayName', 'BUY Signal');
    end
    if ~isempty(sellIdx)
        plot(timeVec(sellIdx), closePrice(sellIdx), 'v', 'MarkerSize', 7, ...
            'MarkerFaceColor', cRedRGB, 'MarkerEdgeColor', 'none', 'DisplayName', 'SELL Signal');
    end
    if ~isempty(slIdx)
        plot(timeVec(slIdx), closePrice(slIdx), 's', 'MarkerSize', 6, ...
            'MarkerFaceColor', cRedRGB, 'MarkerEdgeColor', cGoldRGB, 'DisplayName', 'Stop Loss Exit');
    end
    if ~isempty(tpIdx)
        plot(timeVec(tpIdx), closePrice(tpIdx), 'o', 'MarkerSize', 6, ...
            'MarkerFaceColor', cGreenRGB, 'MarkerEdgeColor', cGoldRGB, 'DisplayName', 'Take Profit Exit');
    end
    hold off;
    grid on;
    title('Panel 1: Price Action & Execution Scatter Markers', 'Color', cWhite, 'FontSize', 10, 'FontWeight', 'bold');
    ylabel('Price (USD)', 'Color', cWhite, 'FontSize', 9);
    legend('Location', 'northwest', 'TextColor', cWhite, 'Color', axDark, 'EdgeColor', gridDark);

    % =====================================================================
    % PANEL 2: SENTIMENT VELOCITY & ROLLING Z-SCORE HEATMAP / THRESHOLDS
    % =====================================================================
    nexttile;
    ax2 = gca;
    set(ax2, 'Color', axDark, 'XColor', cWhite, 'YColor', cWhite, 'GridColor', gridDark, 'GridAlpha', 0.6);
    hold on;
    
    plot(timeVec, sentZ, 'Color', cCyanRGB, 'LineWidth', 1.4, 'DisplayName', '24h Sentiment Z-Score');
    plot(timeVec, sentVel, 'Color', cGoldRGB, 'LineWidth', 1.2, 'DisplayName', 'Sentiment Velocity (dZ/dt)');
    
    yline(2.0, '--', 'Overbought (+2.0)', 'Color', cRedRGB, 'LineWidth', 1.0, 'LabelHorizontalAlignment', 'left');
    yline(-2.0, '--', 'Oversold (-2.0)', 'Color', cGreenRGB, 'LineWidth', 1.0, 'LabelHorizontalAlignment', 'left');
    yline(0, ':', 'Neutral (0.0)', 'Color', [0.5 0.5 0.5]);
    hold off;
    grid on;
    ylim([-3.5, 3.5]);
    title('Panel 2: Sentiment Velocity & 24h Rolling Z-Score', 'Color', cWhite, 'FontSize', 10, 'FontWeight', 'bold');
    ylabel('Z-Score / Velocity', 'Color', cWhite, 'FontSize', 9);
    legend('Location', 'northwest', 'TextColor', cWhite, 'Color', axDark, 'EdgeColor', gridDark);

    % =====================================================================
    % PANEL 3: STRATEGY CUMULATIVE PnL VS BENCHMARK (BUY & HOLD) WITH FILL AREA
    % =====================================================================
    nexttile;
    ax3 = gca;
    set(ax3, 'Color', axDark, 'XColor', cWhite, 'YColor', cWhite, 'GridColor', gridDark, 'GridAlpha', 0.6);
    hold on;
    
    % Strategy PnL Area Fill
    fill([timeVec; flipud(timeVec)], [stratEquity; metrics.InitialCapital * ones(length(stratEquity), 1)], ...
        cGreenRGB, 'FaceAlpha', 0.25, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    
    plot(timeVec, stratEquity, 'Color', cGreenRGB, 'LineWidth', 2.0, ...
        'DisplayName', sprintf('Quantitative Strategy (Net: %+.1f%%)', metrics.TotalReturnStrategy));
    plot(timeVec, benchEquity, 'Color', cBenchRGB, 'LineWidth', 1.4, 'LineStyle', '--', ...
        'DisplayName', sprintf('BTC Buy & Hold (Net: %+.1f%%)', metrics.TotalReturnBenchmark));
    hold off;
    grid on;
    title('Panel 3: Strategy Cumulative Equity Growth ($) vs. Benchmark', 'Color', cWhite, 'FontSize', 10, 'FontWeight', 'bold');
    ylabel('Portfolio Equity ($)', 'Color', cWhite, 'FontSize', 9);
    legend('Location', 'northwest', 'TextColor', cWhite, 'Color', axDark, 'EdgeColor', gridDark);

    % =====================================================================
    % PANEL 4: UNDERWATER DRAWDOWN PROFILE OVER TIME
    % =====================================================================
    nexttile;
    ax4 = gca;
    set(ax4, 'Color', axDark, 'XColor', cWhite, 'YColor', cWhite, 'GridColor', gridDark, 'GridAlpha', 0.6);
    hold on;
    
    fill([timeVec; flipud(timeVec)], [-drawdownVec; zeros(length(drawdownVec), 1)], ...
        cRedRGB, 'FaceAlpha', 0.45, 'EdgeColor', 'none', 'DisplayName', 'Portfolio Drawdown Area');
    plot(timeVec, -drawdownVec, 'Color', cRedRGB, 'LineWidth', 1.2, 'HandleVisibility', 'off');
    hold off;
    grid on;
    ylim([-max(drawdownVec)*1.25 - 1, 1]);
    title(sprintf('Panel 4: Underwater Profile (Maximum Drawdown: -%.2f%%)', metrics.MaxDrawdown), ...
        'Color', cWhite, 'FontSize', 10, 'FontWeight', 'bold');
    xlabel('Date & Time', 'Color', cWhite, 'FontSize', 9);
    ylabel('Drawdown (%)', 'Color', cWhite, 'FontSize', 9);
    legend('Location', 'southwest', 'TextColor', cWhite, 'Color', axDark, 'EdgeColor', gridDark);

    linkaxes([ax1, ax2, ax3, ax4], 'x');

    % =====================================================================
    % INTEGRATED BLOOMBERG HUD OVERLAY TEXT BOX
    % =====================================================================
    calmarValStr = 'N/A';
    if ~isempty(advMetrics) && isfield(advMetrics, 'CalmarRatio')
        calmarValStr = sprintf('%.2f', advMetrics.CalmarRatio);
    end
    
    hudStr = sprintf([ ...
        '  \\bf{BLOOMBERG QUANT METRICS HUD}\n' ...
        '  -----------------------------------------\n' ...
        '  \\color{%s}Sharpe Ratio    : %6.2f\n' ...
        '  \\color{%s}Sortino Ratio   : %6.2f\n' ...
        '  \\color{%s}Calmar Ratio    : %6s\n' ...
        '  \\color{%s}Strategy Net    : %6.1f%%\n' ...
        '  \\color{%s}Max Drawdown    : -%.2f%%\n' ...
        '  \\color{%s}Win Rate        : %6.1f%%\n' ...
        '  \\color{%s}Total Trades    : %6d\n' ...
        '  -----------------------------------------' ...
    ], cGold, metrics.SharpeRatio, ...
       cGold, metrics.SortinoRatio, ...
       cGold, calmarValStr, ...
       cGreen, metrics.TotalReturnStrategy, ...
       cRed, metrics.MaxDrawdown, ...
       cCyan, metrics.WinRate, ...
       cWhite, metrics.TotalTrades);

    annotation(fig, 'textbox', [0.74, 0.77, 0.24, 0.17], ...
        'String', hudStr, ...
        'Interpreter', 'tex', ...
        'Color', cWhite, ...
        'BackgroundColor', axDark, ...
        'EdgeColor', cGold, ...
        'LineWidth', 1.5, ...
        'FontSize', 8, ...
        'FontName', 'Courier New');

    fprintf('[INFO] Bloomberg-Style Dark Dashboard (#0F1117) rendering complete.\n');
end
