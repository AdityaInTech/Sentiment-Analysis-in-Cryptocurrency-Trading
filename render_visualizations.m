function render_visualizations(marketData, sentimentScores, results, coinSymbol)
    % RENDER_VISUALIZATIONS Generates quantitative dashboard figures for price,
    % trading execution signals, sentiment Z-scores, and strategy equity curves.
    %
    % Syntax:
    %   render_visualizations(marketData, sentimentScores, results, coinSymbol)

    if nargin < 4 || isempty(coinSymbol)
        coinSymbol = 'ASSET';
    end

    % --- 1. Extract Timestamps & Prices ---
    if istable(marketData)
        if ismember('Timestamp', marketData.Properties.VariableNames)
            timestamps = marketData.Timestamp;
        elseif ismember('Date', marketData.Properties.VariableNames)
            timestamps = marketData.Date;
        else
            timestamps = (1:height(marketData))';
        end
        prices = marketData.Close;
    else
        prices = marketData;
        timestamps = (1:length(prices))';
    end

    % --- 2. Extract Signals & Equity Curves from Results ---
    if istable(results)
        signals = results.Signals;
        stratEquity = results.StrategyEquity;
        benchEquity = results.BenchmarkEquity;
    elseif isstruct(results)
        signals = results.Signals;
        stratEquity = results.StrategyEquity;
        benchEquity = results.BenchmarkEquity;
    else
        error('Invalid results argument. Expected table or struct.');
    end

    % --- 3. Extract Sentiment Z-Score ---
    if istable(sentimentScores)
        if ismember('SentimentZScore', sentimentScores.Properties.VariableNames)
            zScores = sentimentScores.SentimentZScore;
        elseif ismember('CompoundScore', sentimentScores.Properties.VariableNames)
            zScores = sentimentScores.CompoundScore;
        elseif ismember('SentimentRaw', sentimentScores.Properties.VariableNames)
            zScores = sentimentScores.SentimentRaw;
        else
            zScores = sentimentScores{:, 1};
        end
    else
        zScores = sentimentScores;
    end

    % Clear any existing figures with similar names
    close all;

    % =========================================================================
    % FIGURE 1: Price Action & Execution Scatter Markers
    % =========================================================================
    figure('Name', sprintf('%s - Price Action & Signals', coinSymbol), ...
           'NumberTitle', 'off', 'Color', 'w', 'Position', [100, 100, 900, 500]);
    
    plot(timestamps, prices, 'Color', [0.2 0.2 0.2], 'LineWidth', 1.2, ...
         'DisplayName', sprintf('%s Close Price', coinSymbol));
    hold on;

    buyIdx = find(signals == 1);
    sellIdx = find(signals == -1);

    if ~isempty(buyIdx)
        plot(timestamps(buyIdx), prices(buyIdx), '^', 'MarkerSize', 6, ...
             'MarkerFaceColor', [0.0 0.7 0.1], 'MarkerEdgeColor', 'k', ...
             'DisplayName', 'BUY Signal (+1)');
    end

    if ~isempty(sellIdx)
        plot(timestamps(sellIdx), prices(sellIdx), 'v', 'MarkerSize', 6, ...
             'MarkerFaceColor', [0.9 0.1 0.1], 'MarkerEdgeColor', 'k', ...
             'DisplayName', 'SELL Signal (-1)');
    end

    title(sprintf('%s — Price Action & Execution Signal Markers', coinSymbol), 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Timestamp'); ylabel('Price (USD)');
    legend('Location', 'best');
    grid on; box on;
    hold off;

    % =========================================================================
    % FIGURE 2: Rolling Sentiment Z-Score
    % =========================================================================
    figure('Name', sprintf('%s - Sentiment Z-Score', coinSymbol), ...
           'NumberTitle', 'off', 'Color', 'w', 'Position', [150, 150, 900, 400]);

    plot(timestamps, zScores, 'Color', [0.0 0.45 0.74], 'LineWidth', 1.0, ...
         'DisplayName', 'Sentiment Z-Score');
    hold on;

    yline(1.0, 'r--', 'Overbought Sentiment (+1.0)', 'LineWidth', 1.2);
    yline(-1.0, 'g--', 'Oversold Sentiment (-1.0)', 'LineWidth', 1.2);
    yline(0, 'k:', 'Neutral (0.0)');

    title(sprintf('%s — Social Media Sentiment Rolling Z-Score', coinSymbol), 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Timestamp'); ylabel('Z-Score');
    ylim([-3.5, 3.5]);
    legend('Location', 'best');
    grid on; box on;
    hold off;

    % =========================================================================
    % FIGURE 3: Cumulative Strategy Equity Growth
    % =========================================================================
    figure('Name', sprintf('%s - Strategy Performance', coinSymbol), ...
           'NumberTitle', 'off', 'Color', 'w', 'Position', [200, 200, 900, 500]);

    plot(timestamps, stratEquity, 'Color', [0.0 0.6 0.2], 'LineWidth', 2.0, ...
         'DisplayName', 'Quant Strategy Equity');
    hold on;
    plot(timestamps, benchEquity, 'Color', [0.4 0.4 0.4], 'LineWidth', 1.2, ...
         'LineStyle', '--', 'DisplayName', sprintf('%s Buy & Hold Benchmark', coinSymbol));

    title(sprintf('%s — Cumulative Equity ($10,000 Starting Capital) vs Benchmark', coinSymbol), ...
          'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Timestamp'); ylabel('Portfolio Equity ($)');
    legend('Location', 'best');
    grid on; box on;
    hold off;

    fprintf('[INFO] Dashboard visualizations rendered successfully for %s.\n', coinSymbol);
end